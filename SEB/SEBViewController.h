//
//  SEBViewController.h
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
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

#import "RNCryptor.h"
#import "SEBCryptor.h"

#import "LGSideMenuController.h"
#import "UIViewController+LGSideMenuController.h"

#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "SEBIASKSecureSettingsStore.h"
#import "SEBInAppSettingsViewController.h"

#import "SEBUIController.h"
#import "SEBSliderItem.h"
#import "SEBNavigationController.h"

#import "SEBInitAssistantViewController.h"
#import "SEBiOSInitAssistantViewController.h"

#import "SEBLockedViewController.h"
#import "SEBiOSLockedViewController.h"
#import "SEBiOSConfigFileController.h"
#import "QRCodeReaderViewController.h"
#import "AboutSEBiOSViewController.h"

#import "SEBBrowserController.h"
#import "SEBBrowserTabViewController.h"
#import "SEBSearchBarViewController.h"


@class AppDelegate;
@class SEBUIController;
@class SEBBrowserController;
@class SEBBrowserTabViewController;
@class SEBSearchBarViewController;
@class SEBiOSConfigFileController;
@class SEBInAppSettingsViewController;
@class SEBInitAssistantViewController;
@class SEBiOSInitAssistantViewController;
@class QRCodeReaderViewController;
@class AboutSEBiOSViewController;


@interface SEBViewController : UIViewController <IASKSettingsDelegate, SEBLockedViewControllerDelegate, QRCodeReaderDelegate, LGSideMenuDelegate, SEBBrowserControllerDelegate>
{
    UIBarButtonItem *leftButton;
    UIBarButtonItem *settingsShareButton;
    
@private
    NSInteger attempts;
    BOOL adminPasswordPlaceholder;
    BOOL quitPasswordPlaceholder;
    BOOL ASAMActiveChecked;
    BOOL sebUIInitialized;
    DDFileLogger *_myLogger;

    NSURL *currentConfigPath;
    NSURL *directlyDownloadedURL;

    NSString *currentStartURL;
    NSString *startURLQueryParameter;

    NSUInteger statusBarAppearance;
    BOOL browserToolbarEnabled;
    UIBarButtonItem *toolbarBackButton;
    UIBarButtonItem *toolbarForwardButton;
    UIBarButtonItem *toolbarReloadButton;
    CGFloat navigationBarItemsOffset;
}

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (weak) IBOutlet UIView *containerView;
@property (weak) IBOutlet LGSideMenuController *lgSideMenuController;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTopContraint;
@property (copy) NSURLRequest *request;

@property (strong, nonatomic) UIViewController *topMostController;
@property (strong, nonatomic) SEBBrowserController *browserController;
@property (strong, nonatomic) SEBBrowserTabViewController *browserTabViewController;
@property (strong, nonatomic) SEBUIController *sebUIController;
//@property (nonatomic, strong) SEBiOSDockController *dockController;
@property (strong, nonatomic) SEBSearchBarViewController *searchBarViewController;

@property (strong, nonatomic) SEBiOSInitAssistantViewController *assistantViewController;

@property (strong, nonatomic) AboutSEBiOSViewController *aboutSEBViewController;

@property (strong, nonatomic) SEBiOSLockedViewController< SEBLockedViewUIDelegate > *lockedViewController;
@property (strong, nonatomic) SEBiOSConfigFileController *configFileController;
@property (strong, nonatomic) SEBLockedViewController *sebLockedViewController;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic, retain) SEBInAppSettingsViewController *sebInAppSettingsViewController;

@property (strong, nonatomic) QRCodeReaderViewController *codeReaderViewController;
@property (strong, nonatomic) QRCodeReaderViewController *visibleCodeReaderViewController;

@property (nonatomic, strong) id <SEBConfigURLManagerDelegate> configURLManagerDelegate;

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertController *inactiveAlertController;
@property (strong, nonatomic) UIAlertController *allowediOSAlertController;

@property (strong, nonatomic) UIView *coveringView;
@property (strong, nonatomic) UIView *statusBarView;
@property (strong, nonatomic) UIView *navigationBarView;
@property (strong, nonatomic) UIView *toolBarView;
@property (strong, nonatomic) UIView *bottomBackgroundView;
@property (strong, nonatomic) NSArray *dockItems;

@property (strong, nonatomic) NSLayoutConstraint *statusBarBottomConstraint;
@property (strong, nonatomic) NSLayoutConstraint *toolBarHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarBottomConstraint;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarLeftConstraintToSafeArea;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarLeftConstraintToSuperView;

@property(readwrite) BOOL secureMode;
@property(readwrite) BOOL enableASAM;
@property(readwrite) BOOL allowSAM;

@property(readwrite) BOOL ASAMActive;
@property(readwrite) BOOL SAMActive;
@property(readwrite) BOOL singleAppModeActivated;

@property(readwrite) BOOL finishedStartingUp;
@property(readwrite) BOOL isReconfiguringToMDMConfig;
@property(readwrite) BOOL openCloseSlider;
@property(readwrite) BOOL viewDidLayoutSubviewsAlreadyCalled;
@property(readwrite) BOOL noSAMAlertDisplayed;
@property(readwrite) BOOL startSAMWAlertDisplayed;
@property(readwrite) BOOL pausedSAMAlertDisplayed;
@property(readwrite) BOOL endSAMWAlertDisplayed;
@property(readwrite) BOOL restartSessionAlertDisplayed;
@property(readwrite) BOOL aboutSEBViewDisplayed;
@property(readwrite) BOOL examRunning;
@property(readwrite) BOOL initAssistantOpen;
@property(readwrite) BOOL settingsOpen;
@property(readwrite) BOOL settingsDidClose;
@property(readwrite) BOOL sebLocked;
@property(readwrite) BOOL unlockPasswordEntered;
@property(readwrite) BOOL scannedQRCode;

@property(readwrite, strong) NSDate *didResignActiveTime;
@property(readwrite, strong) NSDate *didBecomeActiveTime;
@property(readwrite, strong) NSDate *didResumeExamTime;


- (void) initializeLogger;

- (BOOL) allowediOSVersion;
- (void) newWebViewTabDidMoveToParentViewController;

- (BOOL) handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

- (void) showConfigURLWarning:(NSError *)error;
- (void) scanQRCode;

- (void) conditionallyShowSettingsModal;
- (void) conditionallyResetSettings;
- (void) settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender;

- (void) showStartSingleAppMode;
- (void) startExam;
- (void) quitExamConditionally;
- (void) quitExamWithCallback:(id)callback selector:(SEL)selector;

- (void) stopAutonomousSingleAppMode;

- (void) conditionallyOpenLockdownWindows;
- (void) openLockdownWindows;

- (void) closeSettingsBeforeOpeningSEBConfig:(id)sebConfig
                                    callback:(id)callback
                                    selector:(SEL)selector;
- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData;
- (void) conditionallyOpenSEBConfigFromUniversalLink:(NSURL *)universalURL;
- (void) conditionallyOpenSEBConfigFromMDMServer;

- (void) storeSEBSettingsDownloadedDirectlySuccessful:(NSError *)error;
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

- (void) showToolbarNavigation:(BOOL)show;
- (void) setToolbarTitle:(NSString *)title;

#pragma mark - SEB Dock and left slider button handler

- (void) leftDrawerButtonPress:(id)sender;
- (void) showAboutSEB;
- (IBAction) backToStart;
- (IBAction) goBack;
- (IBAction) goForward;
- (IBAction) reload;

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
- (void) activateReloadButtonsExamTab:(BOOL)examTab;
- (void) activateReloadButtons:(BOOL)reloadEnabled;

// Delegate method to display an enter password dialog with the
// passed message text asynchronously, calling the callback
// method with the entered password when one was entered
- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;
// Delegate method to hide the previously displayed enter password dialog
- (void) hideEnterUsernamePasswordDialog;

@end

