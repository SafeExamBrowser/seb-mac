//

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZoomSDKAppSignalController : NSObject

/**
 *@brief Show app signal panel.
 *@param point The original point to display app signal panel.
 *@param parentWindow The parent window to locate the application signal panel.
 *@return If the function succeeds, it will return ZoomSDKError_success, otherwise not.
 */
- (ZoomSDKError)showAANPanel:(NSPoint)point parentWindow:(NSWindow*)parentWindow;

/**
 *@brief Close app signal panel.
 *@return If the function succeeds, it will return ZoomSDKError_success, otherwise not.
 */
- (ZoomSDKError)hideAANPanel;

@end

NS_ASSUME_NONNULL_END
