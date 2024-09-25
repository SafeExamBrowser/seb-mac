//
//  AppDelegate.h
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SEBViewController.h"
#import "SEBUIController.h"
#import "SEBLockedViewController.h"
#import "SEBiOSLockedViewController.h"

@class SEBViewController;
@class SEBUIController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIGestureRecognizerDelegate> {
    NSMutableArray *_persistentWebpages;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SEBViewController *sebViewController;
@property (strong, nonatomic) SEBUIController *sebUIController;
@property (strong, nonatomic) DDFileLogger *myLogger;
@property (strong, nonatomic, readonly) NSURL *sebFileURL;
@property (strong, nonatomic, readonly) NSURL *universalURL;
@property (strong, nonatomic) UIApplicationShortcutItem *shortcutItemAtLaunch;
@property(readwrite) BOOL didEnterBackground;
@property(readwrite) BOOL SAMActive;
@property(readwrite) BOOL openedURL;
@property(readwrite) BOOL openedUniversalLink;
@property(readwrite) dispatch_time_t dispatchTimeAppLaunched;

@property (nonatomic, strong) NSMutableArray *persistentWebpages;

@property (strong, nonatomic) WKWebView *temporaryWebView;

@property (readwrite) NSUInteger statusBarAppearance;
@property (readwrite) BOOL showSettingsInApp;
@property (nonatomic, strong) NSArray *leftSliderCommands;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

