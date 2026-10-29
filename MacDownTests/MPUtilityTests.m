//
//  MPUtilityTests.m
//  MacDown
//
//  Created by Tzu-ping Chung  on 23/8.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPUtilities.h"
#import "MPGlobals.h"
#import "MPHomebrewSubprocessController.h"
#import "MPMathJaxListener.h"
#import "NSString+Lookup.h"
#import <stdlib.h>
#import <string.h>
#import <sys/stat.h>
#import <unistd.h>


@interface MPMathJaxListener (WebScriptingTest)
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector;
+ (BOOL)isKeyExcludedFromWebScript:(const char *)name;
@end


@interface MPHomebrewSubprocessController (MPUtilityTestAccess)
@property (readonly) NSTask *task;
@end

@interface MPUtilityTests : XCTestCase
@end


@implementation MPUtilityTests

- (void)testGetObjectFromJavaScript
{
    NSString *code = (
        @"var obj = { foo: 'bar', baz: 42 };"
        @"var arr = [0, null, {}];"
    );
    id obj = MPGetObjectFromJavaScript(code, @"obj");
    id objx = @{@"foo": @"bar", @"baz": @42};
    XCTAssertEqualObjects(obj, objx, @"JavaScript object to NSDictionary");

    id arr = MPGetObjectFromJavaScript(code, @"arr");
    id arrx = @[@0, [NSNull null], @{}];
    XCTAssertEqualObjects(arr, arrx, @"JavaScript object to NSDictionary");
}

- (void)testHomebrewProbeUsesAnAbsoluteExecutableURL
{
    NSArray *paths = @[@"/opt/homebrew/bin/brew", @"/usr/local/bin/brew"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *expectedPath = nil;
    for (NSString *path in paths)
    {
        if ([manager isExecutableFileAtPath:path])
        {
            expectedPath = path;
            break;
        }
    }

    MPHomebrewSubprocessController *controller =
        [[MPHomebrewSubprocessController alloc] initWithArguments:@[@"--prefix"]];
    XCTAssertEqualObjects(controller.task.executableURL.path, expectedPath);

    XCTestExpectation *completed =
        [self expectationWithDescription:@"Homebrew prefix lookup"];
    [controller runWithCompletionHandler:^(NSString *output) {
        if (expectedPath)
        {
            NSString *prefix = [[expectedPath stringByDeletingLastPathComponent]
                stringByDeletingLastPathComponent];
            XCTAssertTrue([[output stringByTrimmingCharactersInSet:
                [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                hasPrefix:prefix]);
        }
        else
        {
            XCTAssertNil(output);
        }
        [completed fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testMathJaxBridgeExposesOnlyItsCompletionCallback
{
    XCTAssertTrue([MPMathJaxListener isKeyExcludedFromWebScript:"_callbacks"]);
    XCTAssertTrue([MPMathJaxListener isKeyExcludedFromWebScript:"callbacks"]);
    XCTAssertFalse([MPMathJaxListener isSelectorExcludedFromWebScript:
        @selector(invokeCallbackForKey:)]);
    XCTAssertTrue([MPMathJaxListener isSelectorExcludedFromWebScript:
        @selector(addCallback:forKey:)]);

    MPMathJaxListener *listener = [[MPMathJaxListener alloc] init];
    __block BOOL invoked = NO;
    [listener addCallback:^{ invoked = YES; } forKey:@"End"];
    [listener invokeCallbackForKey:@"End"];
    XCTAssertTrue(invoked);
}

- (void)testPipedContentTempFileIsPrivateAndDeletionIsRestricted
{
    NSString *directory = NSTemporaryDirectory();
    NSString *validTemplate = [directory stringByAppendingPathComponent:
        [kMPPipedContentFilePrefix stringByAppendingString:@"XXXXXX"]];
    char *validPath = strdup(validTemplate.fileSystemRepresentation);
    if (!validPath)
    {
        XCTFail(@"Could not allocate the temporary path.");
        return;
    }
    int validDescriptor = mkstemp(validPath);
    if (validDescriptor < 0)
    {
        XCTFail(@"Could not create the temporary file.");
        free(validPath);
        return;
    }

    struct stat attributes;
    if (fstat(validDescriptor, &attributes) == 0)
        XCTAssertEqual(attributes.st_mode & 077, 0);
    else
        XCTFail(@"Could not inspect the temporary file permissions.");
    close(validDescriptor);

    NSURL *validURL = [NSURL fileURLWithFileSystemRepresentation:
        validPath isDirectory:NO relativeToURL:nil];
    BOOL deleted = MPDeletePipedContentTemporaryFile(validURL);
    XCTAssertTrue(deleted);
    if (!deleted)
        unlink(validPath);
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:validURL.path]);

    NSString *otherTemplate = [directory stringByAppendingPathComponent:
        @"unrelated-temp-XXXXXX"];
    char *otherPath = strdup(otherTemplate.fileSystemRepresentation);
    if (!otherPath)
    {
        XCTFail(@"Could not allocate the unrelated path.");
        free(validPath);
        return;
    }
    int otherDescriptor = mkstemp(otherPath);
    if (otherDescriptor < 0)
    {
        XCTFail(@"Could not create the unrelated temporary file.");
        free(otherPath);
        free(validPath);
        return;
    }
    close(otherDescriptor);
    NSURL *otherURL = [NSURL fileURLWithFileSystemRepresentation:
        otherPath isDirectory:NO relativeToURL:nil];
    XCTAssertFalse(MPDeletePipedContentTemporaryFile(otherURL));
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:otherURL.path]);
    unlink(otherPath);
    free(otherPath);

    XCTAssertFalse(MPDeletePipedContentTemporaryFile(
        [NSURL fileURLWithPath:@"/private/etc/passwd"]));
    free(validPath);
}

- (void)testFrontMatterHandlesLongEscapedTagURI
{
    NSMutableString *tag = [NSMutableString stringWithString:@"tag:example.com,2024:"];
    for (NSUInteger i = 0; i < 256; i++)
        [tag appendString:@"%C3%A9"];
    NSString *markdown = [NSString stringWithFormat:
        @"---\nvalue: !<%@> safe\n---\nbody", tag];

    NSUInteger contentOffset = 0;
    NSDictionary *frontMatter = [markdown frontMatter:&contentOffset];
    XCTAssertGreaterThan(contentOffset, 0);
    XCTAssertEqualObjects(frontMatter[@"value"], @"safe");
}

- (void)testFrontMatterRejectsExcessiveNesting
{
    NSMutableString *nested = [NSMutableString string];
    for (NSUInteger i = 0; i < 1100; i++)
        [nested appendString:@"["];
    [nested appendString:@"0"];
    for (NSUInteger i = 0; i < 1100; i++)
        [nested appendString:@"]"];

    NSString *markdown = [NSString stringWithFormat:@"---\n%@\n---\nbody", nested];
    NSUInteger contentOffset = 0;
    XCTAssertNil([markdown frontMatter:&contentOffset]);
    XCTAssertEqual(contentOffset, 0);
}

@end
