//
//  HUDController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 05.12.20.
//

#import "HUDController.h"
#import "HUDPanel.h"

@implementation HUDController

- (void) showHUDProgressIndicator
{
    if (!_progressIndicatorHUD)
    {
        NSRect frameRect = NSMakeRect(0,0,200,200); // This will change based on the size you need
        NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] init];
        [progressIndicator setBezeled: NO];
        [progressIndicator setStyle: NSProgressIndicatorSpinningStyle];
        [progressIndicator setControlSize: NSControlSizeRegular];
        [progressIndicator sizeToFit];
        //[progressIndicator setUsesThreadedAnimation:YES];

//        NSSize progressIndicatorSize = [progressIndicator intrinsicContentSize];
//        [progressIndicator setFrameSize:progressIndicatorSize];
        
        _progressIndicatorView = [[NSView alloc] initWithFrame:frameRect];
        [_progressIndicatorView addSubview:progressIndicator];
        
        [progressIndicator setFrame:NSMakeRect(
                                     
                                     0.5 * (_progressIndicatorView.frame.size.width - progressIndicator.frame.size.width),
                                     (0.5 * (_progressIndicatorView.frame.size.height - progressIndicator.frame.size.height)) ,
                                     
                                                    progressIndicator.frame.size.width,
                                                    progressIndicator.frame.size.height
                                     
                                     )];
        
        [progressIndicator setNextResponder:_progressIndicatorView];
        
        NSRect progressIndicatorRect = _progressIndicatorView.frame;
        NSRect backgroundRect = NSMakeRect(0, 0, progressIndicatorRect.size.width, progressIndicatorRect.size.height);
        NSView *HUDBackground = [[NSView alloc] initWithFrame:backgroundRect];
        HUDBackground.wantsLayer = true;
        HUDBackground.layer.cornerRadius = 20.0;
        if (@available(macOS 10.8, *)) {
            HUDBackground.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
        }
        
        [HUDBackground addSubview:_progressIndicatorView];
        [_progressIndicatorView setFrameOrigin:NSMakePoint(0, 0)];
        
        _progressIndicatorHUD = [[HUDPanel alloc] initWithContentRect:HUDBackground.bounds styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:false];
        _progressIndicatorHUD.backgroundColor = [NSColor clearColor];
        _progressIndicatorHUD.opaque = false;
        _progressIndicatorHUD.alphaValue = 0.75;

        _progressIndicatorHUD.contentView = HUDBackground;
    }
//    NSArray *screens = [NSScreen screens];
//    NSScreen *mainScreen = screens[0];
//    NSRect visibleScreenRect = mainScreen.visibleFrame;
//    NSPoint topLeftPoint;
//    topLeftPoint.x = visibleScreenRect.origin.x + visibleScreenRect.size.width - _progressIndicatorHUD.frame.size.width;
//    topLeftPoint.y = visibleScreenRect.origin.y + visibleScreenRect.size.height - 3;
//    [_progressIndicatorHUD setFrameTopLeftPoint:topLeftPoint];
    [_progressIndicatorHUD center];
    
    _progressIndicatorHUD.becomesKeyOnlyIfNeeded = YES;
    [_progressIndicatorHUD setLevel:NSModalPanelWindowLevel];
    [_progressIndicatorHUD makeKeyAndOrderFront:nil];
    [_progressIndicatorHUD invalidateShadow];
}


- (void) hideHUDProgressIndicator
{
    [_progressIndicatorHUD orderOut:self];
}

@end
