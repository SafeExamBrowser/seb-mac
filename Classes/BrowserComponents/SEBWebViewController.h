//
//  SEBWebViewController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 02.07.21.
//

#import <Foundation/Foundation.h>
#import "SEBAbstractWebView.h"
#import "SEBWebView.h"
#import <WebKit/WebKit.h>

#import "SEBBrowserWindowController.h"
#import "SEBWebView.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "SEBOSXBrowserController.h"
#import "SEBTextField.h"

@class SEBAbstractClassicWebView;
@class SEBWebView;
@class SEBURLFilter;

NS_ASSUME_NONNULL_BEGIN

@interface SEBWebViewController : NSViewController <SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate, WebUIDelegate, WebPolicyDelegate, WebFrameLoadDelegate, WebResourceLoadDelegate, NSURLDownloadDelegate>

@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate> navigationDelegate;

//@property (weak) SEBBrowserTabViewController *browserTabViewController;
@property (nonatomic, strong) SEBWebView *sebWebView;
@property (strong) NSString *currentURL;
@property (strong) NSString *currentMainHost;
@property (strong) NSURLRequest *currentRequest;
@property (readwrite) BOOL allowDownloads;
@property (readwrite) BOOL allowDeveloperConsole;

- (NSView*) findFlashViewInView:(NSView*)view;

@end

NS_ASSUME_NONNULL_END
