//
//  ExamLockIndicator.h
//  Safe Exam Browser
//
//  The Cmd+Shift+L lock: a small lock icon that shows in the top left corner of the screen for about
//  a second when the lock changes (closed lock = locked, open lock = unlocked), the shortcut that
//  toggles the lock (works from any app), and, while locked, blocking of the keys that switch
//  between browser tabs and windows. Copy and paste keep working.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ExamLockDelegate <NSObject>
/// Cmd+Shift+L was pressed
- (void)examLockShortcutPressed;
@end


@interface ExamLockIndicator : NSObject

- (instancetype)initWithDelegate:(id<ExamLockDelegate>)delegate;

/// Starts listening for the shortcut
- (void)start;

/// Changing it flashes the icon and switches the key blocking
@property (nonatomic) BOOL locked;

/// True if the global shortcut could be registered (otherwise only the in-app one works)
@property (readonly) BOOL globalShortcutRegistered;

@end

NS_ASSUME_NONNULL_END
