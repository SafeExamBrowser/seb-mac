

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"


@interface ZoomSDKAnswerInfo :NSObject
/**
 @brief Get the answer ID.
 @return If the function succeeds, the return value is the ID of the current answer.
 */
-(NSString*)getAnswerID;

/**
 @brief Get the question answer is send myself.
 @return If return Yes means the answer is send by self.
 */
-(BOOL)isSenderMyself;

/**
 @brief Get the timestamps of the current answer
 @return If the function succeeds, the return value is the timestamps of the current answer.
 */
-(time_t)getTimeStamp;

/**
 @brief Get the answer content.
 @return If the function succeeds, the return value is the content of the current answer.
 */
-(NSString*)getAnswerContent;

/**
 @brief Get the senderName of the send answer.
 @return If the function succeeds, the return value is the name of the person answering the question.
 */
-(NSString*)getSendName;

/**
 @brief Get the question ID.
 @return If the function succeeds, the return value is the questionID.
 */
-(NSString*)getQuestionId;

/**
 @brief Get the answer is private.
 @return If return Yes means the answer is private.
 */
-(BOOL)isPrivate;

/**
 @brief Get the answer is live.
 @return If return Yes means the answer is live.
 */
-(BOOL)isLiveAnswer;
@end


@interface ZoomSDKQuestionInfo : NSObject

/**
 @brief Get the question ID.
 @return If the function succeeds, the return value is the ID of the current question.
 */
-(NSString*)getQuestionId;
/**
 @brief Get the question is send by self.
 @return If return Yes means the question is send by self..
 */
-(BOOL)isSenderMyself;

/**
 @brief Get the timestamps of the current question.
 @return If the function succeeds, the return value is the timestamps of the current question.
 */
-(time_t )getTimeStamp;

/**
 @brief Get the question content.
 @return If the function succeeds, the return value is the content of the current question.
 */
-(NSString*)getQuestionContent;

/**
 @brief Get the senderName of the send question.
 @return If the function succeeds, the return value is the name of the person send the question.
 */
-(NSString*)getSendName;

/**
 @brief Get the question is anonymous.
 @return If return YES means the question is anonymous,otherwise not.
 */
-(BOOL)isAnonymous;

/**
 @brief Get the question is marked as answer.
 @return If return YES means the question is marked as answer,otherwise not.
 */
-(BOOL)isMarkedAsAnswered;

/**
 @brief Get the question is marked as dismissed.
 @return If return YES means the question is marked as dismissed,otherwise not.
 */
-(BOOL)isMarkedAsDismissed;

/**
 @brief Get the question vote number.
 @return  Value is the question vote number.
 */
-(int)upVoteNum;

/**
 @brief Get the question has live answer.
 @return If return YES means the question has live answer,otherwise not.
 */
-(BOOL)hasLiveAnswers;

/**
 @brief Get the question has text answer.
 @return If return YES means the question has text answer,otherwise not.
 */
-(BOOL)hasTextAnswers;

/**
 @brief Get the question is myself vote.
 @return If return YES means the question is myself vote,otherwise not.
 */
-(BOOL)isMySelfUpvoted;

/**
 @brief Get the question is myself live answered.
 @return If return YES means the question is myself live answered,otherwise not.
 */
-(BOOL)amILiveAnswering;

/**
 @brief Get the question answer list.
 @return If the function succeeds, the return value is the answer list of question.
 */
-(NSArray*)getAnswerList;

/**
 @brief Get the person name of live answered question.
 @return If the function succeeds, the return value is the name of the person live answered the question.
 */
-(NSString*)getLiveAnswerName;

/**
 @brief Get the queestion is answered living.
 @return If return Yes means the answer is living.
 */
-(BOOL)isLiveAnswering;
@end

@protocol ZoomSDKQAControllerDelegate <NSObject>

/**
 @brief This callback will return the connect status.
 @param status The Q&A connect status.
 */
-(void)onQAConnectStatus:(ZoomSDKQAConnectStatus)status;

/**
 @brief If add question will receive the callback.
 @param questionID The unique ID of question.
 @param success If the success is YES means add question is success,otherwise not.
 */
-(void)onAddQuestion:(NSString *)questionID  isSuccess:(BOOL)success;

/**
 @brief If add answer will receive the callback.
 @param answerID The unique ID of answer.
 @param success If the success is YES means add answer is success,otherwise not.
 */
-(void)onAddAnswer:(NSString *)answerID  isSuccess:(BOOL)success;

/**
 @brief If the question marked as dismiss will receive the callback.
 @param questionID The unique ID of the question marked as dismissed.
 */
-(void)onQuestionMarkedAsDismissed:(NSString*)questionID;

/**
 @brief If reopen question will receive the callback.
 @param questionID The reopen question ID.
 */
-(void)onReopenQuestion:(NSString*)questionID;

/**
 @brief If receive question will receive the callback.
 @param questionID The receive question ID.
 */
-(void)onReceiveQuestion:(NSString*)questionID;

/**
 @brief If receive answer will receive the callback.
 @param answerID The receive answer ID.
 */
-(void)onReceiveAnswer:(NSString*)answerID;

/**
 @brief If user living reply will receive the callback.
 @param questionID The user living reply questionID.
 */
-(void)onUserLivingReply:(NSString*)questionID;

/**
 @brief If user end living will receive the callback.
 @param questionID The user end living questionID.
 */
-(void)onUserEndLiving:(NSString*)questionID;

/**
 @brief If vote queation will receive the callback.
 @param questionID The vote questionID.
 @param isChanged If YES means the question order will change,otherwise not.
 */
-(void)onVoteupQuestion:(NSString*)questionID orderChanged:(BOOL)isChanged;

/**
 @brief If revoke vote queation will receive the callback.
 @param questionID The revoke vote question ID.
 @param isChanged If YES means the question order will change,otherwise not.
 */
-(void)onRevokeVoteupQuestion:(NSString*)questionID orderChanged:(BOOL)isChanged;

/**
 @brief Notify host/cohost has changed the status of ask question anonymous.
 @param bEnabled Can ask question anonymous or not.
 */
-(void)onAllowAskQuestionAnonymousStatus:(BOOL)bEnabled;

/**
 @brief Notify host/cohost has changed the status of attendee can view all question.
 @param bEnabled Attendee can aview all question or not.
 */
-(void)onAllowAttendeeViewAllQuestionStatus:(BOOL)bEnabled;

/**
 @brief Notify host/cohost has change the status of attendee can voteup question.
 @param bEnabled Attendee can ask voteup question or not.
 */
-(void)onAllowAttendeeVoteupQuestionStatus:(BOOL)bEnabled;

/**
 @brief Notify host/cohost has change the status of attendee comment question.
 @param bEnabled attendee can comment question.
 */
-(void)onAllowAttendeeCommentQuestionStatus:(BOOL)bEnabled;

/**
 @brief Notify the question has been deleted.
 @param questions The array contain deleted question id (The question id is NSString type).
 */
-(void)onDeleteQuestions:(NSArray *)questions;

/**
 @brief Notify the answer has been deleted.
 @param answer The array contain deleted answer id (The answer id is NSString type).
 */
-(void)onDeleteAnswers:(NSArray *)answer;
@end

@interface ZoomSDKQAController : NSObject
{
    id<ZoomSDKQAControllerDelegate> _delegate;
}
@property(nonatomic,assign)id<ZoomSDKQAControllerDelegate> delegate;

/**
 @brief Q&A function is available.
 @return If return YES means Q&A is available,otherwise not.
 */
-(BOOL)isQAEnable;
/**
 @brief Get all question list.
 @return If the function succeeds, the return value is array of all question.
 */
-(NSArray*)getAllQuestionList;

/**
 @brief Get my question list.
 @return If the function succeeds, the return value is array of my question.
 */
-(NSArray*)getMyQuestionList;

/**
 @brief Get open question list.
 @return If the function succeeds, the return value is array of open question.
 */
-(NSArray*)getOpenQuestionList;

/**
 @brief Get dismissed question list.
 @return If the function succeeds, the return value is array of dismissed question.
 */
-(NSArray*)getDismissedQuestionList;

/**
 @brief Get anwered question list.
 @return If the function succeeds, the return value is array of answered question.
 */
-(NSArray*)getAnsweredQuestionList;

/**
 @brief Attendee to send question.
 @param content The question content of user send.
 @param Anonymous If YES means can anonymous send question.Otherwise not.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)addQuestionWithQuestionContent:(NSString*)content isAnonymous:(BOOL)Anonymous;

/**
 @brief Answer questions in private.
 @param questionID The answer question ID.
 @param content The answer content.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)answerQuestionPrivateWithQuestionID:(NSString*)questionID answerContent:(NSString*)content;

/**
 @brief Answer questions in public.
 @param questionID The answer question ID.
 @param content The answer content.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)answerQuestionPublicWithQuestionID:(NSString*)questionID answerContent:(NSString*)content;

/**
 @brief Dismiss question.
 @param questionID The dismiss question is;
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)dismissQuestionWithQuestionID:(NSString*)questionID;

/**
 @brief Reopen the question.
 @param questionID The reopen question is.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)reopenQuestionWithQuestionID:(NSString*)questionID;

/**
 @brief Comment the question.
 @param questionID The comment question ID.
 @param content The comment on the content.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)commentQuestionWithQuestionID:(NSString*)questionID commentContent:(NSString*)content;

/**
 @brief Vote the question.
 @param questionID The vote question ID.
 @param enable If YES means vote the question,otherwise cancel vote.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)voteupQuestionWithQuestionID:(NSString*)questionID  isEableVokeup:(BOOL)enable;

/**
 @brief Set attendee can anonnymous send question.
 @param enable If set YES means attendee can anonnymous send question,Otherwise not.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)enableAnonnymousSendQuestion:(BOOL)enable;

/**
 @brief Set attendee comment.
 @param enable If set YES means attendee can comment,Otherwise not.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)enableQAComment:(BOOL)enable;

/**
 @brief Set attendee vote.
 @param enable If set YES means attendee can vote,Otherwise not.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)enableQAVoteup:(BOOL)enable;

/**
 @brief
 @param type The enumeration of AttendeeViewQuestionType,if type is viewType_OnlyAnswered_Question,attendee only view the answered question,if type is viewType_All_Question,attendee can view all question
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)setAttendeeViewQuestionType:(AttendeeViewQuestionType)type;

/**
 @brief Get the question object.
 @param questionID The ID of question.
 @return If the function succeeds, the return value is question object.
 */
-(ZoomSDKQuestionInfo*)getQuestionByQuestionID:(NSString*)questionID;

/**
 @brief Determine if the Q&A vote is allowed by the host/co-host.
 @return If return YES means can vote,otherwise not.
 */
-(BOOL)isQAVoteupEnable;

/**
 @brief  Determine if the Q&A comment is allowed by the host/co-host.
 @return If return YES means can commeent,otherwise not.
 */
-(BOOL)isQACommentEnabled;

/**
 @brief  Determine if the ask question anonymous is allowed by the host/co-host.
 @return If return YES means can ask question anonymously,otherwise not.
 */
-(BOOL)isAllowAskQuestionAnonymously;

/**
 @brief Determine if the Q&A attendee can view all question.
 @return If return YES means attendee can view all queation,otherwise not.
 */
-(BOOL)isAttendeeCanViewAllQuestions;

/**
 @brief Get the answer object.
 @param answerID The ID of answer.
 @return If the function succeeds, the return value is answer object.
 */
-(ZoomSDKAnswerInfo *)getAnswerByAnswerID:(NSString *)answerID;

/**
 @brief Start answer question on living.
 @param questionId The ID of question.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)startLiving:(NSString *)questionId;

/**
 @brief End answer question on living.
 @param questionId The ID of question.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)endLiving:(NSString *)questionId;

/**
 @brief Get open question count.
 @return Value is the open question count.
 */
-(int)getOpenQuestionCount;

/**
 @brief Get dismiss question count.
 @return Value is the dismiss question count.
 */
-(int)getDismissedQuestionCount;

/**
 @brief Get answered question count.
 @return Value is the answered question count.
 */
-(int)getAnsweredQuestionCount;

/**
 @brief Get my question count.
 @return Value is the my question count.
 */
-(int)getMyQuestionCount;

/**
 @brief Deleted question.
 @param questionID The ID of question.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)deleteQuestion:(NSString *)questionID;

/**
 @brief Deleted answer.
 @param answerID The ID of answer.
 @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)deleteAnswer:(NSString *)answerID;

/**
 @brief Determine whether the legal notice for QA is available.
 @return true indicates the legal notice for QA is available. Otherwise false.
 */
- (BOOL)isQALegalNoticeAvailable;

/**
 @brief Get the QA legal notices prompt.
 @return If the function succeeds, it will return the QA legal notices prompt. Otherwise nil.
 */
- (NSString *)getQALegalNoticesPrompt;

/**
 @brief Get the QA legal notices explained.
 @return If the function succeeds, it will return the QA legal notices explained. Otherwise nil.
 */
- (NSString *)getQALegalNoticesExplained;
@end
