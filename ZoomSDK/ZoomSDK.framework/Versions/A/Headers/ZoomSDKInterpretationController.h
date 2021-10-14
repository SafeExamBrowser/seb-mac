

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZoomSDKInterpretationLanguageInfo : NSObject

/**
 @brief Get language id.
 @return If the function succeeds, it will return language id.
 */
-(int)getLanguageID;

/**
 @brief Get language alisa.
 @return If the function succeeds, it will return language alisa.
 */
-(NSString*)getLanguageAbbreviations;

/**
 @brief Get language name.
 @return TIf the function succeeds, it will return language name.
 */
-(NSString*)getLanguageName;
@end

@interface ZoomSDKInterpreter : NSObject

/**
 @brief Get the user ID.
 @return If the function succeeds, it will return user ID.
 */
-(int)getUserID;

/**
 @brief Get the language id of the interpreter support.
 @return If the function succeeds, it will return language id.
 */
-(int)getLanguageID1;

/**
 @brief Get the language id of the interpreter support.
 @return If the function succeeds, it will return language id.
 */
-(int)getLanguageID2;

/**
 @brief Determine if the interpreter is available.
 @return YES means the interpreter is available and had join meeting,otherwise not.
 */
-(BOOL)isAvailable;
@end

@protocol ZoomSDKInterpretationControllerDelegate <NSObject>

/**
 @brief Notify the interpretation is started.
 */
-(void)onInterpretationStart;

/**
 @brief Notify the interpretation is stoped.
 */
-(void)onInterpretationStop;

/**
 @brief Notify the interpreter role is changed.
 @param userID The user id of the interpreter role change.
 @param interpreter YES means is interpreter,otherwise not.
 */
-(void)onInterpreterRoleChanged:(unsigned int)userID isInterpreter:(BOOL)interpreter;

/**
 @brief Notify the interpreter role is changed.
 @param userID The user id of the interpreter.
 @param languageID The current active language id.
 */
-(void)onInterpreterActiveLanuageChanged:(unsigned int)userID activeLanguageID:(int)languageID;

/**
 @brief Notify the interpreter language changed.
 @param lanID1 The language id of the first language id.
 @param lanID2 The language id of the second language id.
 */
-(void)onInterpreterLanuageChanged:(int)lanID1  theLanguageID2:(int)lanID2;

/**
 @brief Notify the available language.
 @param availableLanguageArr The array contain available language object (The language object is ZoomSDKInterpretationLanguageInfo).
 */
-(void)onAvailableLanguageListUpdated:(NSArray*)availableLanguageArr;

/**
 @brief Notify the interpreter list changed.
 */
-(void)onInterpreterListChanged;
@end

@interface ZoomSDKInterpretationController : NSObject
@property(nonatomic,assign)id<ZoomSDKInterpretationControllerDelegate>  delegate;

/**
 @brief Determine if the interpretation function is enabled.
 @return YES means interpretation function is enable,otherwise not.
 */
-(BOOL)isInterpretationEnabled;

/**
 @brief Determine if the interpretation function is started.
 @return YES means interpretation is started,otherwise not.
 */
-(BOOL)isInterpretationStarted;

/**
 @brief Determine if self is interpreter.
 @return YES means self is interpreter,otherwise not.
 */
-(BOOL)isInterpreter;

/**
 @brief Get interpretation language.
 @param languageID The id of language.
 @return If the function succeeds, the return value is ZoomSDKInterpretationLanguageInfo object.
 */
-(ZoomSDKInterpretationLanguageInfo*)getInterpretationLanguageByID:(int)languageID;

/**
 @brief Get all language list of interpretation support.
 @return If the function succeeds, the return array contain language object.(The language object is ZoomSDKInterpretationLanguageInfo)
 */
-(NSArray*)getAllLanguageList;

/**
 @brief Get all interpreter list.
 @return If the function succeeds, the return array contain interpreter object.(The language object is ZoomSDKInterpreter)
 */
-(NSArray*)getAllInterpreterList;

/**
 @brief Add interpreter.
 @param userID The unique identity of the user.
 @param lanID1 The id of language.
 @param lanID2 The id of language.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)addInterpreter:(unsigned int)userID languageID1:(int)lanID1 languageID2:(int)lanID2;

/**
 @brief Remove interpreter.
 @param userID The unique identity of the user.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)removeInterpreter:(unsigned int)userID;

/**
 @brief Modify interpreter suport language.
 @param userID The unique identity of the user.
 @param lanID1 The id of language.
 @param lanID2 The id of language.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)modifyInterpreter:(unsigned int)userID languageID1:(int)lanID1 languageID2:(int)lanID2;

/**
 @brief Start interppretation.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)startInterpretation;

/**
 @brief Stop interppretation.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)StopInterpretation;

/**
 @brief Get available language list.
 @return The array contain available language object (The language object is ZoomSDKInterpretationLanguageInfo).
 */
-(NSArray*)getAvailableLanguageList;

/**
 @brief Join language channel by language id.
 @param languageID The language id.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 @note LanguageID is -1 means join major meeting.
 */
-(ZoomSDKError)joinLanguageChannel:(int)languageID;

/**
 @brief Get the language id of user joined.
 @return If the function succeeds, it will return language id.
 */
-(int)getJoinedLanguageID;

/**
 @brief Turn off the major meeting audio.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)turnOffMajorAudio;

/**
 @brief Turn on the major meeting audio.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)turnOnMajorAudio;

/**
 @brief Determine if major audio is turn off.
 @return YES means major audio is turn off,otherwise not.
 */
-(BOOL)isMajorAudioTurnOff;

/**
 @brief Get interpreter support language.
 @param lanID1 The id is interpreter first language.
 @param lanID2 The id is interpreter second language.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)getInterpreterLans:(int*)lanID1 languageID2:(int*)lanID2;

/**
 @brief Set interpreter active language.
 @param activeLanID The id of language id.
 @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)setInterpreterActiveLan:(int)activeLanID;

/**
 @brief Get interpreter current active language id.
 @return If the function succeeds, it will return language id.
 */
-(int)getInterpreterActiveLanID;
@end

NS_ASSUME_NONNULL_END
