//
//  ZoomSDKRawDataController.h
//  ZoomSDK
//

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"
#import "ZoomSDKRenderer.h"

@class ZoomSDKRawDataVideoSourceController;

@interface ZoomSDKAudioRawData : NSObject
/**
 * @brief Get if this object can add ref.
 * @return If can add ref, it will return YES. Otherwise NO.
 */
-(BOOL)canAddRef;
/**
 * @brief Add reference for this object, if you doesn't add ref, this object will be released when the callback response ends.
 * @return If the function succeeds, it will return YES. Otherwise NO.
 */
-(BOOL)addRef;
/**
 * @brief Release the object, if you has add ref, remeber to call this api to release when you wantn't to use this object.
 * @return If the function succeeds, it will return reference count of this object.
 */
-(int)releaseData;
/**
 * @brief Get the buffer data.
 * @return If the function succeeds, it will return the buffer data.
 */
-(char*)getBuffer;
/**
 * @brief Get the buffer length of this data.
 * @return If the function succeeds, it will return the buffer length of this data.
 */
-(unsigned int)getBufferLen;
/**
 * @brief Get the sample rate of this data.
 * @return If the function succeeds, it will return the sample rate of this data.
 */
-(unsigned int)getSampleRate;
/**
 * @brief Get the channel number of this data.
 * @return If the function succeeds, it will return the channel number of this data.
 */
-(unsigned int)getChannelNum;
@end

@protocol ZoomSDKAudioRawDataDelegate <NSObject>
/**
 * @brief Notify to receive the mixed audio raw data.
 * @param data The received audio raw data.
 */
- (void)onMixedAudioRawDataReceived:(ZoomSDKAudioRawData*)data;
/**
 * @brief Notify to receive the one way audio raw data.
 * @param data The received audio raw data.
 * @param nodeID The user id of received user's data.
 */
- (void)onOneWayAudioRawDataReceived:(ZoomSDKAudioRawData*)data nodeID:(unsigned int)nodeID;
@end

@interface ZoomSDKAudioRawDataHelper : NSObject
{
    id<ZoomSDKAudioRawDataDelegate> _delegate;
}
@property(nonatomic, assign)id<ZoomSDKAudioRawDataDelegate> delegate;
/**
 * @brief Start the audio raw data process.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)subscribe;
/**
 * @brief Stop the audio raw data process.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)unSubscribe;
@end


@interface ZoomSDKRawDataController : NSObject
{
    ZoomSDKAudioRawDataHelper*              _audioRawDataHelper;
    ZoomSDKRawDataVideoSourceController*    _rawDataVideoSourceHelper;
}
/**
 * @brief Query if the user has raw data license.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not ZoomSDKError_NoPermission.
 */
- (ZoomSDKError)hasRawDataLicense;
/**
 * @brief Get the object of ZoomSDKAudioRawDataHelper.
 * @param audioRawDataHelper, the point to the object of ZoomSDKAudioRawDataHelper.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)getAudioRawDataHelper:(ZoomSDKAudioRawDataHelper**)audioRawDataHelper;

/**
 * @brief Get the object of ZoomSDKRawDataVideoSourceController.
 * @param videoRawDataSendHelper, the point to the object of ZoomSDKRawDataVideoSourceController.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)getRawDataVideoSourceHelper:(ZoomSDKRawDataVideoSourceController**)videoRawDataSendHelper;

/**
 * @brief Creat the object of ZoomSDKRenderer.
 * @param render, the point to the object of ZoomSDKRenderer.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)creatRender:(ZoomSDKRenderer**)render;

/**
 * @brief Destory the object of ZoomSDKRenderer.
 * @param render, the point to the object of ZoomSDKRenderer.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)destoryRender:(ZoomSDKRenderer*)render;
@end
