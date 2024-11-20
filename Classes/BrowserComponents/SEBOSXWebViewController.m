//
//  SEBOSXWebViewController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 09.08.21.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBOSXWebViewController.h"


@implementation SEBOSXWebViewController


- (instancetype)initNewTabMainWebView:(BOOL)mainWebView
                       withCommonHost:(BOOL)commonHostTab
                        configuration:(WKWebViewConfiguration *)configuration
                   overrideSpellCheck:(BOOL)overrideSpellCheck
                             delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    if (self) {
        SEBAbstractWebView *sebAbstractWebView = [[SEBAbstractWebView alloc] initNewTabMainWebView:mainWebView withCommonHost:commonHostTab configuration:configuration overrideSpellCheck:(BOOL)overrideSpellCheck delegate:delegate];
        _sebAbstractWebView = sebAbstractWebView;
        firstAppearance = YES;
    }
    return self;
}


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

- (void)loadView
{
    self.view = _sebAbstractWebView.nativeWebView;
}

- (void) viewDidLoad
{
    [_sebAbstractWebView viewDidLoad];
    
    [super viewDidLoad];
}

- (void)viewWillAppear
{
    [_sebAbstractWebView viewWillAppear];
    
    [super viewWillAppear];
}

- (void)viewDidAppear
{
    [_sebAbstractWebView viewDidAppear];
    Class webViewClass = [_sebAbstractWebView.nativeWebView superclass];
    if (firstAppearance &&
        webViewClass != WKWebView.class &&
        ![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowWebViewClassicHideDeprecationNote"]) {
        firstAppearance = NO;
        [self showTopOverlayMessage:[NSString stringWithFormat:NSLocalizedString(@"Classic WebView is deprecated and no longer fully supported by iOS! The used %@ assessment system integration/settings need to be updated to support the modern WebView.", @""), SEBShortAppName]];
    }
    
    [super viewDidAppear];
}

- (void)viewDidLayout
{
    [_sebAbstractWebView viewDidLayout];
    
    [super viewDidLayout];
}

- (void)viewWillDisappear
{
    [_sebAbstractWebView viewWillDisappear];
    
    [super viewWillDisappear];
}

- (void)viewWDidDisappear
{
    [_sebAbstractWebView viewDidDisappear];
    
    [super viewDidDisappear];
}


#pragma mark Overlay Messages

- (void) showTopOverlayMessage:(NSString *)text
{
    if (!_topOverlayMessageView) {
        
        NSRect frameRect = NSMakeRect(0,0,155,21); // This will change based on the size you need
        NSTextField *message = [[NSTextField alloc] initWithFrame:frameRect];
        message.stringValue = text;
        message.bezeled = NO;
        message.editable = NO;
        message.drawsBackground = NO;

        NSSize messageLabelSize = [message intrinsicContentSize];
//        [message setAlignment:NSTextAlignmentCenter];
        CGFloat messageLabelWidth = messageLabelSize.width + 2;
        CGFloat messageLabelHeight = messageLabelSize.height;
        [message setFrameSize:NSMakeSize(messageLabelWidth, messageLabelHeight)];
        
        _topOverlayMessageView = [self overlayViewForLabelConstraints:message];
    }
    
    NSView *nativeWebView = (NSView *)[_sebAbstractWebView nativeWebView];
    _topOverlayMessageView.translatesAutoresizingMaskIntoConstraints = NO;
    [nativeWebView addSubview:_topOverlayMessageView positioned:NSWindowAbove relativeTo:nativeWebView];
    
    if (@available(macOS 11.0, *)) {
        [_topOverlayMessageView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10].active = YES;
//        [_topOverlayMessageView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10].active = YES;
        [_topOverlayMessageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10].active = YES;
    } else {
        // Fallback on earlier versions
    }
}


- (void) closeOverlayMessage
{
    [_topOverlayMessageView removeFromSuperview];
}


- (NSView *) overlayViewForLabelConstraints:(NSTextField *)message {
    [message sizeToFit];
    
    message.maximumNumberOfLines = 0;
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize messageLabelSize = message.frame.size;
//    CGFloat messageLabelWidth = messageLabelSize.width + messageLabelSize.height;
    CGFloat messageLabelHeight = messageLabelSize.height * 1.5;
    
    NSView *overlayView = [NSView new];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
//    message.centerXAnchor = overlayView.centerXAnchor;
    
    overlayView.wantsLayer = YES;
    overlayView.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    overlayView.layer.opacity = 0.75;
    
    overlayViewCloseButton = [NSButton buttonWithImage:[NSImage imageNamed:@"Cancel"] target:self action:@selector(closeOverlayMessage)];
    id target = overlayViewCloseButton.target;
    DDLogDebug(@"Overlay view close button target: %@", target);
    [overlayViewCloseButton setBezelStyle:NSBezelStyleCircular];
    overlayViewCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayViewCloseButton setAccessibilityLabel:NSLocalizedString(@"Close Warning", @"")];

//    NSStackView *closeButtonStackView = [NSStackView new];
//    closeButtonStackView.orientation = NSUserInterfaceLayoutOrientationVertical;
//    closeButtonStackView.distribution = NSStackViewDistributionFill;
//    closeButtonStackView.translatesAutoresizingMaskIntoConstraints = NO;
//    [closeButtonStackView addArrangedSubview:overlayViewCloseButton];
//    [closeButtonStackView addArrangedSubview:[NSView new]];

    NSStackView *overlayStackView = [NSStackView new];
    overlayStackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    overlayStackView.spacing = 10;
    overlayStackView.distribution = NSStackViewDistributionFill;
    overlayStackView.translatesAutoresizingMaskIntoConstraints = NO;
//    [overlayStackView addArrangedSubview:closeButtonStackView];
    [overlayStackView addArrangedSubview:overlayViewCloseButton];
    [overlayStackView addArrangedSubview:message];
//    [overlayViewCloseButton.widthAnchor constraintEqualToConstant:overlayViewCloseButton.image.size.width].active = YES;
//    [closeButtonStackView.leadingAnchor constraintEqualToAnchor:overlayStackView.leadingAnchor].active = YES;
//    [closeButtonStackView.trailingAnchor constraintEqualToAnchor:overlayStackView.trailingAnchor].active = YES;
//    [closeButtonStackView.topAnchor constraintEqualToAnchor:overlayStackView.topAnchor].active = YES;
//    [closeButtonStackView.bottomAnchor constraintEqualToAnchor:overlayStackView.bottomAnchor].active = YES;

    [overlayView addSubview:overlayStackView];
    [overlayStackView.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor constant: 15].active = YES;
    [overlayStackView.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor constant: -15].active = YES;
    [overlayStackView.topAnchor constraintEqualToAnchor:overlayView.topAnchor constant: 7].active = YES;
    [overlayStackView.bottomAnchor constraintEqualToAnchor:overlayView.bottomAnchor constant: -7].active = YES;

    overlayView.layer.cornerRadius = messageLabelHeight / 2;
    overlayView.clipsToBounds = YES;
    [overlayViewCloseButton setNextResponder:overlayView];
    return overlayView;
}



@end
