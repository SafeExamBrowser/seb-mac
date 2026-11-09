//
//  MyGlobals.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13.10.11.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//  
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//  
//  The Original Code is Safe Exam Browser for Mac OS X.
//  
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright 
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SynthesizeSingleton.h"
#import "MyGlobals.h"
#include <SystemConfiguration/SystemConfiguration.h>

@implementation MyGlobals

SYNTHESIZE_SINGLETON_FOR_CLASS(MyGlobals);


+ (DDLogLevel)ddLogLevel
{
//    NSUInteger newDDLogLevel = (NSUInteger)[[self sharedMyGlobals] logLevel];
//    return (DDLogLevel)newDDLogLevel;
    return ddLogLevel;
}


+ (NSArray *)SEBExtensions
{
    return @[@"SEBPresetSettings"];
}


+ (NSString *)osName
{
#if TARGET_OS_OSX
    return [NSString stringWithFormat:@"%@ %@", runningOSmacOS, NSProcessInfo.processInfo.operatingSystemVersionString];
#else
    UIDevice *device = UIDevice.currentDevice;
    NSString *deviceModel = device.model;
    NSString *systemName = device.systemName;
    NSString *systemVersion = device.systemVersion;
    return [NSString stringWithFormat:@"%@ (%@ %@)", deviceModel, systemName, systemVersion];
#endif
}

+ (NSString *)localHostname
{
#if TARGET_OS_OSX
    return (NSString *)CFBridgingRelease(SCDynamicStoreCopyLocalHostName(NULL));
#else
    return @"";
#endif
}

+ (NSString *)computerName
{
#if TARGET_OS_OSX
    return (NSString *)CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
#else
    return UIDevice.currentDevice.name;
#endif
}

+ (NSString *)userName
{
    return NSUserName();
}

+ (NSString *)fullUserName
{
    return NSFullUserName();
}

+ (NSString *)displayName
{
    return [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleDisplayName"];
}

+ (NSString *)versionString
{
    return [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
}

+ (NSString *)buildNumber
{
    return [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
}
+ (NSString *)bundleID
{
    return [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleIdentifier"];
}

+ (NSString *)bundleExecutable
{
    return [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleExecutable"];
}


+ (BOOL)catchException:(void (NS_NOESCAPE ^)(void))tryBlock error:(NSError * _Nullable * _Nullable)error
{
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        if (error) {
            NSString *description = exception.reason ?: exception.name ?: @"Objective-C exception";
            *error = [NSError errorWithDomain:@"SEBExceptionDomain"
                                         code:0
                                     userInfo:@{ NSLocalizedDescriptionKey: description }];
        }
        return NO;
    }
}


+ (NSArray<NSString *> *) logSystemInfo
{
    NSMutableArray *logOutput = [NSMutableArray new];
    NSString *localHostname = MyGlobals.localHostname;
    NSString *computerName = MyGlobals.computerName;
    NSString *userName = MyGlobals.userName;
    NSString *fullUserName = MyGlobals.fullUserName;
    NSString *displayName = MyGlobals.displayName;
    NSString *versionString = MyGlobals.versionString;
    NSString *buildNumber = MyGlobals.buildNumber;
    NSString *bundleID = MyGlobals.bundleID;
    NSString *bundleExecutable = MyGlobals.bundleExecutable;
    
    DDLogInfo(@"%@ version %@ (Build %@)", displayName, versionString, buildNumber);
    [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"%@ version %@ (Build %@)", @"App full/build version"), displayName, versionString, buildNumber]];
    
    DDLogInfo(@"Bundle ID: %@, executable: %@", bundleID, bundleExecutable);
    [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"Bundle ID: %@, executable: %@", @""), bundleID, bundleExecutable]];

    DDLogInfo(@"OS version %@", MyGlobals.osName);
    [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"OS version %@", @""), MyGlobals.osName]];

    if (localHostname.length > 0) {
        DDLogInfo(@"Local hostname: %@", localHostname);
        [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"Local hostname: %@", @""), localHostname]];
    }
    DDLogInfo(@"Device name: %@", computerName);
    [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"Device name: %@", @""), computerName]];

    DDLogInfo(@"User name: %@", userName);
    [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"User name: %@", @""), userName]];

    DDLogInfo(@"Full user name: %@", fullUserName);
    [logOutput addObject:[NSString stringWithFormat:NSLocalizedString(@"Full user name: %@", @""), fullUserName]];

    return logOutput.copy;
}


- (void)setDownloadPath:(NSMutableArray *)downloadPath
{
    [[NSUserDefaults standardUserDefaults] setPersistedSecureObject:downloadPath forKey:DownloadPathsKey];
}

- (NSMutableArray *)downloadPath
{
    return [[NSUserDefaults standardUserDefaults] persistedSecureObjectForKey:DownloadPathsKey];
}

// Read Info.plist values from bundle
- (id)infoValueForKey:(NSString*)key
{
    if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key]) {
        return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
    }
	
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}


- (void)setDDLogLevel:(SEBLogLevel)sebLogLevel
{
    NSArray *ddLogLevels = @[[NSNumber numberWithInt:DDLogLevelError],
                             [NSNumber numberWithInt:DDLogLevelWarning],
                             [NSNumber numberWithInt:DDLogLevelInfo],
                             [NSNumber numberWithInt:DDLogLevelDebug],
                             [NSNumber numberWithInt:DDLogLevelVerbose]];
    if (sebLogLevel < ddLogLevels.count) {
        _logLevel = [ddLogLevels[sebLogLevel] intValue];
    } else {
        _logLevel = DDLogLevelOff;
    }
    ddLogLevel = _logLevel;
}


+ (DDFileLogger *)initializeFileLoggerWithDirectory:(NSString *)logPath
{
    DDFileLogger *myLogger;
#if !TARGET_OS_IPHONE
    if (logPath.length == 0) {
        // macOS: resolve the standard log directory explicitly (~/Library/Logs/<app name>)
        // instead of passing nil down to DDLogFileManagerDefault. This mirrors CocoaLumberjack's
        // own macOS default (NSLibraryDirectory + "Logs" + process name) but makes the location
        // deterministic and independent of any change in how the library treats a nil directory,
        // so the temporary startup logger and the permanent logger reliably use the same standard
        // directory. On iOS we keep passing nil so CocoaLumberjack uses its platform default
        // (the Caches directory), unchanged.
        NSString *basePath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        if (basePath.length > 0) {
            NSString *appName = [NSProcessInfo processInfo].processName;
            logPath = [[basePath stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:appName];
        }
    }
#endif
    DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logPath];
    myLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    myLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    myLogger.logFileManager.maximumNumberOfLogFiles = 20; // keep max. 20 log files

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    myLogger.logFormatter = [[DDLogFileFormatterDefault alloc] initWithDateFormatter:dateFormatter];

    return myLogger;
}


+ (NSURL *)resolvedDirectoryURL:(NSURL *)directoryURL
{
    if (!directoryURL.isFileURL) {
        return directoryURL;
    }
    // Symbolic links and aliases can only be resolved for existing items, so split off not (yet)
    // existing trailing path components (e.g. ~/Documents/SEB when SEB doesn't exist yet, but
    // ~/Documents is redirected) and re-append them after resolving the existing ancestor.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *existingPath = directoryURL.path.stringByStandardizingPath;
    NSMutableArray<NSString *> *missingComponents = [NSMutableArray new];
    while (existingPath.length > 1 && ![fileManager fileExistsAtPath:existingPath]) {
        [missingComponents insertObject:existingPath.lastPathComponent atIndex:0];
        existingPath = existingPath.stringByDeletingLastPathComponent;
    }
    // Resolve symbolic links in all path components (also an ancestor like a symlinked ~/Documents)
    NSString *resolvedPath = existingPath.stringByResolvingSymlinksInPath;
    // Resolve a Finder alias file: Unlike a symbolic link, an alias is a regular file, so trying to
    // read it as a directory fails with POSIX error 20 "Not a directory". This returns the same URL
    // if the item isn't an alias file and fails (returns nil) for a non-existing item.
    NSError *error;
    NSURL *aliasTargetURL = [NSURL URLByResolvingAliasFileAtURL:[NSURL fileURLWithPath:resolvedPath]
                                                        options:(NSURLBookmarkResolutionWithoutUI | NSURLBookmarkResolutionWithoutMounting)
                                                          error:&error];
    if (aliasTargetURL) {
        resolvedPath = aliasTargetURL.path;
    }
    for (NSString *component in missingComponents) {
        resolvedPath = [resolvedPath stringByAppendingPathComponent:component];
    }
    return [NSURL fileURLWithPath:resolvedPath.stringByStandardizingPath isDirectory:YES];
}


+ (BOOL)directoryIsRedirected:(NSURL *)directoryURL
{
    if (!directoryURL.isFileURL) {
        return NO;
    }
    // Standardize both paths, so e.g. the system's /tmp -> /private/tmp link isn't reported as redirected
    NSString *originalPath = directoryURL.path.stringByStandardizingPath;
    NSString *resolvedPath = [self resolvedDirectoryURL:directoryURL].path.stringByStandardizingPath;
    return ![originalPath isEqualToString:resolvedPath];
}


- (NSString *)createUniqueFilename:(nullable NSString *)filename intendedExtension:(nullable NSString*)intendedExtension
{
    // Add string " copy" (or " n+1" if the filename already ends with " copy" or " copy n")
    // to the filename
    NSString *extension = filename.pathExtension;
    filename = filename.lastPathComponent.stringByDeletingPathExtension;
    if (filename.length == 0) {
        filename = NSLocalizedString(@"Untitled", @"untitled filename");
        extension = intendedExtension;
    } else {
        NSRange copyStringRange = [filename rangeOfString:NSLocalizedString(@" copy", @"word indicating the duplicate of a file, same as in Finder ' copy'") options:NSBackwardsSearch];
        if (copyStringRange.location == NSNotFound) {
            filename = [filename stringByAppendingString:NSLocalizedString(@" copy", @"")];
        } else {
            NSString *copyNumberString = [filename substringFromIndex:copyStringRange.location+copyStringRange.length];
            if (copyNumberString.length == 0) {
                filename = [filename stringByAppendingString:NSLocalizedString(@" 1", @"")];
            } else {
                NSInteger copyNumber = [[copyNumberString substringFromIndex:1] integerValue];
                if (copyNumber == 0) {
                    filename = [filename stringByAppendingString:NSLocalizedString(@" copy", @"")];
                } else {
                    filename = [[filename substringToIndex:copyStringRange.location+copyStringRange.length+1] stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)copyNumber+1]];
                }
            }
        }
    }
    return filename;
}


- (nullable NSString *)fileExtensionForConfigFormat:(ShareConfigFormat)configFormat
{
    NSString *fileExtension;
    switch (configFormat) {
        case shareConfigFormatFile:
            fileExtension = SEBFileExtension;
            break;
            
        case shareConfigFormatLink:
            fileExtension = @"txt";
            break;
            
        case shareConfigFormatQRCode:
            fileExtension = @"png";
            break;
            
        default:
            break;
    }
    return fileExtension;
}


@end
