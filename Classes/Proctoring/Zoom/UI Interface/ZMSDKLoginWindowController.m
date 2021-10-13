        //
//  ZMSDKLoginWindowController.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/15.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKLoginWindowController.h"
#import "ZMSDKMainWindowController.h"
#import "ZMSDKAuthHelper.h"
#import "ZMSDKInitHelper.h"
#import "ZMSDKRestAPILogin.h"
#import "ZMSDKSSOLogin.h"
#import "ZMSDKJoinOnly.h"
#import "ZMSDKCommonHelper.h"
#import "ZMSDKEmailLogin.h"

#define kZoomSDKDomain      @""


@interface ZMSDKLoginWindowController ()

@end

@implementation ZMSDKLoginWindowController
- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(void)awakeFromNib
{
    [self initUI];
}
- (id)init
{
    self = [super initWithWindowNibName:@"ZMSDKLoginWindowController" owner:self];
    if(self)
    {
        return self;
    }
    return nil;
}
- (void)initHelper
{
    _authHelper = [[ZMSDKAuthHelper alloc] initWithWindowController:self];
    _restAPIHelper = [[ZMSDKRestAPILogin alloc] initWithWindowController:self];
    _emailLoginHelper = [[ZMSDKEmailLogin alloc] initWithWindowController:self];
    _ssoLoginHelper = [[ZMSDKSSOLogin alloc] initWithWindowController:self];
    _joinOnlyHelper = [[ZMSDKJoinOnly alloc] initWithWindowController:self];
}

- (void)cleanUp
{
    if (_mainWindowController)
    {
        [_mainWindowController cleanUp];
        _mainWindowController = nil;
    }
    if(_authHelper)
    {
        _authHelper = nil;
    }
    if (_restAPIHelper) {
        _restAPIHelper = nil;
    }
    if(_ssoLoginHelper)
    {
        _ssoLoginHelper = nil;
    }
    if(_joinOnlyHelper)
    {
        _joinOnlyHelper = nil;
    }
    if(_emailLoginHelper)
    {
        _emailLoginHelper = nil;
    }
    [self close];
}
-(void)dealloc
{
    [self cleanUp];
}
- (void)initUI
{
    [_loadingProgressIndicator stopAnimation:self];
}
- (void)showSelf
{
    [self relayoutWindowPosition];
    [self.window makeKeyAndOrderFront:nil];
}
- (void)relayoutWindowPosition
{
    [self.window setLevel:NSPopUpMenuWindowLevel];
    [self.window center];
}
- (IBAction)onSetDomainClicked:(id)sender
{
    BOOL useCustomizedUI = NO;
    if(_setUseCustomizedUIButton.state == NSOnState)
        useCustomizedUI = YES;
    [ZMSDKInitHelper initSDK:useCustomizedUI];
    [self initHelper];
    //[ZMSDKInitHelper setDomain:kZoomSDKDomain];
    [ZMSDKInitHelper setDomain:_setDomainTextField.stringValue];
    [self switchToAuthTab];
}


- (IBAction)onAuthClicked:(id)sender
{
    if (_sdkKeyTextField.stringValue.length > 0) {
        
        ZoomSDKError error = [_authHelper newAuth:_sdkKeyTextField.stringValue];
        NSLog(@"%u", error);
    }
}
- (IBAction)onEmailLoginClicked:(id)sender
{
    if(_emailTextField.stringValue.length > 0)
    {
        BOOL rememberMe = NO;
        if(_emailRememerMeButton.state == NSOnState)
            rememberMe = YES;
        [_emailLoginHelper loginWithEmail:_emailTextField.stringValue Password:_emailPSWTextField.stringValue RememberMe:rememberMe];
        [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_Email;
    }
}
- (IBAction)onEmailRemeberMeClicked:(id)sender
{
    return;
}
- (IBAction)onSSORememberMeClicked:(id)sender
{
    return;
}

- (IBAction)generateSSOLoginWebURL:(NSButton *)sender {
    if (_prefixUrlTextField.stringValue && _prefixUrlTextField.stringValue.length > 0) {
        NSString *webUrl = [[[ZoomSDK sharedSDK] getAuthService] generateSSOLoginWebURL:_prefixUrlTextField.stringValue];
        if (!webUrl || webUrl.length == 0)
            return;
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:webUrl]];
    }
}

- (IBAction)onSSOLoginClicked:(id)sender
{
    if (!_ssoTokenTextField.stringValue || _ssoTokenTextField.stringValue.length == 0)
        return;;
    [[[ZoomSDK sharedSDK] getAuthService] SSOLoginWithWebUriProtocol:_ssoTokenTextField.stringValue];
    
}
- (IBAction)onJoinOnlyClicked:(id)sender
{
    if(_joinOnlyMeetingIDTextField.stringValue.length > 0)
    {
        [_joinOnlyHelper joinMeetingOnly:_joinOnlyMeetingIDTextField.stringValue displayName:_joinOnlyUserNameTextField.stringValue meetingPSW:_joinOnlyMeetingPSWTextField.stringValue];
    }
}
- (IBAction)onErrorBackClicked:(id)sender
{
    [self switchToLoginTab];
}

- (IBAction)onApiLogin:(id)sender
{
    [_restAPIHelper loginRestApiWithUserID:_userIDField.stringValue zak:_zakString.stringValue];
}

- (void)switchToConnectingTab
{
    [_baseTabView selectTabViewItemWithIdentifier:@"loading"];
    [_loadingTextField setStringValue:@"Loading"];
    [_loadingProgressIndicator stopAnimation:self];
    [_loadingProgressIndicator startAnimation:self];
}
- (void)switchToLoginTab
{
    [_baseTabView selectTabViewItemWithIdentifier:@"login"];
    [_loadingProgressIndicator stopAnimation:self];
}
- (void)switchToErrorTab
{
    [_baseTabView selectTabViewItemWithIdentifier:@"error"];
    [_loadingProgressIndicator stopAnimation:self];
}
- (void)switchToAuthTab
{
    [_baseTabView selectTabViewItemWithIdentifier:@"auth"];
    [_loadingProgressIndicator stopAnimation:self];
}
- (void)switchToDomainTab
{
    [_baseTabView selectTabViewItemWithIdentifier:@"domain"];
    [_loadingProgressIndicator stopAnimation:self];
}
- (void)showErrorMessage:(NSString*)error
{
    _errorMessageTextField.stringValue = error;
}

- (void)removeEmailLoginTab
{
    NSTabViewItem* emailItem = nil;
    for(NSTabViewItem* item in _loginTabView.tabViewItems)
    {
        if([item.identifier isEqualToString:@"email login"])
            emailItem = item;
    }
    if(emailItem && [emailItem.identifier isEqualToString:@"email login"])
        [_loginTabView removeTabViewItem:emailItem];
}

- (void)createMainWindow
{
    if (self.mainWindowController)
    {
        [self.mainWindowController showWindow:nil];
        [self.mainWindowController updateUI];
        return;
    }
    self.mainWindowController = [[ZMSDKMainWindowController alloc] init] ;
    self.mainWindowController.loginWindowController = self;
    [self close];
    [self.mainWindowController.window makeKeyAndOrderFront:nil];
    [self.mainWindowController showWindow:nil];
}
- (void)updateUIWithLoginStatus:(BOOL)hasLogin
{
    [ZMSDKCommonHelper sharedInstance].hasLogin = hasLogin;
    BOOL isEmailLoginEnabled = NO;
    if([[[ZoomSDK sharedSDK] getAuthService] isEmailLoginEnabled:&isEmailLoginEnabled] == ZoomSDKError_Success && isEmailLoginEnabled)
    {
        if (_emailRememerMeButton.state == NSOnState && [ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email)
        {
            [[NSUserDefaults standardUserDefaults] setBool:hasLogin forKey:kZMSDKLoginEmailRemember];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}
- (void)logOut
{
    if ([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email)
    {
       [_emailLoginHelper logOutWithEmail];
    }
    else if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_SSO)
    {
        [_ssoLoginHelper logOutWithSSO];
    }
    if(self.mainWindowController)
       [self.mainWindowController close];
    if([self.window isVisible])
        [self switchToLoginTab];
    else
    {
        [self showSelf];
        [self switchToLoginTab];
    }
}
@end
