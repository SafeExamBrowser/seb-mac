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

    //self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}


- (void)viewDidAppear:(BOOL)animated {
    
    self.alertController = [UIAlertController  alertControllerWithTitle:@"Start Guided Access" message:@"Activate Guided Access in Settings -> General -> Accessibility and after returning to SEB, tripple click home button to proceed to exam."  preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:self.alertController animated:YES completion:nil];
}


- (void)dissmissGuidedAccessAlert
{
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
    
}


- (void)startExam {
    //    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Load start URL from the system's user defaults
    NSString *urlText = @"http://safeexambrowser.org/exams"; //[preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    //    NSString *urlText = @"https://view.ethz.ch/portal/webclient/index.html#/login";
    
    self.request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]];
    
    [self.webView loadRequest:self.request];
    self.request = nil;
    
    self.alertController = [UIAlertController  alertControllerWithTitle:@"Guided Access Warning" message:@"Don't switch Guided Access off (home button tripple click or Touch ID) before submitting your exam! SEB will notify you, when you're allowed to switch Guided Access off. If you try to switch it off during the exam, SEB will lock access to the exam."  preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.alertController dismissViewControllerAnimated:YES completion:nil];
        self.alertController = nil;
    }]];
    [self presentViewController:self.alertController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end