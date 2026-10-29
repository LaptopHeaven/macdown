//
//  main.m
//  macdown-cmd
//
//  Created by Esben Sorig on 30/06/2014.
//  Copyright (c) 2014 Tzu-ping Chung . All rights reserved.
//

#import <sys/time.h>
#import <AppKit/AppKit.h>
#import <GBCli/GBCli.h>
#import <stdio.h>
#import <stdlib.h>
#import <sys/stat.h>
#import <unistd.h>
#import "NSUserDefaults+Suite.h"
#import "MPGlobals.h"
#import "MPArgumentProcessor.h"


const NSUInteger kMPPathEncoding = NSUTF8StringEncoding;


NSRunningApplication *MPRunningMacDownInstance()
{
    NSArray *runningInstances = [NSRunningApplication
        runningApplicationsWithBundleIdentifier:kMPApplicationSuiteName];
    return runningInstances.firstObject;
}

void MPCollectPipedContentURLForMacDown(NSURL *url) {
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteNamed:kMPApplicationSuiteName];
    
    [defaults setObject:url.path forKey:kMPPipedContentFileToOpen inSuiteNamed:kMPApplicationSuiteName];
    [defaults synchronize];
}

void MPCollectForMacDown(NSOrderedSet<NSURL *> *urls)
{
    NSUserDefaults *defaults =
        [[NSUserDefaults alloc] initWithSuiteNamed:kMPApplicationSuiteName];
    NSMutableArray<NSString *> *urlStrings =
        [[NSMutableArray alloc] initWithCapacity:urls.count];
    for (NSURL *url in urls)
        [urlStrings addObject:url.path];
    [defaults setObject:urlStrings forKey:kMPFilesToOpenKey
           inSuiteNamed:kMPApplicationSuiteName];
    [defaults synchronize];
}

/**
 * Data piped to macdown through stdin.
 * 
 * @return Piped data if any, otherwise nil.
 */
NSData* MPPipedData() {
    NSFileHandle *stdInFileHandle = [NSFileHandle fileHandleWithStandardInput];
    // Check if stdin file handle have anything to read
    // Modified solution from http://stackoverflow.com/questions/7505777/how-do-i-check-for-nsfilehandle-has-data-available
    int fd = [stdInFileHandle fileDescriptor];
    fd_set fdset;
    struct timeval tmout = { 0, 0 };
    FD_ZERO(&fdset);
    FD_SET(fd, &fdset);
    if (select(fd + 1, &fdset, NULL, NULL, &tmout) <= 0) { // Doesn't hold any data
        return nil;
    }
    else if (FD_ISSET(fd, &fdset)) { // Holds data
        NSData *stdInData = [NSData dataWithData:[stdInFileHandle readDataToEndOfFile]];
        return stdInData;
    }
    else {
        return nil;
    }
}


int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        MPArgumentProcessor *argproc = [[MPArgumentProcessor alloc] init];

        if (argproc.printsHelp)
            [argproc printHelp:YES];
        else if (argproc.printsVersion)
            [argproc printVersion:YES];
        
        NSData *dataFromPipe = MPPipedData();
        
        if (dataFromPipe) {
            NSString *pathTemplate = [NSTemporaryDirectory()
                stringByAppendingPathComponent:
                    [kMPPipedContentFilePrefix stringByAppendingString:@"XXXXXX"]];
            char *filePath = strdup(pathTemplate.fileSystemRepresentation);
            if (filePath) {
                int fileDescriptor = mkstemp(filePath);
                if (fileDescriptor >= 0) {
                    struct stat fileAttributes;
                    BOOL privateFile = fstat(fileDescriptor, &fileAttributes) == 0
                        && (fileAttributes.st_mode & 077) == 0;
                    FILE *file = privateFile ? fdopen(fileDescriptor, "wb") : NULL;
                    BOOL wroteAllData = NO;
                    if (file) {
                        wroteAllData = fwrite(dataFromPipe.bytes, 1,
                                              dataFromPipe.length, file)
                            == dataFromPipe.length;
                        if (fflush(file) != 0)
                            wroteAllData = NO;
                        if (fclose(file) != 0)
                            wroteAllData = NO;
                    }
                    else
                    {
                        close(fileDescriptor);
                    }

                    if (wroteAllData) {
                        NSURL *fileURL = [NSURL fileURLWithFileSystemRepresentation:
                            filePath isDirectory:NO relativeToURL:nil];
                        if (fileURL)
                            MPCollectPipedContentURLForMacDown(fileURL);
                        else
                            unlink(filePath);
                    }
                    else
                    {
                        unlink(filePath);
                    }
                }
                free(filePath);
            }
        }

        // Treat all arguments as file names to open. Convert them to absolute
        // paths and store them (as an array) in MacDown's user defaults to
        // be opened later.
        NSString *pwd = [NSFileManager defaultManager].currentDirectoryPath;
        NSURL *pwdUrl = [NSURL fileURLWithPath:pwd isDirectory:YES];
        NSMutableOrderedSet<NSURL *> *urls = [NSMutableOrderedSet orderedSet];
        for (NSString *arg in argproc.arguments)
        {
            NSString *escaped = [arg stringByAddingPercentEncodingWithAllowedCharacters:
                                 [NSCharacterSet URLPathAllowedCharacterSet]];
            NSURL *url = [NSURL URLWithString:escaped relativeToURL:pwdUrl];
            [urls addObject:url];
        }
        MPCollectForMacDown(urls);

        // Launch MacDown.
        NSURL *appURL = [[NSWorkspace sharedWorkspace]
            URLForApplicationWithBundleIdentifier:kMPApplicationBundleIdentifier];
        if (appURL)
        {
            NSWorkspaceOpenConfiguration *configuration =
                [NSWorkspaceOpenConfiguration configuration];
            [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL
                                                  configuration:configuration
                                              completionHandler:nil];
        }
    }
    return EXIT_SUCCESS;
}
