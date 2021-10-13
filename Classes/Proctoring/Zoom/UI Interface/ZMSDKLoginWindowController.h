//
//  ZMSDKLoginWindowController.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/15.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMSDKMainWindowController.h"

@class ZMSDKAuthHelper;
@class ZMSDKRestAPILogin;
@class ZMSDKEmailLogin;
@class ZMSDKSSOLogin;
@class ZMSDKJoinOnly;

#define kZMSDKLoginEmailRemember @"email remember me"
#define kZMSDKLoginSSORemember @"sso remember me"

@interface ZMSDKLoginWindowController : NSWindowController
{
    IBOutlet NSTabView* _baseTabView;
    //set domain
    IBOutlet NSImageView* _domainLogoImageView;
    IBOutlet NSTextField* _setDomainTextField;
    IBOutlet NSButton* _setDomainButton;
    IBOutlet NSButton* _setUseCustomizedUIButton;
    
    //auth
    IBOutlet NSImageView* _authLogoImageView;
    IBOutlet NSTextField* _sdkKeyTextField;
    IBOutlet NSButton* _authButton;
    
    //loading
    IBOutlet NSProgressIndicator* _loadingProgressIndicator;
    IBOutlet NSTextField* _loadingTextField;
    
    //error
    IBOutlet NSImageView* _errorLogoImageView;
    IBOutlet NSTextField* _connectFailedTextField;
    IBOutlet NSTextField* _errorMessageTextField;
    IBOutlet NSButton* _errorBackButton;
    
    //login
    IBOutlet NSTabView *_loginTabView;
    //email login
    __weak IBOutlet NSImageView *_emailLoginLogoImageView;
    __weak IBOutlet NSTextField *_emailTextField;
    __weak IBOutlet NSSecureTextField *_emailPSWTextField;
    __weak IBOutlet NSButton *_emailRememerMeButton;
    __weak IBOutlet NSButton *_emailLoginButton;
    
    //rest api login
    IBOutlet NSTextField* _zakString;
    IBOutlet NSTextField* _userIDField;

    //sso login
    IBOutlet NSImageView* ssoLoginLogoImageView;
    __weak IBOutlet NSTextField *_prefixUrlTextField;
    __weak IBOutlet NSTextField *_ssoTokenTextField;
    IBOutlet NSButton* _ssoLoginButton;
    
    //join only
    IBOutlet NSImageView* _joinOnlyLogoImageView;
    IBOutlet NSTextField* _joinOnlyMeetingIDTextField;
    IBOutlet NSTextField* _joinOnlyUserNameTextField;
    IBOutlet NSTextField* _joinOnlyMeetingPSWTextField;
    IBOutlet NSButton* _JoinOnlyButton;
}
@property(nonatomic, strong, readwrite)ZMSDKMainWindowController *mainWindowController;
@property(nonatomic, strong, readwrite)ZMSDKAuthHelper* authHelper;
@property(nonatomic, strong, readwrite)ZMSDKRestAPILogin* restAPIHelper;
@property(nonatomic, strong, readwrite)ZMSDKEmailLogin* emailLoginHelper;
@property(nonatomic, strong, readwrite)ZMSDKSSOLogin* ssoLoginHelper;
@property(nonatomic, strong, readwrite)ZMSDKJoinOnly* joinOnlyHelper;

- (IBAction)onSetDomainClicked:(id)sender;
- (IBAction)onAuthClicked:(id)sender;
- (IBAction)onEmailLoginClicked:(id)sender;
- (IBAction)onEmailRemeberMeClicked:(id)sender;
- (IBAction)onSSORememberMeClicked:(id)sender;
- (IBAction)onSSOLoginClicked:(id)sender;
- (IBAction)onJoinOnlyClicked:(id)sender;
- (IBAction)onErrorBackClicked:(id)sender;
- (IBAction)onApiLogin:(id)sender;
- (void)showSelf;
- (void)switchToConnectingTab;
- (void)switchToLoginTab;
- (void)switchToErrorTab;
- (void)switchToAuthTab;
- (void)switchToDomainTab;
- (void)showErrorMessage:(NSString*)error;

- (void)removeEmailLoginTab;

- (void)createMainWindow;
- (void)logOut;
- (void)updateUIWithLoginStatus:(BOOL)hasLogin;
@end
