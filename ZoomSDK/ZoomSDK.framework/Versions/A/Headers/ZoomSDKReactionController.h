

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZoomSDKReactionControllerDelegate <NSObject>

/**
 * @brief Notify receive the emoji reaction.
 * @param userid The user id of the send emoji racetion.
 * @param type The send emoji racetion type.
 * @param skinTone The send emoji racetion skinstone.
 */
-(void)onEmojiReactionReceived:(unsigned int)userid reactionType:(ZoomSDKEmojiReactionType)type reactionSkinTone:(ZoomSDKEmojiReactionSkinTone)skinTone;

@end

@interface ZoomSDKReactionController : NSObject
{
    id<ZoomSDKReactionControllerDelegate> _delegate;
}
@property (assign, nonatomic) id<ZoomSDKReactionControllerDelegate> delegate;

/**
 * @brief Determine if the Reaction function is enabled.
 * @return YES means Reaction function is enable,otherwise not.
 */
-(BOOL)isEmojiReactionEnabled;

/**
 * @brief Send emoji reaction.
 * @param type The type of the emoji reaction.
 * @param skinTone The skintone of the emoji reaction
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
-(ZoomSDKError)sendEmojiReaction:(ZoomSDKEmojiReactionType)type reactionSkinTone:(ZoomSDKEmojiReactionSkinTone)skinTone;

@end

NS_ASSUME_NONNULL_END
