//
//  ViewController.m
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//
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
    
    self.webView = [[SEBWKWebView alloc] initWithFrame:self.containerView.bounds configuration:[[self class] defaultWebViewConfiguration]];
    self.webView.navigationDelegate = self;

    [self.containerView addSubview:self.webView];

    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:true];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(guidedAccessChanged) name:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [self showStartGuidedAccess];
}


- (BOOL) prefersStatusBarHidden
{
    return YES;
}


// Called when the Guided Access status changes
- (void) guidedAccessChanged
{
    // Is the exam already running?
    if (self.examRunning) {
        
        // Exam running: Check if Guided Access is switched off
        if (UIAccessibilityIsGuidedAccessEnabled() == false) {
            
            // Dismiss the Guided Access warning alert if it still was visible
            if (self.guidedAccessWarningAC) {
                [self.guidedAccessWarningAC dismissViewControllerAnimated:YES completion:nil];
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
                [self.view addSubview:self.lockedViewController.view];
                [self addChildViewController:self.lockedViewController];
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
                [self.alertController dismissViewControllerAnimated:YES completion:nil];
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
        else if (self.guidedAccessWarningAC) {
            // Guided Access warning was already displayed: dismiss it
            [self.guidedAccessWarningAC dismissViewControllerAnimated:YES completion:nil];
            self.guidedAccessWarningAC = nil;
            
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
        [self.alertController dismissViewControllerAnimated:YES completion:nil];
        
        self.guidedAccessWarningAC = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Guided Access Warning", nil)
                                                                          message:NSLocalizedString(@"Don't switch Guided Access off (home button tripple click or Touch ID) before submitting your exam, otherwise SEB will lock access to the exam! SEB will notify you when you're allowed to switch Guided Access off.", nil)
                                                                   preferredStyle:UIAlertControllerStyleAlert];
        [self.guidedAccessWarningAC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"I Understand", nil)
                                                                       style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.guidedAccessWarningAC dismissViewControllerAnimated:YES completion:nil];
            self.guidedAccessWarningAC = nil;
            
            [self startExam];
        }]];
        [self presentViewController:self.guidedAccessWarningAC animated:YES completion:nil];
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
    NSString *urlText = @"http://safeexambrowser.org/exams"; //[preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    //    NSString *urlText = @"https://view.ethz.ch/portal/webclient/index.html#/login";
    
    self.request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]];
    
    [self.webView loadRequest:self.request];
    self.request = nil;
    
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end