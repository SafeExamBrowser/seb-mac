//
//  SEBDockItemWiFi.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.07.26.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBDockItemWiFi.h"
#import "SafeExamBrowser-Swift.h"

@implementation SEBDockItemWiFi

- (instancetype) init
{
    self = [super initWithTitle:nil bundleID:nil allowManualStart:NO icon:nil highlightedIcon:nil toolTip:NSLocalizedString(@"Wi-Fi", nil) menu:nil target:nil action:nil secondaryAction:nil];
    return self;
}


- (void) startDisplayingWiFi
{
    CGFloat dockHeight = [[NSUserDefaults standardUserDefaults] secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
    dockScale = dockHeight / SEBDefaultDockHeight;

    if (itemSize == 0) {
        itemSize = 32;
    }
    CGFloat scaledSize = itemSize * dockScale;

    // Create container view
    _view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, scaledSize, scaledSize)];

    // Create WiFi icon button
    wifiIconButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, scaledSize, scaledSize)];
    wifiIconButton.bezelStyle = NSBezelStyleSmallSquare;
    wifiIconButton.bordered = NO;
    wifiIconButton.imagePosition = NSImageOnly;
    wifiIconButton.imageScaling = NSImageScaleProportionallyUpOrDown;
    wifiIconButton.target = self;
    wifiIconButton.action = @selector(wifiIconClicked:);
    wifiIconButton.toolTip = NSLocalizedString(@"Wi-Fi", nil);

    // Set initial icon
    NSImage *initialIcon = [NSImage imageNamed:@"SEBWiFiIcon_off"];
    if (initialIcon) {
        initialIcon.size = NSMakeSize(scaledSize, scaledSize);
    }
    wifiIconButton.image = initialIcon;

    [_view addSubview:wifiIconButton];

    // Set up Auto Layout for the button inside the container
    wifiIconButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [wifiIconButton.leadingAnchor constraintEqualToAnchor:_view.leadingAnchor],
        [wifiIconButton.trailingAnchor constraintEqualToAnchor:_view.trailingAnchor],
        [wifiIconButton.topAnchor constraintEqualToAnchor:_view.topAnchor],
        [wifiIconButton.bottomAnchor constraintEqualToAnchor:_view.bottomAnchor],
        [wifiIconButton.widthAnchor constraintEqualToConstant:scaledSize],
        [wifiIconButton.heightAnchor constraintEqualToConstant:scaledSize]
    ]];
}


- (void) wifiIconClicked:(id)sender
{
    if ([self.wifiActionDelegate respondsToSelector:@selector(wifiButtonPressed:)]) {
        [self.wifiActionDelegate wifiButtonPressed:sender];
    }
}


#pragma mark - SEBWiFiControllerDelegate

- (void) updateWiFiSignalStrength:(NSInteger)rssi networkName:(NSString *)ssid connected:(BOOL)connected
{
    _currentSSID = ssid;
    _currentlyConnected = connected;

    NSString *iconName = [SEBWiFiController iconNameForRSSI:rssi connected:connected];
    NSImage *icon = [NSImage imageNamed:iconName];
    if (icon) {
        CGFloat scaledSize = itemSize * dockScale;
        icon.size = NSMakeSize(scaledSize, scaledSize);
    }
    wifiIconButton.image = icon;

    // Update tooltip
    NSString *toolTipString;
    if (connected && ssid) {
        toolTipString = [NSString stringWithFormat:NSLocalizedString(@"Wi-Fi: %@ (Signal: %ld dBm)", nil), ssid, (long)rssi];
    } else if (connected) {
        toolTipString = [NSString stringWithFormat:NSLocalizedString(@"Wi-Fi: Connected (Signal: %ld dBm)", nil), (long)rssi];
    } else {
        toolTipString = NSLocalizedString(@"Wi-Fi: Not Connected", nil);
    }
    [self setToolTip:toolTipString];
}


- (void) setToolTip:(NSString *)toolTip
{
    wifiIconButton.toolTip = toolTip;
}


@end
