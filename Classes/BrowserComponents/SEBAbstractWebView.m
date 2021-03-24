//
//  SEBAbstractWebView.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 04.11.20.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBAbstractWebView.h"
#import "SEBAbstractClassicWebView.h"
#import "SafeExamBrowser-Swift.h"


@implementation SEBAbstractWebView

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_URLFilterEnableContentFilter"] &&
            ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"]) {
            // Cancel if navigation is disabled in exam
            SEBAbstractModernWebView *sebAbstractModernWebView = [SEBAbstractModernWebView new];
            sebAbstractModernWebView.navigationDelegate = self;
            self.browserControllerDelegate = sebAbstractModernWebView;
        } else {
            SEBAbstractClassicWebView *sebAbstractClassicWebView = [SEBAbstractClassicWebView new];
            sebAbstractClassicWebView.navigationDelegate = self;
            self.browserControllerDelegate = sebAbstractClassicWebView;
        }
    }
    return self;
}


/// SEBAbstractBrowserControllerDelegate Methods

- (void)loadView
{
    [self.browserControllerDelegate loadView];
}

- (void)didMoveToParentViewController
{
    [self.browserControllerDelegate didMoveToParentViewController];
}

- (void)viewDidLayoutSubviews
{
    [self.browserControllerDelegate viewDidLayoutSubviews];
}
- (void)viewWillTransitionToSize
{
    [self.browserControllerDelegate viewWillTransitionToSize];
}
- (void)viewWillAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillAppear:(BOOL)animated];
}
- (void)viewDidAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewDidAppear:(BOOL)animated];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillDisappear:(BOOL)animated];
}


- (id)nativeWebView
{
    return self.browserControllerDelegate.nativeWebView;
}

- (NSURL*)url
{
    return [self.browserControllerDelegate url];
}

- (NSString*)pageTitle
{
    return [self.browserControllerDelegate pageTitle];
}

- (BOOL)canGoBack
{
    return [self.browserControllerDelegate canGoBack];
}

- (BOOL)canGoForward;
{
    return [self.browserControllerDelegate canGoForward];
}

- (void)goBack
{
    [self.browserControllerDelegate goBack];
}

- (void)goForward
{
    [self.browserControllerDelegate goForward];
}

- (void)reload
{
    [self.browserControllerDelegate reload];
}

- (void)loadURL:(NSURL *)url
{
    [self.browserControllerDelegate loadURL:url];
}

- (void)stopLoading
{
    [self.browserControllerDelegate stopLoading];
}


- (void)toggleScrollLock
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(toggleScrollLock)]) {
        [self.browserControllerDelegate toggleScrollLock];
    }
}

- (BOOL) isScrollLockActive
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(isScrollLockActive)]) {
        return [self.browserControllerDelegate isScrollLockActive];
    }
    return NO;
}


/// SEBAbstractWebViewNavigationDelegate Methods

- (void) setLoading:(BOOL)loading
{
    [self.navigationDelegate setLoading:loading];
}

- (void) setTitle:(NSString *)title
{
    [self.navigationDelegate setTitle:title];
}

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
}

- (void) openNewTabWithURL:(NSURL *)url
{
    [self.navigationDelegate openNewTabWithURL:url];
}

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
}


- (void)SEBWebViewDidStartLoad:(SEBAbstractWebView *)sebWebView
{
    [self.navigationDelegate SEBWebViewDidStartLoad:sebWebView];
}

- (void)SEBWebViewDidFinishLoad:(SEBAbstractWebView *)sebWebView
{
    [self.navigationDelegate SEBWebViewDidFinishLoad:sebWebView];
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didFailLoadWithError:(NSError *)error
{
    [self.navigationDelegate SEBWebView:sebWebView didFailLoadWithError:error];
}

- (BOOL)SEBWebView:(SEBAbstractWebView *)sebWebView shouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
{
    return [self.navigationDelegate SEBWebView:sebWebView shouldStartLoadWithRequest:request navigationAction:navigationAction];
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateTitle:(nullable NSString *)title
{
    if ([self.navigationDelegate respondsToSelector:@selector(SEBWebView:didUpdateTitle:)]) {
        [self.navigationDelegate SEBWebView:sebWebView didUpdateTitle:title];
    }
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateProgress:(double)progress
{
    if ([self.navigationDelegate respondsToSelector:@selector(SEBWebView:didUpdateProgress:)]) {
        [self.navigationDelegate SEBWebView:sebWebView didUpdateProgress:progress];
    }
}


- (SEBBackgroundTintStyle) backgroundTintStyle
{
    return [self.navigationDelegate backgroundTintStyle];
}

@end


@implementation SEBWKNavigationAction

- (void)setNavigationType:(WKNavigationType)navigationType
{
    _writableNavigationType = navigationType;
}

- (WKNavigationType)navigationType
{
    if (_writableNavigationType) {
        return _writableNavigationType;
    } else {
        return super.navigationType;
    }
}

@end
