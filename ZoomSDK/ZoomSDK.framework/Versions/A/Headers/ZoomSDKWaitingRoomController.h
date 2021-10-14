

@class ZoomSDKUserInfo;

@protocol ZoomSDKWaitingRoomDelegate <NSObject>
/**
 * @brief Callback of that user joins waiting room.
 * @param userid The ID of user who joins waiting room.
 */
-(void)onUserJoinWaitingRoom:(unsigned int)userid;
/**
 * @brief Callback of that user leaves waiting room.
 * @param userid The ID of user who leaves waiting room.
 */
-(void)onUserLeftWaitingRoom:(unsigned int)userid;
@end

@interface ZoomSDKWaitingRoomController : NSObject
{
    id<ZoomSDKWaitingRoomDelegate> _delegate;
}
@property (assign, nonatomic) id<ZoomSDKWaitingRoomDelegate> delegate;
/**
 * @brief Query if the meeting supports waiting room.
 * @return YES means supported, otherwise not.
 */
- (BOOL)isSupportWaitingRoom;
/**
 * @brief Query if waiting room is enabled in current meeting.
 * @return YES means enabled, otherwise not.	
 */
- (BOOL)isEnableWaitingRoomOnEntry;
/**
 * @brief Set to enable/disable waiting room.
 * @param enable YES means enabled, NO disabled.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)enableWaitingRoomOnEntry:(BOOL)enable;
/**
 * @brief Get the list of users in the waiting room.
 * @return If the function succeeds, it will return a NSArray.
 */
- (NSArray*)getWaitRoomUserList;
/** 
 * @brief Get the information of users in the waiting room.
 * @param userid The ID of user who is in the waiting room.
 * @return If the function succeeds, it will return the object of ZoomSDKUserInfo for the specified user.
 */
- (ZoomSDKUserInfo*)getWaitingRoomUserInfo:(unsigned int)userid;
/**
 * @brief Admit user to join meeting.
 * @param userid The ID of user who joins meeting.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)admitToMeeting:(unsigned int)userid;
/**
 * @brief Put user into waiting room.
 * @param userid The ID of user who is put into waiting room by host/co-host.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)putIntoWaitingRoom:(unsigned int)userid;
@end
