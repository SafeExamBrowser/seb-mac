
#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

NS_ASSUME_NONNULL_BEGIN
@interface ZoomSDKBOMeetingInfo : NSObject

/**
 *@brief Get breakout meeting id.
 *@return The breakout meeting id.
 */
-(NSString *)getBOID;

/**
 *@brief Get breakout meeting nmae.
 *@return The breakout meeting name.
 */
-(NSString *)getBOName;

/**
 *@brief Get breakout meeting user list.
 *@return If the function succeeds,will get the breakout meeting user list.
 */
-(NSArray *)getBOUserlist;
@end

@protocol ZoomSDKBOMeetingCreatorDelegate <NSObject>
@optional

/**
 *@brief Callback of breakout room create success.
 *@param boID Breakout meeting ID.
 */
-(void)onBOCreateSuccess:(NSString *)boID;

@end

@interface ZoomSDKBOMeetingCreator : NSObject

@property(nonatomic,assign)id<ZoomSDKBOMeetingCreatorDelegate>  delegate;

/**
 *@brief Creator breakout meeting.
 *@param name Breakout meeting name.
 *@return If the function succeeds,will return breakout meeting id, otherwise return nil,
 */
-(NSString *)createBOWithBOName:(NSString*)name;

/**
 *@brief Update breakout meeting information.
 *@param newName Breakout meeting new name.
 *@param ID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)updateBOName:(NSString*)newName  BOID:(NSString *)ID;

/**
 *@brief Remove breakout meeting by ID.
 *@param BOID Need remove breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)removeBO:(NSString*)BOID;

/**
 *@brief Assign user to Breakout meeting.
 *@param userID Assigned user ID.
 *@param ID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)assignUserToBO:(NSString *)userID  BOID:(NSString *)ID;

/**
 *@brief Removed user from Breakout meeting.
 *@param userID Removed user ID.
 *@param ID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)removeUserFromBO:(NSString *)userID  BOID:(NSString *)ID;

/**
 *@brief Set BO stop countdown option.
 *@param countDown The option that you want to set.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)setBOOption:(ZoomSDKBOStopCountDown)countDown;

/**
 *@brief Get BO stop countdown option.
 *@return The value is bo stop countdown.
 */
-(ZoomSDKBOStopCountDown)getBOOption;

@end

@protocol ZoomSDKBOMeetingAdminDelegate <NSObject>
@optional
/**
 *@brief Host will recieve this callback when attendee request for help.
 *@param userID The ID of user who request for help.
 */
-(void)onHelpRequestReceived:(NSString *)userID;

/**
 *@brief Callback of start breakout room fail.
 *@param errCode The reason of fail.
 */
-(void)onStartBOError:(ZoomSDKBOControllerError)errCode;

@end

@interface ZoomSDKBOMeetingAdmin : NSObject

@property(nonatomic,assign)id<ZoomSDKBOMeetingAdminDelegate>  delegate;
/**
 *@brief Start breakout meeting.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)startBO;

/**
 *@brief Stop breakout meeting
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)stopBO;

/**
 *@brief Assign user to is runing breakout meeting.
 *@param userID Assigned user ID.
 *@param ID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)assignNewUserToRunningBO:(NSString *)userID  BOID:(NSString *)ID;

/**
 *@brief Switch Assigned user to differnt Breakout meeting(BO-A to BO-B).
 *@param userID Assigned user ID.
 *@param ID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)switchAssignedUserToRunningBO:(NSString *)userID  BOID:(NSString *)ID;

/**
 *@brief  Determine if the user can start breakout room.
 *@return If return YES means can start breakout room,otherwise not.
 */
-(BOOL)canStartBO;

/**
 *@brief User request to join breakout room.
 *@param requestUserID The user id.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)joinBOByUserRequest:(NSString *)requestUserID;

/**
 *@brief Notify attendee request help result.
 *@param userID The user id of requested help.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)ignoreUserHelpRequest:(NSString *)userID;

/**
 *@brief Broadcast message.
 *@param message The broadcast context.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)broadcastMessage:(NSString *)message;

/**
 *@brief Host invite user return to main session, When BO is started and user is in BO.
 *@param userID The user id.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)inviteBOUserReturnToMainSession:(NSString *)userID;

@end

@interface ZoomSDKBOMeetingAssistant : NSObject

/**
 *@brief Join Breakout meeting by Breakout meeting ID.
 *@param ID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)joinBO:(NSString*)ID;

/**
 *@brief Leave Breakout meeting.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)leaveBO;
@end

@protocol ZoomSDKBOMeetingAttendeeDelegate <NSObject>
@optional
/**
 *@brief Notify current user the request for help result.
 *@param result It is the request for help result.
 */
-(void)onHelpRequestHandleResultReceived:(ZoomSDKRequest4HelpResult)result;

/**
 *@brief Notify the host join current breakout room.
 */
-(void)onHostJoinedThisBOMeeting;

/**
 *@brief Notify the host leave current breakout room.
 */
-(void)onHostLeaveThisBOMeeting;

@end

@interface ZoomSDKBOMeetingAttendee : NSObject

@property(nonatomic,assign)id<ZoomSDKBOMeetingAttendeeDelegate>  delegate;
/**
 *@brief Join Breakout meeting.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)joinBO;

/**
 *@brief Leave breakout meeting.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)leaveBO;

/**
 *@brief Get breakout meeting name.
 *@return If the function succeeds,will return breakout meeting name.
 */
-(NSString*)getBOName;

/**
 *@brief Request for help when user in breakout room.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)requestForHelp;

/**
 *@brief Determine if the host is in this breakout room.
 *@return YES means the host in breakout room,otherwise not.
 */
-(BOOL)isHostInThisBO;
@end

@protocol ZoomSDKBOMeetingDataHelpDelegate <NSObject>
@optional

/**
 *@brief If breakout meeting info changed,will receive the callback.
 *@param boID Breakout meeting ID.
 */
-(void)onBOMeetingInfoUpdata:(NSString *)boID;

/**
 *@brief If the unassigned user changed,will receive the callback.
 */
-(void)onUnAssignedUserUpdated;

/**
 *@brief If breakout meeting list changed,will receive the callback.
 */
-(void)onBOListInfoUpdated;
@end

@interface ZoomSDKBOMeetingDataHelp : NSObject

/**
 *@brief Sets the delegate.
 */
@property(nonatomic,assign)id<ZoomSDKBOMeetingDataHelpDelegate>  delegate;

/**
 *@brief Get unassigned user list.
 *@return If the function succeeds,will return unassigned user array.
 */
-(NSArray *)getUnassignedUserList;

/**
 *@brief Get breakout meeting ID list.
 *@return If the function succeeds,will return breakout meeting ID array.
 */
-(NSArray *)getBOMeetingIDList;

/**
 *@brief Get breakout meeting user name.
 *@param userID The user's user ID.
 *@return If the function succeeds,will return user name.
 */
-(NSString *)getBOUserNameWithUserID:(NSString *)userID;

/**
 *@brief Get breakout meeting user Status.
 *@param userID The user's user ID.
 *@return If the function succeeds,will return user status.
 */
-(ZoomSDKBOUserStatus)getBOUserStatusWithUserID:(NSString *)userID;

/**
 *@brief Get breakout meeting info.
 *@param BOID Breakout meeting ID.
 *@return If the function succeeds,will return ZoomSDKBOMeetingInfo object.
 */
-(ZoomSDKBOMeetingInfo *)getBOMeetingInfoWithBOID:(NSString *)BOID;

/**
 *@brief Determine if it is yourself by userID.
 *@param userid The user's user ID.
 *@return YES means yourself is in the breakout meeting ,otherwise not.
 */
-(BOOL)isMyselfInBo:(NSString *)userid;

/**
 *@brief Get breakout meeting name.
 *@return The name of current breakout meeting.
 */
-(NSString*)getCurrentBoName;
@end

@interface ZoomSDKBOMeetingReturnToMainSessionHandler : NSObject

/**
 *@brief Return to main session.
 *@return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)returnToMainSession;

/**
 *@brief Ignore the return invitation, after call this api, please don't use the handler unless you receive the invitation again.
 */
-(void)ignore;

@end

@protocol ZoomSDKNewBreakoutRoomControllerDelegate <NSObject>
@optional

/**
 *@brief If the creator's permissions change,will receive the callback.
 *@param creatorObject ZoomSDKBOMeetingCreator class object.
 */
-(void)onHasCreatorPermission:(ZoomSDKBOMeetingCreator *)creatorObject;

/**
 *@brief If the admin's permissions change,will receive the callback.
 *@param adminObject ZoomSDKBOMeetingAdmin class object.
 */
-(void)onHasAdminPermission:(ZoomSDKBOMeetingAdmin *)adminObject;

/**
 *@brief If the assistant's permissions change,will receive the callback.
 *@param assistantObject ZoomSDKBOMeetingAssistant class object.
 */
-(void)onHasAssistantPermission:(ZoomSDKBOMeetingAssistant *)assistantObject;

/**
 *@brief If the attendee's permissions change,will receive the callback.
 *@param attendeeObject ZoomSDKBOMeetingAttendee class object.
 */
-(void)onHasAttendeePermission:(ZoomSDKBOMeetingAttendee *)attendeeObject;

/**
 *@brief If the dataHelper's permissions change,will receive the callback.
 *@param dataHelpObject ZoomSDKBOMeetingDataHelp class object.
 */
-(void)onHasDataHelperPermission:(ZoomSDKBOMeetingDataHelp *)dataHelpObject;

/**
 *@brief If lost creator's permissions change,will receive the callback.
 */
-(void)onLostCreatorPermission;

/**
 *@brief If lost admin's permissions change,will receive the callback.
 */
-(void)onLostAdminPermission;

/**
 *@brief If lost assistant's permissions change,will receive the callback.
 */
-(void)onLostAssistantPermission;

/**
 *@brief If lost attendee's permissions change,will receive the callback.
 */
-(void)onLostAttendeePermission;

/**
 *@brief If lost dataHelper's permissions change,will receive the callback.
 */
-(void)onLostDataHelperPermission;

/**
 *@brief If host broadcast message,all attendee will revieve this callback
 *@param message The broadcast message context.
 **@param senderUserId The sender message user id.
*/
-(void)onNewBroadcastMessageReceived:(NSString *)message senderUserId:(unsigned int)userid;

/**
 *@brief If countDown != ZoomSDKBOStopCountDown_Not, host stop BO and all users receive the event.
 *@param countDown The countdown seconds.
 */
-(void)onBOStopCountDown:(ZoomSDKBOStopCountDown)countDown;

/**
 *@brief If you are in BO, host invite you return to main session, you will receive the event.
 *@param userName The host name.
 *@param handler The ZoomSDKBOMeetingReturnToMainSessionHandler class object.
 */
-(void)onHostInviteReturnToMainSession:(NSString*)userName handler:(ZoomSDKBOMeetingReturnToMainSessionHandler*)handler;

/**
 *@brief When host change the BO status, all users receive the event.
 *@param status Current status of BO.
 */
-(void)onBOControlStatusChanged:(ZoomSDKBOStatus)status;

@end

@interface ZoomSDKNewBreakoutRoomController : NSObject

@property(nonatomic,assign)id<ZoomSDKNewBreakoutRoomControllerDelegate>  delegate;

/**
 *@brief Get ZoomSDKBOMeetingCreator Class object.
 *@return If the function succeeds,will return ZoomSDKBOMeetingCreator Class object.
 @note Only host can get this object.
 */
-(ZoomSDKBOMeetingCreator *)getBOMeetingCreator;

/**
 *@brief Get ZoomSDKBOMeetingAdmin Class object.
 *@return If the function succeeds,will return ZoomSDKBOMeetingAdmin Class object.
 *@note Host in master meeting or breakout meeting can get this object.
 */
-(ZoomSDKBOMeetingAdmin *)getBOMeetingAdmin;

/**
 *@brief Get ZoomSDKBOMeetingAssistant Class object
 *@return If the function succeeds,will return ZoomSDKBOMeetingAssistant Class object.
 *@note Host in master/breakout meeting or cohost in breakmeeting can get this object.
 */
-(ZoomSDKBOMeetingAssistant *)getBOMeetingAssistant;

/**
 *@brief Get ZoomSDKBOMeetingAttendee Class object.
 *@return If the function succeeds,will return ZoomSDKBOMeetingAttendee Class object.
 *@note If you are CoHost/attendee, and are assigned to BO, you will get this object.
 */
-(ZoomSDKBOMeetingAttendee *)getBOMeetingAttendee;

/**
 *@brief Get ZoomSDKBOMeetingDataHelp Class object.
 *@return If the function succeeds,will return ZoomSDKBOMeetingDataHelp Class object.
 *@note Host in master/breakout meeting or cohost in breakmeeting can get this object.
 */
-(ZoomSDKBOMeetingDataHelp *)getBOMeetingDataHelp;

/**
 *@brief Determine if breakout meeting is start.
 *@return If the function succeeds, it will return YES, otherwise not.
 */
-(BOOL)isBOStart;

/**
 *@brief Determine if breakout meeting is enable.
 *@return If the function succeeds, it will return YES, otherwise not.
 */
-(BOOL)isBOEnable;

/**
 *@brief Determine if user is in breakout meeting.
 *@return If the function succeeds, it will return YES, otherwise not.
 */
-(BOOL)isInBOMeeting;

/**
 *@brief Get current BO status.
 *@return The value is a enum for bo status.
 */
-(ZoomSDKBOStatus)getBOStatus;
@end

NS_ASSUME_NONNULL_END
