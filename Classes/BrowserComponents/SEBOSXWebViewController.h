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

@interface SEBOSXWebViewController : NSViewController

//@property (weak, nonatomic) id <SEBAbstractWebViewNavigationDelegate> navigationDelegate;
@property (strong, nonatomic) SEBAbstractWebView *sebAbstractWebView;

- (instancetype)initNewTabWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
