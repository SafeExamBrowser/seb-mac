//
//  SEBAbstractWebView.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 04.11.20.
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
#import <WebKit/WebKit.h>
#import "SEBURLFilter.h"

NS_ASSUME_NONNULL_BEGIN

@class SEBAbstractWebView;
@class SEBURLFilter;
@class WKWebView;
@class SEBNavigationAction;

@protocol SEBAbstractBrowserControllerDelegate <NSObject>

@optional
- (id) nativeWebView;
- (void) closeWKWebView;
- (nullable NSURL*) url;
- (nullable NSString*) pageTitle;
- (BOOL) canGoBack;
- (BOOL) canGoForward;

- (void) goBack;
- (void) goForward;
- (void) clearBackForwardList;
- (void) loadURL:(NSURL *)url;
- (void) stopLoading;
- (void) reload;

- (void) focusFirstElement;
- (void) focusLastElement;

@property (readonly) BOOL zoomPageSupported;
- (void) zoomPageIn;
- (void) zoomPageOut;
- (void) zoomPageReset;
- (void) updateZoomScale:(double)zoomScale;

- (void) textSizeIncrease;
- (void) textSizeDecrease;
- (void) textSizeReset;

- (NSString *) stringByEvaluatingJavaScriptFromString:(NSString *)js;

- (void) searchText:(nullable NSString *)textToSearch backwards:(BOOL)backwards caseSensitive:(BOOL)caseSensitive;

- (void) privateCopy:(id)sender;
- (void) privateCut:(id)sender;
- (void) privatePaste:(id)sender;
- (void) clearPrivatePasteboard;

- (void) loadView;
- (void) didMoveToParentViewController;
- (void) viewDidLayout;
- (void) viewDidLayoutSubviews;
- (void) viewWillTransitionToSize;
- (void) viewDidLoad;
- (void) viewWillAppear;
- (void) viewWillAppear:(BOOL)animated;
- (void) viewDidAppear;
- (void) viewDidAppear:(BOOL)animated;
- (void) viewWillDisappear;
- (void) viewWillDisappear:(BOOL)animated;
- (void) viewDidDisappear;
- (void) viewDidDisappear:(BOOL)animated;

- (void) stopMediaPlaybackWithCompletionHandler:(void (^)(void))completionHandler;

- (void) toggleScrollLock;
- (BOOL) isScrollLockActive;

- (void) setPrivateClipboardEnabled:(BOOL)privateClipboardEnabled;
- (void) setAllowDictionaryLookup:(BOOL)allowDictionaryLookup;
- (void) setAllowPDFPlugIn:(BOOL)allowPDFPlugIn;

- (void) disableFlashFullscreen;

- (void) sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task;

@property (readwrite, nonatomic) BOOL downloadingSEBConfig;

@end


@protocol SEBAbstractWebViewNavigationDelegate <NSObject>

@optional
@property (readonly, nonatomic) WKWebViewConfiguration *wkWebViewConfiguration;
@property (nullable, readonly, nonatomic) id accessibilityDock;
- (void) setPageTitle:(NSString *)title;
- (void) setLoading:(BOOL)loading;
- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(NSURL *)url;
- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url;
- (void) firstDOMElementDeselected;
- (void) lastDOMElementDeselected;

- (SEBAbstractWebView *) openNewTabWithURL:(nullable NSURL *)url
                             configuration:(nullable WKWebViewConfiguration *)configuration;
- (SEBAbstractWebView *) openNewWebViewWindowWithURL:(nullable NSURL *)url
                                       configuration:(nullable WKWebViewConfiguration *)configuration;

- (void) makeActiveAndOrderFront;
- (void) showWebView:(SEBAbstractWebView *)webView;
- (void) closeWebView;
- (void) closeWebView:(SEBAbstractWebView *)webView;
- (void) addWebView:(id)nativeWebView;
- (void) addWebViewController:(id)webViewController;

@property (readonly, nonatomic) SEBAbstractWebView *abstractWebView;
@property (nullable, strong, nonatomic) NSURL *currentURL;
@property (strong, nonatomic) NSString  *_Nullable currentMainHost;
@property (readonly) BOOL isMainBrowserWebViewActive;
@property (readwrite) BOOL isMainBrowserWebView;
@property (readwrite) BOOL isNavigationAllowed;
- (BOOL) isNavigationAllowedMainWebView:(BOOL)mainWebView;
@property (readwrite) BOOL isReloadAllowed;
- (BOOL) isReloadAllowedMainWebView:(BOOL)mainWebView;
@property (readwrite) BOOL showReloadWarning;
- (BOOL) showReloadWarningMainWebView:(BOOL)mainWebView;
- (NSString *) webPageTitle:(NSString *)title orURL:(NSURL *)url mainWebView:(BOOL)mainWebView;
@property (readonly, nonatomic) NSString *quitURL;
@property (readonly, nonatomic) NSString *pageJavaScript;
@property (readonly) BOOL allowDownUploads;
- (void) showAlertNotAllowedDownUploading:(BOOL)uploading;
@property (readonly) BOOL downloadPDFFiles;
@property (readonly) BOOL directConfigDownloadAttempted;
@property (readonly) BOOL allowSpellCheck;
@property (readonly) BOOL overrideAllowSpellCheck;
- (NSURLRequest *) modifyRequest:(NSURLRequest *)request;
- (NSString *) browserExamKeyForURL:(NSURL *)url;
- (NSString *) configKeyForURL:(NSURL *)url;
- (NSString *) appVersion;

@property (readwrite, nonatomic) double pageZoom;

- (void) searchTextMatchFound:(BOOL)matchFound;


@property (readonly, nonatomic) NSString *customSEBUserAgent;
// Currently required by SEB-macOS
@property (nullable, readwrite, nonatomic) NSArray<NSData *> *privatePasteboardItems;
- (void) storePasteboard;
- (void) restorePasteboard;

- (void) presentAlertWithTitle:(NSString *)title
                       message:(NSString *)message;

// Required by SEB-iOS
- (SEBBackgroundTintStyle) backgroundTintStyle;

// Required by SEB-macOS
@property (weak, nonatomic) id __nullable window;
@property (readonly) BOOL isAACEnabled;

// Required by SEB-iOS
@property (strong, nonatomic) id __nullable uiAlertController;

- (void)sebWebViewDidStartLoad;
- (void)sebWebViewDidFinishLoad;
- (void)sebWebViewDidFailLoadWithError:(NSError *)error;
- (SEBNavigationAction *)decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                  newTab:(BOOL)newTab
                                           configuration:(nullable WKWebViewConfiguration *)configuration
                                        downloadFilename:(nullable NSString *)downloadFilename;
- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title;
- (void)sebWebViewDidUpdateProgress:(double)progress;
- (SEBNavigationResponsePolicy)decidePolicyForMIMEType:(nullable NSString*)mimeType
                                                   url:(nullable NSURL *)url
                                       canShowMIMEType:(BOOL)canShowMIMEType
                                        isForMainFrame:(BOOL)isForMainFrame
                                     suggestedFilename:(nullable NSString *)suggestedFilename
                                               cookies:(nullable NSArray <NSHTTPCookie *>*)cookies;

- (void)webView:(WKWebView *)webView
didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView
didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;

- (void)webView:(nullable WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler;

- (void)webView:(WKWebView *)webView
didCommitNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView
didFinishNavigation:(WKNavigation *)navigation;

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView;

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

- (nullable WKWebView *)webView:(WKWebView *)webView
createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
   forNavigationAction:(WKNavigationAction *)navigationAction
        windowFeatures:(WKWindowFeatures *)windowFeatures;

- (void)webViewDidClose:(WKWebView *)webView;

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler;

- (void)pageTitle:(NSString *)pageTitle
runJavaScriptAlertPanelWithMessage:(NSString *)message;

- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler;

- (BOOL)pageTitle:(NSString *)pageTitle
runJavaScriptConfirmPanelWithMessage:(NSString *)message;

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString *result))completionHandler;

- (NSString *)pageTitle:(NSString *)pageTitle
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
            defaultText:(NSString *)defaultText;

- (void)webView:(nullable WKWebView *)webView
runOpenPanelWithParameters:(id)parameters
initiatedByFrame:(nullable WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler;

- (void)webView:(WKWebView *)webView
navigationAction:(WKNavigationAction *)navigationAction
didBecomeDownload:(WKDownload *)download API_AVAILABLE(macos(11.3), ios(14.5));

- (void)download:(WKDownload *)download
decideDestinationUsingResponse:(NSURLResponse *)response
suggestedFilename:(NSString *)suggestedFilename
completionHandler:(void (^)(NSURL * _Nullable destination))completionHandler API_AVAILABLE(macos(11.3), ios(14.5));

- (void)downloadDidFinish:(WKDownload *)download API_AVAILABLE(macos(11.3), ios(14.5));

- (void)download:(WKDownload *)download
didFailWithError:(NSError *)error
      resumeData:(nullable NSData *)resumeData API_AVAILABLE(macos(11.3), ios(14.5));


- (WKPermissionDecision)permissionDecisionForType:(WKMediaCaptureType)type API_AVAILABLE(macos(12.0), ios(15.0));
@property (readonly) BOOL browserMediaCaptureScreen;
- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler;
#if TARGET_OS_IPHONE
- (void) presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion;
#endif
- (BOOL) showURLFilterAlertForRequest:(NSURLRequest *)request
                     forContentFilter:(BOOL)contentFilter
                       filterResponse:(URLFilterRuleActions)filterResponse;
- (void) loadWebPageOrSearchResultWithString:(NSString *)webSearchString;

// Currently required by SEB-iOS
- (void) openCloseSliderForNewTab;
- (void) switchToTab:(nullable id)sender;
- (void) switchToNextTab;
- (void) switchToPreviousTab;
- (void) closeTab;
- (void) closeTabWithIndex:(NSUInteger)tabIndex;

@property (readonly) NSURL *downloadPathURL;
- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename cookies:(NSArray <NSHTTPCookie *>*)cookies;
- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename cookies:(NSArray <NSHTTPCookie *>*)cookies sender:(nullable id <SEBAbstractBrowserControllerDelegate>)sender;
- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) openSEBConfigFromData:(NSData *)sebConfigData;
- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL cookies:(NSArray <NSHTTPCookie *>*)cookies;
- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL cookies:(NSArray <NSHTTPCookie *>*)cookies sender:(nullable id <SEBAbstractBrowserControllerDelegate>)sender;
@property (readonly) BOOL downloadingInTemporaryWebView;
// Required by SEB-iOS (SEBUIWebViewController)
- (BOOL) originalURLIsEqualToURL:(NSURL *)url;

@end


@protocol WKUIDelegatePrivateSEB <NSObject>

typedef NS_OPTIONS(NSUInteger, _WKCaptureDevices) {
    _WKCaptureDeviceMicrophone = 1 << 0,
    _WKCaptureDeviceCamera = 1 << 1,
    _WKCaptureDeviceDisplay = 1 << 2,
};

typedef NS_ENUM(NSInteger, WKDisplayCapturePermissionDecision) {
    WKDisplayCapturePermissionDecisionDeny,
    WKDisplayCapturePermissionDecisionScreenPrompt,
    WKDisplayCapturePermissionDecisionWindowPrompt,
};

- (void)_webView:(WKWebView *)webView requestUserMediaAuthorizationForDevices:(_WKCaptureDevices)devices url:(NSURL *)url mainFrameURL:(NSURL *)mainFrameURL decisionHandler:(void (^)(BOOL authorized))decisionHandler;

- (void)_webView:(WKWebView *)webView requestDisplayCapturePermissionForOrigin:(WKSecurityOrigin *)securityOrigin initiatedByFrame:(WKFrameInfo *)frame withSystemAudio:(BOOL)withSystemAudio decisionHandler:(void (^)(WKDisplayCapturePermissionDecision decision))decisionHandler;

- (void)_webView:(WKWebView *)webView queryPermission:(NSString*)name forOrigin:(WKSecurityOrigin*)origin completionHandler:(void (^)(WKPermissionDecision permissionState))completionHandler API_AVAILABLE(macos(12.0), ios(15.0));

@end


@interface SEBAbstractWebView : NSObject <SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate> {
    
@private
    NSString *quitURLTrimmed;
    SEBURLFilter *urlFilter;
}


@property (strong, nonatomic) id<SEBAbstractBrowserControllerDelegate> browserControllerDelegate;
@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate> navigationDelegate;

@property (readwrite) BOOL isMainBrowserWebView;
@property (strong, nonatomic) NSURL *originalURL;
@property (readwrite) BOOL isNavigationAllowed;
@property (readwrite) BOOL isReloadAllowed;
@property (readwrite) BOOL showReloadWarning;
@property (readwrite, nonatomic) BOOL allowSpellCheck;
@property (readwrite, nonatomic) BOOL overrideAllowSpellCheck;
@property (readonly) BOOL downUploadsAllowed;
@property (readonly) BOOL downloadPDFFiles;
@property (weak, nonatomic) SEBAbstractWebView *creatingWebView;
@property (strong, nonatomic) NSMutableArray *notAllowedURLs;
@property (readwrite) BOOL dismissAll;


- (instancetype)initNewTabMainWebView:(BOOL)mainWebView
                       withCommonHost:(BOOL)commonHostTab
                        configuration:(WKWebViewConfiguration *)configuration
                   overrideSpellCheck:(BOOL)overrideSpellCheck
                             delegate:(id <SEBAbstractWebViewNavigationDelegate>)delegate;
- (void) initGeneralProperties;

@end


@interface SEBWKNavigationAction : WKNavigationAction

@property (readwrite, nonatomic) WKNavigationType writableNavigationType;
@property (readwrite, nonatomic) NSURLRequest *writableRequest;

@end


@interface SEBNavigationAction : NSObject

@property (readwrite, nonatomic) SEBNavigationActionPolicy policy;
@property (nullable, weak, nonatomic) SEBAbstractWebView *openedWebView;

@end


#if TARGET_OS_OSX
@interface WKPreferences ()

- (void)_setDeveloperExtrasEnabled:(BOOL)developerExtrasEnabled;
- (void)_setShouldAllowUserInstalledFonts:(BOOL)_shouldAllowUserInstalledFonts;
- (void)_setFullScreenEnabled:(BOOL)fullScreenEnabled;
- (void)_setAllowsPictureInPictureMediaPlayback:(BOOL)allowed;

@end
#endif

NS_ASSUME_NONNULL_END
