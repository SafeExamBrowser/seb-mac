//
//  SEBiOSBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.04.21.
//

#import "SEBBrowserController.h"
#import "SEBViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SEBViewController;

@interface SEBiOSBrowserController : SEBBrowserController <SEBBrowserControllerDelegate>

@property (weak, nonatomic) SEBViewController *sebViewController;
@property(readwrite) BOOL openingSettings;

@end

NS_ASSUME_NONNULL_END
