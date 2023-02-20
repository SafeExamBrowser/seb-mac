//
//  MyGlobals.h
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

#import <Foundation/Foundation.h>
#import "Constants.h"
#if TARGET_OS_IPHONE
#import "SEBViewController.h"
#else
@import CocoaLumberjack;
#endif

@interface MyGlobals : NSObject

NS_ASSUME_NONNULL_BEGIN

+ (MyGlobals*)sharedMyGlobals;

+ (DDLogLevel)ddLogLevel;

+ (NSArray *)SEBExtensions;

+ (NSString *)osName;
+ (NSString *)localHostname;
+ (NSString *)computerName;
+ (nullable NSString *)userName;
+ (nullable NSString *)fullUserName;
+ (NSString *)displayName;
+ (NSString *)versionString;
+ (NSString *)buildNumber;
+ (NSString *)bundleID;
+ (NSString *)bundleExecutable;

+ (NSArray<NSString *> *) logSystemInfo;

@property(readwrite) BOOL finishedInitializing;
@property(copy, readwrite) NSMutableArray *downloadPath;
@property(readwrite) NSInteger lastDownloadPath;

@property(copy, readwrite) NSURL *_Nullable currentConfigURL;

@property(copy, readwrite) NSMutableString *pasteboardString;
@property(readwrite) NSUInteger presentationOptions;
@property(readwrite) BOOL startInitAssistant;
@property(readwrite) BOOL startKioskChangedPresentationOptions;
@property(readwrite) BOOL flashChangedPresentationOptions;
@property(readwrite) BOOL preferencesReset;
@property(readwrite) BOOL transitioningToFullscreen;
@property(readwrite) BOOL reconfiguredWhileStarting;
@property(readwrite) BOOL shouldGoFullScreen;
@property(readwrite) NSUInteger logLevel;
@property(copy, readwrite) NSString *defaultUserAgent;
@property(copy, readwrite) NSString *currentUserAgent;

#if TARGET_OS_IPHONE
@property(weak, nonatomic) SEBViewController *sebViewController;
#endif

// SEB for iOS
@property(readwrite) NSInteger currentWebpageIndexPathRow;
@property(readwrite) NSInteger selectedWebpageIndexPathRow;

- (id)infoValueForKey:(NSString*)key;
- (void)setDDLogLevel:(SEBLogLevel)sebLogLevel;
+ (DDFileLogger *)initializeFileLoggerWithDirectory:(nullable NSString *)logPath;
- (NSString *)createUniqueFilename:(nullable NSString *)filename
                 intendedExtension:(nullable NSString*)extension;

NS_ASSUME_NONNULL_END

@end
