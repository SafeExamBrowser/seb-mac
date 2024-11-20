//
//  HUDController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 05.12.20.
//

#import <Foundation/Foundation.h>
#import "HUDPanel.h"

@class HUDPanel;

NS_ASSUME_NONNULL_BEGIN

@interface HUDController : NSObject

@property(strong, nonatomic) NSView *progressIndicatorView ;
@property(strong, nonatomic) NSPanel *progressIndicatorHUD ;

+ (HUDPanel *) createOverlayPanelWithView:(NSView *)overlayView size:(CGSize)size;
- (void) showHUDProgressIndicator;
- (void) hideHUDProgressIndicator;

@end

NS_ASSUME_NONNULL_END
