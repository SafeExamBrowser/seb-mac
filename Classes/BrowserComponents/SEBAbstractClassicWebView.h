//
//  SEBAbstractClassicWebView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.03.21.
//

#import <Foundation/Foundation.h>
#import "SEBAbstractWebView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEBAbstractClassicWebView : NSObject <SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate>

@property (strong, nonatomic) id<SEBAbstractBrowserControllerDelegate> browserControllerDelegate;
@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate> navigationDelegate;

@end

NS_ASSUME_NONNULL_END
