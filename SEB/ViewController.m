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

#import "ViewController.h"

@interface ViewController () <WKNavigationDelegate>

@property (weak) IBOutlet UIView *containerView;
@property (strong) SEBWKWebView *webView;
@property (copy) NSURLRequest *request;

@end

static NSMutableSet *browserWindowControllers;

@implementation ViewController

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
    
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Load start URL from the system's user defaults
    NSString *urlText = @"http://safeexambrowser.org/exams"; //[preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
//    NSString *urlText = @"https://view.ethz.ch/portal/webclient/index.html#/login";
    
    self.request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]];

    [self.webView loadRequest:self.request];
    self.request = nil;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end