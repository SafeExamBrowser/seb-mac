//
//  ExamLockIndicator.m
//  Safe Exam Browser
//

#import "ExamLockIndicator.h"
#import <Carbon/Carbon.h>

// Key codes (ANSI layout) of the shortcut and of the keys blocked while locked
static const unsigned short ExamKeyL = 37;
static const unsigned short ExamKeyTab = 48;
static const unsigned short ExamKeyBacktick = 50;
static const unsigned short ExamKeyH = 4;
static const unsigned short ExamKeyM = 46;
static const unsigned short ExamKeyLeftBracket = 33;
static const unsigned short ExamKeyRightBracket = 30;
static const unsigned short ExamKeyLeftArrow = 123;
static const unsigned short ExamKeyRightArrow = 124;


@interface ExamLockIndicator ()
{
    EventHotKeyRef _hotKeyRef;
    EventHandlerRef _hotKeyHandlerRef;
}
@property (weak) id<ExamLockDelegate> delegate;
@property (strong) NSPanel *panel;
@property (strong) NSImageView *iconView;
@property (strong) NSTextField *fallbackLabel;
@property (strong) NSTimer *hideTimer;
@property (strong) id keyMonitor;
@property (readwrite) BOOL globalShortcutRegistered;
@end


static OSStatus ExamLockHotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData)
{
    ExamLockIndicator *indicator = (__bridge ExamLockIndicator *)userData;
    dispatch_async(dispatch_get_main_queue(), ^{
        [indicator.delegate examLockShortcutPressed];
    });
    return noErr;
}


@implementation ExamLockIndicator

- (instancetype)initWithDelegate:(id<ExamLockDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}


- (void)start
{
    if (self.panel) {
        return;
    }
    [self createPanel];
    [self registerGlobalShortcut];
    [self installKeyMonitor];
}


#pragma mark - Icon

static const CGFloat ExamIconPanelSize = 30;
static const NSTimeInterval ExamIconVisibleSeconds = 1.0;

- (void)createPanel
{
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, ExamIconPanelSize, ExamIconPanelSize)
                                                styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = NO;
    panel.ignoresMouseEvents = YES;            // clicks go to whatever is below
    panel.releasedWhenClosed = NO;
    panel.hidesOnDeactivate = NO;
    panel.level = NSPopUpMenuWindowLevel;      // above SEB's covering windows and other apps' windows
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary |
                               NSWindowCollectionBehaviorIgnoresCycle | NSWindowCollectionBehaviorFullScreenAuxiliary;
    panel.title = @"Lock state";

    NSView *content = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, ExamIconPanelSize, ExamIconPanelSize)];
    content.wantsLayer = YES;
    content.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.62].CGColor;
    content.layer.cornerRadius = 8;

    NSImageView *iconView = [[NSImageView alloc] initWithFrame:NSInsetRect(content.bounds, 5, 5)];
    iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    iconView.contentTintColor = NSColor.whiteColor;
    [content addSubview:iconView];
    self.iconView = iconView;

    // Systems older than macOS 11 have no symbol icons: they get a short word instead
    NSTextField *fallbackLabel = [NSTextField labelWithString:@""];
    fallbackLabel.font = [NSFont systemFontOfSize:9 weight:NSFontWeightSemibold];
    fallbackLabel.textColor = NSColor.whiteColor;
    fallbackLabel.alignment = NSTextAlignmentCenter;
    fallbackLabel.frame = NSMakeRect(0, 8, ExamIconPanelSize, 12);
    fallbackLabel.hidden = YES;
    [content addSubview:fallbackLabel];
    self.fallbackLabel = fallbackLabel;

    panel.contentView = content;
    panel.alphaValue = 0;
    self.panel = panel;
}


- (void)setLocked:(BOOL)locked
{
    BOOL changed = (_locked != locked);
    _locked = locked;
    if (changed) {
        [self flashIcon];
    }
}


// Shows a lock (closed) or an open lock for about a second at the top left, then fades it away
- (void)flashIcon
{
    if (!self.panel) {
        return;
    }
    NSString *description = self.locked ? @"Exam browser locked" : @"Exam browser unlocked";
    if (@available(macOS 11.0, *)) {
        NSImage *image = [NSImage imageWithSystemSymbolName:(self.locked ? @"lock.fill" : @"lock.open.fill")
                                    accessibilityDescription:description];
        self.iconView.image = image;
        self.iconView.contentTintColor = self.locked ? [NSColor colorWithRed:1.0 green:0.58 blue:0.52 alpha:1] : NSColor.whiteColor;
        self.iconView.hidden = NO;
        self.fallbackLabel.hidden = YES;
    } else {
        self.iconView.hidden = YES;
        self.fallbackLabel.stringValue = self.locked ? @"Locked" : @"Open";
        self.fallbackLabel.hidden = NO;
    }
    [self.iconView setAccessibilityLabel:description];

    [self.hideTimer invalidate];
    [self reposition];
    [self.panel orderFrontRegardless];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.12;
        self.panel.animator.alphaValue = 1;
    } completionHandler:nil];

    __weak typeof(self) weakSelf = self;
    self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:ExamIconVisibleSeconds repeats:NO block:^(NSTimer *timer) {
        [weakSelf hideIcon];
    }];

    // VoiceOver users hear the new state, as the icon is only visible for a moment
    NSAccessibilityPostNotificationWithUserInfo(NSApp, NSAccessibilityAnnouncementRequestedNotification,
                                                @{NSAccessibilityAnnouncementKey: description,
                                                  NSAccessibilityPriorityKey: @(NSAccessibilityPriorityHigh)});
}


- (void)hideIcon
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        self.panel.animator.alphaValue = 0;
    } completionHandler:^{
        // A new flash may have started during the fade
        if (self.panel.alphaValue == 0) {
            [self.panel orderOut:nil];
        }
    }];
}


// Top left corner of the screen. SEB hides the menu bar while it is the active app; when another
// app is active its menu bar shows, and the icon sits just below it instead.
- (void)reposition
{
    NSScreen *screen = NSScreen.screens.firstObject ?: NSScreen.mainScreen;
    if (!screen || !self.panel) {
        return;
    }
    CGFloat menuBarHeight = NSApp.isActive ? 0 : NSMaxY(screen.frame) - NSMaxY(screen.visibleFrame);
    NSSize size = self.panel.frame.size;
    [self.panel setFrameOrigin:NSMakePoint(NSMinX(screen.frame) + 8, NSMaxY(screen.frame) - menuBarHeight - size.height - 6)];
}


#pragma mark - Shortcut

- (void)registerGlobalShortcut
{
    EventTypeSpec eventType = {kEventClassKeyboard, kEventHotKeyPressed};
    OSStatus status = InstallApplicationEventHandler(&ExamLockHotKeyHandler, 1, &eventType, (__bridge void *)self, &_hotKeyHandlerRef);
    if (status == noErr) {
        EventHotKeyID hotKeyID = {'EXBL', 1};
        status = RegisterEventHotKey(ExamKeyL, cmdKey | shiftKey, hotKeyID, GetApplicationEventTarget(), 0, &_hotKeyRef);
    }
    self.globalShortcutRegistered = (status == noErr);
}


- (void)installKeyMonitor
{
    __weak typeof(self) weakSelf = self;
    self.keyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return event;
        }
        NSEventModifierFlags flags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask & ~(NSEventModifierFlagCapsLock | NSEventModifierFlagNumericPad | NSEventModifierFlagFunction);
        unsigned short key = event.keyCode;

        // Fallback when the global shortcut could not be registered
#ifdef DEBUG
        if (key == ExamKeyL) { NSLog(@"ExamLockTest: keyDown L flags=%lx registered=%d", (unsigned long)flags, strongSelf.globalShortcutRegistered); }
#endif
        if (key == ExamKeyL && flags == (NSEventModifierFlagCommand | NSEventModifierFlagShift) && !strongSelf.globalShortcutRegistered) {
            [strongSelf.delegate examLockShortcutPressed];
            return nil;
        }
        if (strongSelf.locked && [strongSelf isSwitchingKey:key flags:flags]) {
#ifdef DEBUG
            NSLog(@"ExamLockTest: blocked key %d flags=%lx", key, (unsigned long)flags);
#endif
            return nil;
        }
        return event;
    }];
}


// Keys that move between browser tabs and windows or take the app out of the way.
// Copy, paste, cut, select all, undo, find, typing and Cmd+Q are not among them.
- (BOOL)isSwitchingKey:(unsigned short)key flags:(NSEventModifierFlags)flags
{
    NSEventModifierFlags cmd = NSEventModifierFlagCommand;
    NSEventModifierFlags shift = NSEventModifierFlagShift;
    NSEventModifierFlags ctrl = NSEventModifierFlagControl;
    NSEventModifierFlags opt = NSEventModifierFlagOption;

    if (key == ExamKeyTab && (flags == ctrl || flags == (ctrl | shift))) return YES;              // next / previous tab
    if ((key == ExamKeyLeftBracket || key == ExamKeyRightBracket) && flags == (cmd | shift)) return YES;
    if ((key == ExamKeyLeftArrow || key == ExamKeyRightArrow) && flags == (cmd | opt)) return YES;
    if (key == ExamKeyBacktick && (flags == cmd || flags == (cmd | shift))) return YES;            // next window
    if (key == ExamKeyH && (flags == cmd || flags == (cmd | opt))) return YES;                     // hide
    if (key == ExamKeyM && (flags == cmd || flags == (cmd | opt))) return YES;                     // minimize
    // Cmd+1 ... Cmd+9: jump to tab number
    static const unsigned short digitKeys[] = {18, 19, 20, 21, 23, 22, 26, 28, 25};
    if (flags == cmd) {
        for (size_t i = 0; i < sizeof(digitKeys) / sizeof(digitKeys[0]); i++) {
            if (key == digitKeys[i]) return YES;
        }
    }
    return NO;
}

@end
