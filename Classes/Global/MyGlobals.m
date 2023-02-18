//
//  MyGlobals.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13.10.11.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
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
    NSUInteger newDDLogLevel = (NSUInteger)[[self sharedMyGlobals] logLevel];
    return (DDLogLevel)newDDLogLevel;
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
    if (sebLogLevel) {
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
    } else {
        _logLevel = DDLogLevelOff;
    }
}


+ (DDFileLogger *)initializeFileLoggerWithDirectory:(NSString *)logPath
{
    DDFileLogger *myLogger;
    DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logPath];
    myLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    myLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    myLogger.logFileManager.maximumNumberOfLogFiles = 7; // keep logs for 7 days

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    myLogger.logFormatter = [[DDLogFileFormatterDefault alloc] initWithDateFormatter:dateFormatter];
    
    return myLogger;
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
            filename = [filename stringByAppendingString:NSLocalizedString(@" copy", nil)];
        } else {
            NSString *copyNumberString = [filename substringFromIndex:copyStringRange.location+copyStringRange.length];
            if (copyNumberString.length == 0) {
                filename = [filename stringByAppendingString:NSLocalizedString(@" 1", nil)];
            } else {
                NSInteger copyNumber = [[copyNumberString substringFromIndex:1] integerValue];
                if (copyNumber == 0) {
                    filename = [filename stringByAppendingString:NSLocalizedString(@" copy", nil)];
                } else {
                    filename = [[filename substringToIndex:copyStringRange.location+copyStringRange.length+1] stringByAppendingString:[NSString stringWithFormat:@"%ld", (long)copyNumber+1]];
                }
            }
        }
    }
    return filename;
}


@end
