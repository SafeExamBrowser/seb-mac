

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

@protocol ZoomSDKCloseCaptionControllerDelegate <NSObject>
/**
 * @brief Callback of getting the privilege of close caption. 
 */
- (void)onGetCCPrvilege;

/**
 * @brief Callback of losing privilege of close caption. 
 */
- (void)onLostCCPrvilege;

/**
 * @brief Notify the current user that close caption is received.
 * @param inString The string of the close caption.
 */
- (void)onReceiveCCMessageWithString:(NSString*)inString;

/**
 * @brief Notify the current user of realtime message.
 * @param realtimeMessage The message that is being input.
 */
- (void)onReceiveCCRealtimeMessage:(NSString *)realtimeMessage;
@end

@interface ZoomSDKCloseCaptionController : NSObject
{
    id<ZoomSDKCloseCaptionControllerDelegate> _delegate;
    
}
@property(nonatomic, assign)id<ZoomSDKCloseCaptionControllerDelegate> delegate;

/**
 * @brief Query if Close Caption is supported in the current meeting.
 * @return YES means supported, otherwise not.
 */
- (BOOL)isMeetingSupportCloseCaption;

/**
 * @brief Query if it is able to assign others to send Close Caption.
 * @return YES means able, otherwise not.
 */
- (BOOL)canAssignOthersToSendCC;

/**
 * @brief Query if the specified user can be assigned to send close caption.
 * @param userID The ID of user who you want to assign to send close caption
 * @return YES means able, otherwise not.
 */
- (BOOL)canBeAssignedToSendCC:(unsigned int)userID;

/**
 * @brief Query if the current user can send Close Caption.
 * @return YES means able, otherwise not.
 */
- (BOOL)canSendClosedCaption;

/**
 * @brief Query if user can save Close Caption.
 * @return YES means able, otherwise not.
 */
- (BOOL)isCanSaveClosedCaption;

/**
 * @brief Query if the third party close caption server is available.
 * @return YES means available, otherwise not.
 */
- (BOOL)is3rdPartCCServerAvailable;

/**
 * @brief This method is used for host to withdraw CC privilege from another user.
 * @param userId The ID of user that you want to withdraw CC privilege.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)withdrawCCPriviledgeForUser:(unsigned int)userID;

/**
 * @brief This method is used for host to assign CC privilege to another user.
 * @param userId The ID of user whom you want to assign CC privilege to.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)assignCCPriviledgeTo:(unsigned int)userID;

/**
 * @brief Send CC message.
 * @param ccString The content of CC.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)sendClosedCaptionMessage:(NSString*)ccString;

/**
 * @brief Save CC.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)saveCCHistory;

/**
 * @brief Get the path where the CC is saved.
 * @return If the function succeeds, it will return a NSString. Otherwise failed.
 */
- (NSString*)getClosedCaptionHistorySavedPath;

/**
 * @brief Get the third party URL which is used to input CC.
 * @param thirdPartyURL The URL of the third party service.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)getClosedCaptionUrlFor3rdParty:(NSString**)thirdPartyURL;

/**
 @brief Determine whether the legal notice for Live transcript is available.
 @return true indicates the legal notice for Live transcript is available. Otherwise false.
 */
- (BOOL)isLiveTranscriptLegalNoticeAvailable;

/**
 @brief Get the CC legal notices prompt.
 @return If the function succeeds, it will return the CC legal notices prompt. Otherwise nil.
 */
- (NSString *)getLiveTranscriptLegalNoticesPrompt;

/**
 @brief Get the CC legal notices explained.
 @return If the function succeeds, it will return the CC legal notices explained. Otherwise nil.
 */
- (NSString *)getLiveTranscriptLegalNoticesExplained;
@end
