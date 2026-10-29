//
//  MPHomebrewSubprocessController.m
//  MacDown
//
//  Created by Tzu-ping Chung on 18/2.
//  Copyright © 2017 Tzu-ping Chung . All rights reserved.
//

#import "MPHomebrewSubprocessController.h"


@interface MPHomebrewSubprocessController ()

@property (readonly) NSTask *task;
@property (readwrite) void(^completionHandler)(NSString *);

@end


@implementation MPHomebrewSubprocessController

- (instancetype)initWithArguments:(NSArray *)args
{
    self = [super init];
    if (!self)
        return nil;

    _task = [[NSTask alloc] init];
    // shortcut: standard Homebrew prefixes only; add configured custom-prefix support if needed.
    NSArray *paths = @[@"/opt/homebrew/bin/brew", @"/usr/local/bin/brew"];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *path in paths)
    {
        if ([manager isExecutableFileAtPath:path])
        {
            _task.executableURL = [NSURL fileURLWithPath:path];
            break;
        }
    }
    if (args)
        _task.arguments = args;

    if (!_task.executableURL)
        return self;

    NSPipe *stdoutPipe = [[NSPipe alloc] init];
    NSFileHandle *stdoutReadHandle = stdoutPipe.fileHandleForReading;
    _task.standardOutput = stdoutPipe;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(homebrewReadDidComplete:)
                   name:NSFileHandleReadToEndOfFileCompletionNotification
                 object:stdoutReadHandle];
    [stdoutReadHandle readToEndOfFileInBackgroundAndNotify];

    return self;
}

- (instancetype)init
{
    return [self initWithArguments:nil];
}

- (void)dealloc
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self
                      name:NSFileHandleReadToEndOfFileCompletionNotification
                    object:nil];
}

- (void)runWithCompletionHandler:(void(^)(NSString *))handler
{
    self.completionHandler = handler;
    if (!self.task.executableURL)
    {
        if (handler)
            handler(nil);
        return;
    }

    if (![self.task launchAndReturnError:NULL])
    {
        self.completionHandler = nil;
        NSPipe *stdoutPipe = self.task.standardOutput;
        [stdoutPipe.fileHandleForWriting closeFile];
        if (handler)
            handler(nil);
    }
}

- (void)homebrewReadDidComplete:(NSNotification *)notification
{
    NSData *outData = notification.userInfo[NSFileHandleNotificationDataItem];
    NSString *output = [[NSString alloc] initWithData:outData
                                             encoding:NSUTF8StringEncoding];
    if (self.completionHandler)
        self.completionHandler(output);
}

@end


void MPDetectHomebrewPrefixWithCompletionhandler(void(^handler)(NSString *))
{
    NSArray *args = @[@"--prefix"];
    MPHomebrewSubprocessController *c =
        [[MPHomebrewSubprocessController alloc] initWithArguments:args];
    [c runWithCompletionHandler:handler];
}
