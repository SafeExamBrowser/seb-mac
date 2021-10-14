

#import "ZoomSDKErrors.h"
/**
 * @brief ZOOM SDK live stream item.
 */
@interface ZoomSDKLiveStreamItem : NSObject
/**
 * @brief Get live stream URL.
 * @return The live stream URL.							   
 */
-(NSString*)getLiveStreamURL;
/**
 * @brief Get description of live stream URL.
 * @return The descriptions of live stream URL.
 */
-(NSString*)getLiveStreamURLDescription;
@end

@protocol ZoomSDKLiveStreamHelperDelegate <NSObject>
/**
 * @brief Callback of that the current live streaming status changes.
 * @param Status The live streaming status.
 */
-(void)onLiveStreamStatusChange:(LiveStreamStatus)status;

@end

@interface ZoomSDKLiveStreamHelper : NSObject
{
    id<ZoomSDKLiveStreamHelperDelegate> _delegate;
}
@property(nonatomic, assign)id<ZoomSDKLiveStreamHelperDelegate> delegate;
/**
 * @brief Query if it is able for the user to enable live stream.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */

- (ZoomSDKError)canStartLiveStream;

/**
 * @brief Get the items of live stream supported by the SDK.
 * @return If the function succeeds, it will return the items, otherwise failed.
 */

-(NSArray*)getSupportLiveStreamItem;

/**
 * @brief Start a live stream.
 * @param item The item of live stream supported by the SDK.
 * @return If the function succeeds, it will return the ZoomSDKError_Success, otherwise failed. 
 */
-(ZoomSDKError)startLiveStream:(ZoomSDKLiveStreamItem*)item;

/**
 * @brief Start a live stream with the URL customized by user.
 * @param streamURL The URL of customized live stream.
 * @param StreamKey The key of customized stream stream.
 * @param broadcastURL Everyone who uses this link can watch the live broadcast. 
 * @return If the function succeeds, it will return the ZoomSDKError_Success, otherwise failed.
 */
-(ZoomSDKError)startLiveStreamByURL:(NSString*)streamURL StreamKey:(NSString*)key BroadcastURL:(NSString*)broadcastURL;

/**
 * @brief Stop a live stream.
 * @return If the function succeeds, it will return the ZoomSDKError_Success, otherwise failed.
 */
-(ZoomSDKError)stopLiveStream;

/**
 * @brief Get the status of current live stream.
 * @return If the function succeeds, it will return the LiveStreamStatus_InProgress, otherwise failed.
 */
-(LiveStreamStatus)getLiveStreamStatus;

@end
