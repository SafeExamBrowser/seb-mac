//
//  SEBViewController.m
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

#import <WebKit/WebKit.h>
#import "Constants.h"
#import "RNCryptor.h"
#import "MethodSwizzling.h"
#import <objc/runtime.h>
#import "SEBWKWebView.h"

//#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

#import "SEBViewController.h"

@interface SEBViewController () <WKNavigationDelegate>
{
    NSURL *currentConfigPath;
}

@property (weak) IBOutlet UIView *containerView;
@property (strong) SEBWKWebView *webView;
@property (copy) NSURLRequest *request;

@end

static NSMutableSet *browserWindowControllers;

@implementation SEBViewController

+ (WKWebViewConfiguration *)defaultWebViewConfiguration
{
    static WKWebViewConfiguration *configuration;
    
    if (!configuration) {
        configuration = [[WKWebViewConfiguration alloc] init];
    }
    
    return configuration;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [ViewController setupModifyRequest];

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.sebViewController = self;
    
    self.webViewController = self.childViewControllers[0];

//    self.webView = [[SEBWKWebView alloc] initWithFrame:self.containerView.bounds configuration:[[self class] defaultWebViewConfiguration]];
//    self.webView.navigationDelegate = self;
//
//    [self.containerView addSubview:self.webView];
//
//    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    [self.webView setTranslatesAutoresizingMaskIntoConstraints:true];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(guidedAccessChanged)
                                                 name:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [self showStartGuidedAccess];
}


- (BOOL) prefersStatusBarHidden
{
    return YES;
}


#pragma mark - Button Handlers
-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    [self.webViewController goBack];
}

- (IBAction)goForward:(id)sender {
    [self.webViewController goForward];
}

- (IBAction)reload:(id)sender {
    [self.webViewController reload];
}


// Called when the Guided Access status changes
- (void) guidedAccessChanged
{
    // Is the exam already running?
    if (self.examRunning) {
        
        // Exam running: Check if Guided Access is switched off
        if (UIAccessibilityIsGuidedAccessEnabled() == false) {
            
            // Dismiss the Guided Access warning alert if it still was visible
            if (self.guidedAccessWarningDisplayed) {
                [self.alertController dismissViewControllerAnimated:NO completion:nil];
                self.alertController = nil;
                self.guidedAccessWarningDisplayed = false;
            }
            
            // If there wasn't a lockdown covering view openend yet, initialize it
            if (!self.sebLocked) {
                
                if (!self.lockedViewController) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    self.lockedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBLockedView"];
                    self.lockedViewController.controllerDelegate = self;
                }
                
                if (!self.lockedViewController.resignActiveLogString) {
                    self.lockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
                }
                // Save current time for information about when Guided Access was switched off
                self.didResignActiveTime = [NSDate date];
                DDLogError(@"Guided Accesss switched off!");
                
                // Open the lockdown view
                [self.lockedViewController willMoveToParentViewController:self];
                
                UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                
                [rootViewController.view addSubview:self.lockedViewController.view];
                [rootViewController addChildViewController:self.lockedViewController];
                [self.lockedViewController didMoveToParentViewController:self];
                
                self.sebLocked = true;
                
                // Add log string for resign active
                [self.lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Guided Access switched off!", nil)] withTime:self.didResignActiveTime];
            }
        } else {
            // Guided Access is on again
            // Add log string
            self.didBecomeActiveTime = [NSDate date];
            [self.lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Guided Access is switched on again.", nil)] withTime:self.didBecomeActiveTime];
            
            // Close unlock windows only if the correct quit/restart password was entered already
            if (self.unlockPasswordEntered) {
                self.unlockPasswordEntered = false;
                [self.alertController dismissViewControllerAnimated:NO completion:nil];
                self.alertController = nil;
                [self.lockedViewController shouldCloseLockdownWindows];
            }
        }
    } else {
        // Exam is not yet running
        
        // If Guided Access switched on
        if (UIAccessibilityIsGuidedAccessEnabled() == true) {
            
            // Proceed to exam
            [self showGuidedAccessWarning];
            
        }
        // Guided Access off
        else if (self.guidedAccessWarningDisplayed) {
            // Guided Access warning was already displayed: dismiss it
            [self.alertController dismissViewControllerAnimated:NO completion:nil];
            self.alertController = nil;
            self.guidedAccessWarningDisplayed = false;
            
            [self showRestartGuidedAccess];
        }
    }
}


- (void) showStartGuidedAccess {
    if (UIAccessibilityIsGuidedAccessEnabled() == false) {
        self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Start Guided Access", nil)
                                                                    message:NSLocalizedString(@"Enable Guided Access in Settings -> General -> Accessibility and after returning to SEB, tripple click home button to proceed to exam.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:self.alertController animated:YES completion:nil];
    }
}

- (void) showRestartGuidedAccess {
    // If Guided Access isn't already on, show alert to switch it on again
    if (UIAccessibilityIsGuidedAccessEnabled() == false) {
        self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Restart Guided Access", nil)
                                                                    message:NSLocalizedString(@"Activate Guided Access with tripple click home button to return to exam.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:self.alertController animated:YES completion:nil];
    }
}


- (void) showGuidedAccessWarning
{
    // If Guided Access switched on
    if (UIAccessibilityIsGuidedAccessEnabled() == true) {
        // Proceed to exam
        [self.alertController dismissViewControllerAnimated:NO completion:nil];
        
        self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Guided Access Warning", nil)
                                                                          message:NSLocalizedString(@"Don't switch Guided Access off (home button tripple click or Touch ID) before submitting your exam, otherwise SEB will lock access to the exam! SEB will notify you when you're allowed to switch Guided Access off.", nil)
                                                                   preferredStyle:UIAlertControllerStyleAlert];
        [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"I Understand", nil)
                                                                       style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                           [self.alertController dismissViewControllerAnimated:NO completion:nil];
                                                                           self.alertController = nil;
                                                                           self.guidedAccessWarningDisplayed = false;
                                                                           
                                                                           [self startExam];
        }]];
        [self presentViewController:self.alertController animated:YES completion:nil];
        self.guidedAccessWarningDisplayed = true;
    }
}


- (void) correctPasswordEntered {
    // If necessary show the dialog to start Guided Access again
    [self showRestartGuidedAccess];

    // If Guided Access is already switched on, close lockdown window
    if (UIAccessibilityIsGuidedAccessEnabled() == true) {
        [self.lockedViewController shouldCloseLockdownWindows];
    }
}


- (void) startExam {
    //    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    self.examRunning = true;

    // Load start URL from the system's user defaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    
    [self.webViewController openNewTabWithURL:[NSURL URLWithString:urlText]];
}


- (void) downloadAndOpenSebConfigFromURL:(NSURL *)url
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (NSUserDefaults.userDefaultsPrivate) {
            // If yes, we don't download the .seb file
            if (self.alertController) {
                [self.alertController dismissViewControllerAnimated:NO completion:nil];
            }
            self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Loading New SEB Settings Not Allowed!", nil)
                                                                              message:NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam and use a quit link or the quit button in SEB before starting another exam.", nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];
            [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                               [self.alertController dismissViewControllerAnimated:NO completion:nil];
                                                                               [self showStartGuidedAccess];
                                                                           }]];
            [self presentViewController:self.alertController animated:YES completion:nil];

        } else {
            // SEB isn't in exam mode: reconfiguring it is allowed
            NSError *error = nil;
            NSData *sebFileData;
            // Download the .seb file directly into memory (not onto disc like other files)
            if ([url.scheme isEqualToString:@"seb"]) {
                // If it's a seb:// URL, we try to download it by http
                NSURL *httpURL = [[NSURL alloc] initWithScheme:@"http" host:url.host path:url.path];
                sebFileData = [NSData dataWithContentsOfURL:httpURL options:NSDataReadingUncached error:&error];
                if (error) {
                    // If that didn't work, we try to download it by https
                    NSURL *httpsURL = [[NSURL alloc] initWithScheme:@"https" host:url.host path:url.path];
                    sebFileData = [NSData dataWithContentsOfURL:httpsURL options:NSDataReadingUncached error:&error];
                    // Still couldn't download the .seb file: present an error and abort
                    if (error) {
//                        [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                        return;
                    }
                }
            } else if ([url.scheme isEqualToString:@"sebs"]) {
                // If it's a sebs:// URL, we try to download it by https
                NSURL *httpsURL = [[NSURL alloc] initWithScheme:@"https" host:url.host path:url.path];
                sebFileData = [NSData dataWithContentsOfURL:httpsURL options:NSDataReadingUncached error:&error];
                // Couldn't download the .seb file: present an error and abort
                if (error) {
//                    [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                    return;
                }
            } else {
                sebFileData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
                if (error) {
//                    [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                }
            }
            SEBiOSConfigFileController *configFileManager = [[SEBiOSConfigFileController alloc] init];
            
            // Get current config path
            currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
            // Store the URL of the .seb file as current config file path
            [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:url.lastPathComponent]]; // absoluteString]];
            
            [configFileManager storeNewSEBSettings:sebFileData forEditing:false callback:self selector:@selector(storeNewSEBSettingsSuccessful:)];
        }
    }
}


- (void) storeNewSEBSettingsSuccessful:(BOOL)success
{
    [self showStartGuidedAccess];
    
    if (success) {
        // Post a notification that it was requested to restart SEB with changed settings
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestRestartNotification" object:self];
        
    } else {
        // if decrypting new settings wasn't successfull, we have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
    }
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end