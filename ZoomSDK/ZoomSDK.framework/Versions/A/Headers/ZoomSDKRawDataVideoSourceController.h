//
//  ZoomSDKRawDataVideoSourceController.h
//  ZoomSDK
//
//  Created by derain on 2020/8/10.
//  Copyright © 2020 TOTTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZoomSDKRawDataController.h"


@interface ZoomSDKYUVProcessDataI420 : NSObject
/**
 * @brief Get the width of this data.
 * @return If the function succeeds, it will return the width of this data.
 */
- (unsigned int)getWidth;

/**
 * @brief Get the height of this data.
 * @return If the function succeeds, it will return the height of this data.
 */
- (unsigned int)getHeight;

/**
 * @brief Get the Y buffer of this data.
 * @return If the function succeeds, it will return the Y buffer of this data.
 */
- (char*)getYBuffer:(unsigned int)lineNum;

/**
 * @brief Get the U buffer of this data.
 * @return If the function succeeds, it will return the U buffer of this data.
 */
- (char*)getUBuffer:(unsigned int)lineNum;

/**
 * @brief Get the V buffer of this data.
 * @return If the function succeeds, it will return the V buffer of this data.
 */
- (char*)getVBuffer:(unsigned int)lineNum;

/**
 * @brief Get the V stride of this data.
 * @return If the function succeeds, it will return the V stride of this data.
 */
- (unsigned int)getYStride;

/**
 * @brief Get the U stride of this data.
 * @return If the function succeeds, it will return the U stride of this data.
 */
- (unsigned int)getUStride;

/**
 * @brief Get the V stride of this data.
 * @return If the function succeeds, it will return the V stride of this data.
 */
- (unsigned int)getVStride;

/**
 * @brief Get the rotation of this data.
 * @return If the function succeeds, it will return the rotation of this data.
 */
- (unsigned int)getRotation;

/**
 * @brief Get if this data is limited I420.
 * @return If it is limited I420, it will return YES. Otherwise NO.
 */
- (BOOL)isLimitedI420;
@end

@interface ZoomSDKVideoCapabilityItem : NSObject
/**
 * @brief Get the width of this data.
 * @return If the function succeeds, it will return the width of this data.
 */
- (unsigned int)getWidth;

/**
 * @brief Get the height of this data.
 * @return If the function succeeds, it will return the height of this data.
 */
- (unsigned int)getHeight;

/**
 * @brief Get the frame of this data.
 * @return If the function succeeds, it will return the frame of this data.
 */
- (unsigned int)getFrame;
@end


@interface ZoomSDKRawDataSender : NSObject
/**
 * @brief Send raw data in meeting.
 * @param data The data to send.
 * @param width The width of the data to send.
 * @param height The height of the data to send.
 * @param length The length of the data to send.
 * @param ratation The ratation of the data to send.
 */
- (void)sendRawData:(char*)data width:(unsigned int)width height:(unsigned int)height dataLength:(unsigned int)length ratation:(ZoomSDKLocalVideoDeviceRotation)ratation;
@end


@protocol ZoomSDKVirtualVideoSourceDelegate <NSObject>
- (void)onInitialize:(ZoomSDKRawDataSender*)sender supportedCapabilityList:(NSArray*)capabilityList suggestCapability:(ZoomSDKVideoCapabilityItem*)suggestCap;
- (void)onPropertyChange:(NSArray*)supportedCapabilityList suggestCapability:(ZoomSDKVideoCapabilityItem*)suggestCap;
- (void)onStartSend;
- (void)onStopSend;
- (void)onUninitialize;
@end


@protocol ZoomSDKRawDataSendDelegate <NSObject>
- (void)onPreProcessRawData:(ZoomSDKYUVProcessDataI420*)data;
@end

@interface ZoomSDKRawDataVideoSourceController : NSObject
/**
 * @brief Register the delegate of raw data preprocessor.
 * @param delegate The delegate to receive callback.
 * @return If the function succeeds, it will return ZoomSDKError_Success.
 */
- (ZoomSDKError)registerRawDataPreProcessor:(id<ZoomSDKRawDataSendDelegate>)delegate;

/**
 * @brief unRegister the delegate of raw data preprocessor.
 * @param delegate The delegate to receive callback.
 * @return If the function succeeds, it will return ZoomSDKError_Success.
 */
- (ZoomSDKError)unRegisterRawDataPreProcessor:(id<ZoomSDKRawDataSendDelegate>)delegate;

/**
 * @brief Set the delegate of virtual video source.
 * @param videoSource The delegate to receive callback.
 * @return If the function succeeds, it will return ZoomSDKError_Success.
 */
- (ZoomSDKError)setExternalVideoSource:(id <ZoomSDKVirtualVideoSourceDelegate>)videoSource;
@end
