//
//  HUDController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 05.12.20.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "HUDController.h"

@implementation HUDController


+ (HUDPanel *) createOverlayPanelWithView:(NSView *)overlayView size:(CGSize)size
{
    CGFloat padding = 20.0;
;
    NSRect backgroundRect = NSMakeRect(0, 0, size.width+padding*2, size.height+padding*2);
    NSView *HUDBackground = [[NSView alloc] initWithFrame:backgroundRect];
    HUDBackground.wantsLayer = YES;
    HUDBackground.layer.cornerRadius = padding/2;
    HUDBackground.layer.backgroundColor = [NSColor lightGrayColor].CGColor;

    [HUDBackground addSubview:overlayView];

    HUDBackground.translatesAutoresizingMaskIntoConstraints = NO;
    
    [HUDBackground.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor constant: -padding].active = YES;
    [HUDBackground.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor constant: padding].active = YES;
    [HUDBackground.topAnchor constraintEqualToAnchor:overlayView.topAnchor constant: -padding].active = YES;
    [HUDBackground.bottomAnchor constraintEqualToAnchor:overlayView.bottomAnchor constant: padding].active = YES;

    HUDPanel *overlayPanel;
    if ([overlayView conformsToProtocol:@protocol(VQRCodeProtocol)] && [(id<VQRCodeProtocol>)overlayView isVQRCode]) {
        overlayPanel = [[QRCPanel alloc] initWithContentRect:backgroundRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    } else {
        overlayPanel = [[HUDPanel alloc] initWithContentRect:backgroundRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    }
    overlayPanel.backgroundColor = [NSColor clearColor];
    overlayPanel.opaque = NO;
    overlayPanel.alphaValue = 0.75;

    overlayPanel.contentView = HUDBackground;
    return overlayPanel;
}


- (void) showHUDProgressIndicator
{
    if (!_progressIndicatorHUD)
    {
        NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] init];
        [progressIndicator setBezeled: NO];
        [progressIndicator setStyle: NSProgressIndicatorSpinningStyle];
        [progressIndicator setControlSize: NSControlSizeRegular];
        [progressIndicator sizeToFit];
        //[progressIndicator setUsesThreadedAnimation:YES];

//        NSSize progressIndicatorSize = [progressIndicator intrinsicContentSize];
//        [progressIndicator setFrameSize:progressIndicatorSize];
        
        NSRect frameRect = NSMakeRect(0,0,200,200);
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
        HUDBackground.wantsLayer = YES;
        HUDBackground.layer.cornerRadius = 20.0;
        if (@available(macOS 10.8, *)) {
            HUDBackground.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
        }
        
        [HUDBackground addSubview:_progressIndicatorView];
        [_progressIndicatorView setFrameOrigin:NSMakePoint(0, 0)];
        
        _progressIndicatorHUD = [[HUDPanel alloc] initWithContentRect:HUDBackground.bounds styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        _progressIndicatorHUD.backgroundColor = [NSColor clearColor];
        _progressIndicatorHUD.opaque = NO;
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
    [_progressIndicatorHUD orderFront:self];
    [_progressIndicatorHUD invalidateShadow];
}


- (void) hideHUDProgressIndicator
{
    [_progressIndicatorHUD orderOut:self];
}

@end

