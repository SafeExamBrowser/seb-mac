//
//  SEBiOSBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.04.21.
//

#import "SEBiOSBrowserController.h"

@implementation SEBiOSBrowserController

@synthesize startingUp;


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}


- (NSString *)currentMainHost
{
    return _sebViewController.browserTabViewController.currentMainHost;
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    _sebViewController.browserTabViewController.currentMainHost = currentMainHost;
}


- (void)closeWebView:(SEBAbstractWebView *)webViewToClose {
    [_sebViewController.browserTabViewController closeTab];
}


// Called when downloading the config file failed
- (void) downloadingSEBConfigFailed:(NSError *)error
{
    DDLogError(@"%s error: %@", __FUNCTION__, error);
    _sebViewController.openingSettings = false;
    
    // Only show the download error and close temp browser window if this wasn't a direct download attempt
    if (!self.directConfigDownloadAttempted) {
        
        // Close the temporary browser window
        [self closeWebView:self.temporaryWebView];
        // Show the load error
        [_sebViewController showAlertWithError:error];
        [self openingConfigURLRoleBack];
    }
}


- (void)openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL {
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    _sebViewController.openingSettings = true;
    [_sebViewController.configFileController storeNewSEBSettings:sebFileData
                                forEditing:NO
                                  callback:self
                                  selector:@selector(storeNewSEBSettingsSuccessful:)];
}


- (SEBAbstractWebView *)openTempWebViewForDownloadingConfigFromURL:(NSURL *)url {
    SEBAbstractWebView *tempWebView = [_sebViewController.browserTabViewController openNewTabWithURL:url];
    [tempWebView disableSpellCheck];
    
    return tempWebView;
}


- (void)openingConfigURLRoleBack {
    if (self.startingUp) {
        // we quit, as decrypting the config wasn't successful
        DDLogError(@"%s: SEB is starting up and opening a config link wasn't successfull, SEB will be terminated!", __FUNCTION__);
//        _sebController.quittingMyself = true; // quit SEB without asking for confirmation or password
//        [NSApp terminate: nil]; // Quit SEB
    }
    // Reset the opening settings flag which prevents opening URLs concurrently
    _sebViewController.openingSettings = false;
}

- (void)closeOpeningConfigFileDialog {
    
}


- (void)hideEnterUsernamePasswordDialog {
    
}


- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task {
    [_sebViewController sessionTaskDidCompleteSuccessfully:task];
}


- (BOOL)isStartingUp {
    return _sebViewController.startingUp;
}

- (void)setStartingUp:(BOOL)startingUp {
    _sebViewController.startingUp = startingUp;
}

- (void)showEnterUsernamePasswordDialog:(NSString *)text title:(NSString *)title username:(NSString *)username modalDelegate:(id)modalDelegate didEndSelector:(SEL)didEndSelector {
    [_sebViewController showEnterUsernamePasswordDialog:text title:title username:username modalDelegate:modalDelegate didEndSelector:didEndSelector];
}


- (void)showOpeningConfigFileDialog:(NSString *)text title:(NSString *)title cancelCallback:(id)callback selector:(SEL)selector {
    [_sebViewController showOpeningConfigFileDialog:text title:title cancelCallback:callback selector:selector];
}


- (NSString *) showURLplaceholderTitleForWebpage
{
    NSString *placeholderString = nil;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] <= browserWindowShowURLOnlyLoadError) {
            placeholderString = NSLocalizedString(@"the exam page", nil);
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] <= browserWindowShowURLOnlyLoadError) {
            placeholderString = NSLocalizedString(@"the webpage", nil);
        }
    }
    return placeholderString;
}


- (void)storeNewSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing forceConfiguringClient:(BOOL)forceConfiguringClient showReconfiguredAlert:(BOOL)showReconfiguredAlert callback:(id)callback selector:(SEL)selector {
    [_sebViewController storeNewSEBSettings:sebData forEditing:forEditing forceConfiguringClient:forceConfiguringClient showReconfiguredAlert:showReconfiguredAlert callback:callback selector:selector];
}


- (void) storeNewSEBSettingsSuccessfulProceed:(NSError *)error
{
    _sebViewController.openingSettings = NO;
    [_sebViewController storeNewSEBSettingsSuccessful:error];
}

@end
