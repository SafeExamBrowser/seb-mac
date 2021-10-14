//
//  ZoomSDKRenderer.h
//  ZoomSDK

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

@class ZoomSDKYUVRawDataI420;

@interface ZoomSDKYUVRawDataI420 : NSObject
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
 * @brief Get the Y data.
 * @return If the function succeeds, it will return the Y data.
 */
-(char*)getYBuffer;
/**
 * @brief Get the U data.
 * @return If the function succeeds, it will return the U data.
 */
-(char*)getUBuffer;
/**
 * @brief Get the V data.
 * @return If the function succeeds, it will return the V data.
 */
-(char*)getVBuffer;
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
 * @brief Get if this data is limited I420 format.
 * @return If is limited I420 format, it will return YES. Otherwise NO.
 */
-(BOOL)isLimitedI420;
/**
 * @brief Get the stream width of this data.
 * @return If the function succeeds, it will return the stream width of this data.
 */
-(unsigned int)getStreamWidth;
/**
 * @brief Get the stream height of this data.
 * @return If the function succeeds, it will return the stream height of this data.
 */
-(unsigned int)getStreamHeight;
/**
 * @brief Get the rotation of this data.
 * @return If the function succeeds, it will return the rotation of this data.
 */
-(unsigned int)getRotation;
/**
 * @brief Get the source id of this data.
 * @return If the function succeeds, it will return the source id of this data.
 */
- (unsigned int)getSourceID;
@end


@protocol ZoomSDKRendererDelegate <NSObject>
- (void)onSubscribedUserDataOn;
- (void)onSubscribedUserDataOff;
- (void)onSubscribedUserLeft;
- (void)onRawDataReceived:(ZoomSDKYUVRawDataI420*)data;
- (void)onRendererBeDestroyed;
@end

@interface ZoomSDKRenderer : NSObject
{
    unsigned int                  _userID;
    ZoomSDKRawDataType            _rawDataType;
    ZoomSDKResolution             _resolution;
    id<ZoomSDKRendererDelegate>   _delegate;
}
@property(nonatomic, assign)id<ZoomSDKRendererDelegate> delegate;


/**
 * @brief Subscribe to receive raw data.
 * @param userID The user id of the raw data user want to receive.
 * @param rawDataType The type of raw data user want to receive.
 * @return If the function succeeds, it will return ZoomSDKError_Success.
 */
- (ZoomSDKError)subscribe:(unsigned int)userID rawDataType:(ZoomSDKRawDataType)rawDataType;

/**
 * @brief Unsubscribe to receive raw data.
 * @return If the function succeeds, it will return ZoomSDKError_Success.
 */
- (ZoomSDKError)unSubscribe;

/**
 * @brief Get the type of raw data.
 * @return If the function succeeds, it will return the type of raw data.
 */
- (ZoomSDKRawDataType)getRawDataType;

/**
 * @brief Get the user id of raw data user is subscribing.
 * @return If the function succeeds, it will return the user id.
 */
- (unsigned int)getUserID;

/**
 * @brief Get the resolution of raw data.
 * @return If the function succeeds, it will return the resolution.
 */
- (ZoomSDKResolution)getResolution;

/**
 * @brief Set the resolution of raw data.
 * @param resolution The resolution of raw data user want to receive.
 * @return If the function succeeds, it will return ZoomSDKError_Success.
 */
- (ZoomSDKError)setResolution:(ZoomSDKResolution)resolution;
@end

