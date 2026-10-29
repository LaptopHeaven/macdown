//
//  MPUtilityTests.m
//  MacDown
//
//  Created by Tzu-ping Chung  on 23/8.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPUtilities.h"
#import "MPHomebrewSubprocessController.h"
#import "MPMathJaxListener.h"


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

@end
