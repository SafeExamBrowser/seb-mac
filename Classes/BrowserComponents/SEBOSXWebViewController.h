//
//  SEBOSXWebViewController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 09.08.21.
//

#import <Cocoa/Cocoa.h>
#import "SEBAbstractWebView.h"

@class SEBAbstractWebView;

NS_ASSUME_NONNULL_BEGIN

@interface SEBOSXWebViewController : NSViewController {
    @private
    NSButton *overlayViewCloseButton;
    BOOL firstAppearance;
}

@property (strong, nonatomic) NSView *topOverlayMessageView;
@property (strong, nonatomic) NSPanel *topOverlayMessageHUD;

//@property (weak, nonatomic) id <SEBAbstractWebViewNavigationDelegate> navigationDelegate;
@property (strong, nonatomic) SEBAbstractWebView *sebAbstractWebView;

- (instancetype)initNewTabMainWebView:(BOOL)mainWebView
                       withCommonHost:(BOOL)commonHostTab
                        configuration:(WKWebViewConfiguration *)configuration
                   overrideSpellCheck:(BOOL)overrideSpellCheck
                             delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
