
//  [Used for Customized UI]
#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

 /**   
  @note This class is available only for custom UI.
  */ 
@class  ZoomSDKVideoContainer;
@interface ZoomSDKVideoElement : NSObject
{
    VideoRenderElementType _elementType;
    VideoRenderDataType    _dataType;
    unsigned int           _userid;
    NSView*                _videoView;
    NSRect                 _viewFrame;
}

@property(nonatomic, assign)unsigned int userid;
@property(nonatomic, assign)NSView*  videoView;
/**
 * @brief Create object of video elements for each user.
 * @param rect Frame of video view.
 */
- (id)initWithFrame:(NSRect)rect;
/**
 * @brief Set whether to show video.
 * @param show YES means displaying video, otherwise not.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)showVideo:(BOOL)show;
/**
 * @brief Get the type of the video render element: preview/active/normal.
 * @return The type of the video render element.
 */
- (VideoRenderElementType)getElementType;
/**
 * @brief Get data type of video render: avatar/video.
 * @return The data type of the video render.
 */
- (VideoRenderDataType)getDataType;
/**
 * @brief Get NSView object in the element.  
 * @return The point of the video view. 
 */
- (NSView*)getVideoView;
/**
 * @brief Resize the video view according to your requirements.
 * @param frame Custom frame of video view.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)resize:(NSRect)frame;

/**
 * @brief Config the video view resolution.
 * @param resolution Custom resolution of video view.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)setResolution:(ZoomSDKVideoRenderResolution)resolution;
@end

@interface ZoomSDKPreViewVideoElement : ZoomSDKVideoElement
/**
 * @brief Set whether to preview video.
 * @param start YES means starting preview, otherwise not.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)startPreview:(BOOL)start;
@end


@interface ZoomSDKActiveVideoElement : ZoomSDKVideoElement
/**
 * @brief Set whether to display active video.
 * @param start YES means starting active video, otherwise not.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)startActiveView:(BOOL)start;
@end

@interface ZoomSDKNormalVideoElement : ZoomSDKVideoElement
/**
 * @brief Set whether to display user's video. 
 * @param subscribe YES means to display user's avatar or video, otherwise display a black background.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)subscribeVideo:(BOOL)subscribe;
@end

@protocol ZoomSDKVideoContainerDelegate <NSObject>
/**
 * @brief Callback of user ID changes in the video container.
 * @param element Element of the new user.
 * @param userid The ID of changed user.
 */
-(void)onRenderUserChanged:(ZoomSDKVideoElement*)element User:(unsigned int)userid;

/**
 * @brief Callback of user data changes in the video container.
 * @param element Element of the new user.
 * @param type Data type of the current user.
 */
-(void)onRenderDataTypeChanged:(ZoomSDKVideoElement*)element DataType:(VideoRenderDataType)type;

/**
 * @brief Callback of user's subscription failed.
 * @param element The point of element to the user.
 * @param error The error of the failed reason.
 */
-(void)onCustomVideoSubscribeFail:(ZoomSDKVideoElement*)element error:(int)error NS_DEPRECATED_MAC(5.2, 5.7);

/**
 * @brief Callback of user's subscription failed.
 * @param error The error of the failed reason.
 * @param element The point of video element to the user.
 */
-(void)onSubscribeUserFail:(ZoomSDKVideoSubscribeFailReason)error videoElement:(ZoomSDKVideoElement*)element NS_AVAILABLE_MAC(5.7);
@end

@interface ZoomSDKVideoContainer : NSObject
{
    id<ZoomSDKVideoContainerDelegate> _delegate;
    NSMutableArray*                          _elementArray;
}
@property(nonatomic,assign) id<ZoomSDKVideoContainerDelegate> delegate;
/**
 * @brief Create a video element in the video container.
 * @param element An object of ZoomSDKVideoElement*. 
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)createVideoElement:(ZoomSDKVideoElement**)element;
/**
 * @brief Destroy an existed video element in the video container.
 * @param element An object of ZoomSDKVideoElement*.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)cleanVideoElement:(ZoomSDKVideoElement*)element;
/**
 * @brief Get the list of video element.
 * @return If the function succeeds, it will return an array containing ZoomSDKVideoElement object.
 */
-(NSArray*)getVideoElementList;
@end

