
//  [Used for Customized UI]
#import "ZoomSDKErrors.h"

@protocol ZoomSDKShareElementDelegate <NSObject>
/**
 * @brief Callback event of sharer sending data.
 */
-(void)onShareContentStartReceiving;
/**
 * @brief Callback of the user ID changing when sharing.
 * @param userid The ID of new sharer.
 */
-(void)onShareSourceUserIDNotify:(unsigned int)userid;

@end

@interface ZoomSDKShareElement : NSObject
{
    unsigned int         _userId;
    ViewShareMode        _viewMode;
    NSView*              _shareView;
    id<ZoomSDKShareElementDelegate>   _delegate;
    NSRect                            _frame;
}
@property(nonatomic, assign) unsigned int userId;
@property(nonatomic, assign) ViewShareMode viewMode;
@property(nonatomic, assign) NSView*  shareView;
@property(nonatomic, assign) id<ZoomSDKShareElementDelegate> delegate;
/**
 * @brief Create a sharing element.
 * @param frame Frame of sharing view owned by the element.
 */
- (id)initWithFrame:(NSRect)frame;
/**
 * @brief Resize the frame of the shared view owned by this element
 * @param frame The coordinates of _shareview.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)resize:(NSRect)frame;
/**
 * @brief Set whether to show the share view or not.
 * @param show YES means to show, NO to hide.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)ShowShareRender:(BOOL)show;
@end

@protocol ZoomSDKShareContainerDelegate <NSObject>
/**
 * @brief Callback of that element is destroyed. 
 * @param element The object of ZoomSDKShareElement.
 */
-(void)onShareElementDestroy:(ZoomSDKShareElement*)element;
@end

@interface ZoomSDKShareContainer : NSObject
{
    NSMutableArray*                          _elementArray;
    id<ZoomSDKShareContainerDelegate>        _delegate;
}
@property(nonatomic, assign)id<ZoomSDKShareContainerDelegate>  delegate;
/**
 * @brief Create shared elements.
 * @param element The pointer to ZoomSDKShareElement object.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)createShareElement:(ZoomSDKShareElement**)element;
/**
 * @brief Clean shared elements.
 * @param element The pointer to ZoomSDKShareElement object.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)cleanShareElement:(ZoomSDKShareElement*)element;
/**
 * @brief Get an array of shared elements.
 * @return If the function succeeds, it will return a NSArray containing all sharing elements.
 */ 
-(NSArray*)getShareElementArray;
/**
 * @brief Get an array of shared elements by user ID.
 * @param userid The specified user id.
 * @return If the function succeeds, it will return an object of ZoomSDKShareElement.
 */
-(ZoomSDKShareElement*)getShareElementByUserID:(unsigned int)userid;

@end
