//
//  MPPreferencesTests.m
//  MPPreferencesTests
//
//  Created by Tzu-ping Chung  on 6/06/2014.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <hoedown/html.h>
#import "MPPreferences.h"
#import "MPRenderer.h"


@interface MPPreferences (HoedownTest)
- (int)rendererFlags;
@end


@interface MPRendererTestDataSource : NSObject <MPRendererDataSource>
@property (copy) NSString *markdown;
@property (copy) NSString *title;
@end

@implementation MPRendererTestDataSource
- (BOOL)rendererLoading { return NO; }
- (NSString *)rendererMarkdown:(MPRenderer *)renderer { return self.markdown; }
- (NSString *)rendererHTMLTitle:(MPRenderer *)renderer { return self.title; }
@end


@interface MPRendererTestDelegate : NSObject <MPRendererDelegate>
@property XCTestExpectation *rendered;
@property (copy) NSString *html;
@end

@implementation MPRendererTestDelegate
- (int)rendererExtensions:(MPRenderer *)renderer { return 0; }
- (BOOL)rendererHasSmartyPants:(MPRenderer *)renderer { return NO; }
- (BOOL)rendererRendersTOC:(MPRenderer *)renderer { return NO; }
- (NSString *)rendererStyleName:(MPRenderer *)renderer { return nil; }
- (BOOL)rendererDetectsFrontMatter:(MPRenderer *)renderer { return NO; }
- (BOOL)rendererHasSyntaxHighlighting:(MPRenderer *)renderer { return NO; }
- (BOOL)rendererHasMermaid:(MPRenderer *)renderer { return NO; }
- (BOOL)rendererHasGraphviz:(MPRenderer *)renderer { return NO; }
- (MPCodeBlockAccessoryType)rendererCodeBlockAccesory:(MPRenderer *)renderer
{
    return MPCodeBlockAccessoryNone;
}
- (BOOL)rendererHasMathJax:(MPRenderer *)renderer { return NO; }
- (NSString *)rendererHighlightingThemeName:(MPRenderer *)renderer { return nil; }
- (void)renderer:(MPRenderer *)renderer didProduceHTMLOutput:(NSString *)html
{
    self.html = html;
    [self.rendered fulfill];
}
@end

@interface MPPreferencesTests : XCTestCase
@property MPPreferences *preferences;
@property NSDictionary *oldFontInfo;
@property NSString *oldHTMLTemplateName;
@end


@implementation MPPreferencesTests

- (void)setUp
{
    [super setUp];
    self.preferences = [MPPreferences sharedInstance];
    self.oldFontInfo = [self.preferences.editorBaseFontInfo copy];
    self.oldHTMLTemplateName = self.preferences.htmlTemplateName;

}

- (void)tearDown
{
    self.preferences.editorBaseFontInfo = self.oldFontInfo;
    self.preferences.htmlTemplateName = self.oldHTMLTemplateName;
    [self.preferences synchronize];
    [super tearDown];
}

- (void)testFont
{
    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    self.preferences.editorBaseFont = font;

    XCTAssertTrue([self.preferences synchronize],
                  @"Failed to synchronize user defaults.");

    NSFont *result = [self.preferences.editorBaseFont copy];
    XCTAssertEqualObjects(font, result,
                          @"Preferences not preserving font info correctly.");
}

- (void)testRendererEscapesUntrustedHTMLAndTitle
{
    self.preferences.htmlTemplateName = @"Default";

    MPRendererTestDataSource *source = [[MPRendererTestDataSource alloc] init];
    source.markdown = @"<script>window.pwned = true;</script>\n\nsafe paragraph";
    source.title = @"</title><script>window.titlePwned = true;</script>";

    MPRendererTestDelegate *delegate = [[MPRendererTestDelegate alloc] init];
    delegate.rendered = [self expectationWithDescription:@"renderer output"];

    MPRenderer *renderer = [[MPRenderer alloc] init];
    XCTAssertNotEqual(renderer.rendererFlags & HOEDOWN_HTML_ESCAPE, 0);
    XCTAssertNotEqual(self.preferences.rendererFlags & HOEDOWN_HTML_ESCAPE, 0);
    renderer.dataSource = source;
    renderer.delegate = delegate;
    [renderer parseAndRenderNow];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    NSString *exportHTML = [renderer HTMLForExportWithStyles:NO highlighting:NO];
    for (NSString *html in @[delegate.html, exportHTML])
    {
        XCTAssertFalse([html containsString:@"<script>window.pwned"]);
        XCTAssertFalse([html containsString:@"</title><script>"]);
        XCTAssertTrue([html containsString:@"&lt;/title&gt;&lt;script&gt;window.titlePwned"]);
        XCTAssertTrue([html containsString:@"<p>safe paragraph</p>"]);
    }
}

@end
