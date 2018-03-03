//
//  SEBUIController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.02.18.
//

#import <UIKit/UIKit.h>
#import "SEBViewController.h"
#import "SEBSliderItem.h"

@class SEBViewController;

@interface SEBUIController : NSObject {
    
    UIBarButtonItem *dockBackButton;
    UIBarButtonItem *dockForwardButton;
    UIBarButtonItem *dockReloadButton;
    SEBSliderItem *sliderBackButtonItem;
    SEBSliderItem *sliderForwardButtonItem;
    SEBSliderItem *sliderReloadButtonItem;

}

@property (strong, nonatomic) SEBViewController *sebViewController;

@property (nonatomic, strong) NSArray *leftSliderCommands;
@property (nonatomic, strong) NSArray *dockItems;

@end
