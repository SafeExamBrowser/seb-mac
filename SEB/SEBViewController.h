//
//  SEBViewController.h
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


/**
 * @protocol    SEBConfigURLManagerDelegate
 *
 * @brief       All SEB config URL managers must conform to
 *              the SEBConfigURLDelegate protocol.
 */
@protocol SEBConfigURLManagerDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required

/**
 * @brief       Evaluate an entered string, derive a SEB config URL and act on result.
 * @details
 */
- (void)evaluateEnteredURLString:(NSString *)inputURLString;

@end


#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import "UIViewController+MMDrawerController.h"
#import "IASKAppSettingsViewController.h"

#import "SEBInitAssistantViewController.h"
#import "SEBiOSInitAssistantViewController.h"

#import "SEBLockedViewController.h"
#import "SEBiOSLockedViewController.h"
#import "SEBiOSConfigFileController.h"
#import "QRCodeReaderViewController.h"

#import "SEBBrowserTabViewController.h"
#import "SEBSearchBarViewController.h"


@class SEBBrowserTabViewController;
@class SEBSearchBarViewController;
@class SEBiOSConfigFileController;
@class SEBInitAssistantViewController;
@class SEBiOSInitAssistantViewController;
@class QRCodeReaderViewController;


@interface SEBViewController : UIViewController <SEBLockedViewControllerDelegate, QRCodeReaderDelegate>

@property (nonatomic, strong) SEBBrowserTabViewController *browserTabViewController;
//@property (nonatomic, strong) SEBiOSDockController *dockController;
@property (nonatomic, strong) SEBSearchBarViewController *searchBarViewController;

@property (strong, nonatomic) SEBiOSInitAssistantViewController *assistantViewController;

@property (strong, nonatomic) SEBiOSLockedViewController< SEBLockedViewUIDelegate > *lockedViewController;
@property (strong, nonatomic) SEBiOSConfigFileController *configFileController;
@property (strong, nonatomic) SEBLockedViewController *sebLockedViewController;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

@property (nonatomic, strong) QRCodeReaderViewController *codeReaderViewController;
@property (nonatomic, strong) QRCodeReaderViewController *visibleCodeReaderViewController;

@property (nonatomic, strong) id <SEBConfigURLManagerDelegate> configURLManagerDelegate;

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertController *inactiveAlertController;

@property (strong, nonatomic) UIView *coveringView;
@property (strong, nonatomic) UIView *statusBarView;
@property (strong, nonatomic) NSArray *dockItems;

@property(readwrite) BOOL secureMode;
@property(readwrite) BOOL enableASAM;
@property(readwrite) BOOL allowSAM;

@property(readwrite) BOOL ASAMActive;
@property(readwrite) BOOL SAMActive;
@property(readwrite) BOOL singleAppModeActivated;

@property(readwrite) BOOL finishedStartingUp;
@property(readwrite) BOOL isReconfiguring;
@property(readwrite) BOOL startSAMWAlertDisplayed;
@property(readwrite) BOOL pausedSAMAlertDisplayed;
@property(readwrite) BOOL endSAMWAlertDisplayed;
@property(readwrite) BOOL restartSessionAlertDisplayed;
@property(readwrite) BOOL examRunning;
@property(readwrite) BOOL initAssistantOpen;
@property(readwrite) BOOL settingsOpen;
@property(readwrite) BOOL sebLocked;
@property(readwrite) BOOL unlockPasswordEntered;
@property(readwrite) BOOL scannedQRCode;

@property(readwrite, strong) NSDate *didResignActiveTime;
@property(readwrite, strong) NSDate *didBecomeActiveTime;
@property(readwrite, strong) NSDate *didResumeExamTime;


- (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

- (void)showConfigURLWarning;
- (void)scanQRCode:(id)sender;

- (void)conditionallyShowSettingsModal;
- (void)conditionallyResetSettings;

- (void) showStartSingleAppMode;
- (void) startExam;
- (void) quitExamConditionally;
- (void) quitExamWithCallback:(id)callback selector:(SEL)selector;

- (void) stopAutonomousSingleAppMode;

- (void) conditionallyOpenLockdownWindows;
- (void) openLockdownWindows;

- (void) downloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

- (void) showToolbarNavigation:(BOOL)show;
- (void) setToolbarTitle:(NSString *)title;

- (void)setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;

@end

