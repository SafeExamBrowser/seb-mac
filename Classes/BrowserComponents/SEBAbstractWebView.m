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

@implementation SEBAbstractWebView

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


- (id)nativeWebView
{
    return self.delegate.nativeWebView;
}


- (void)goBack
{
    [self.delegate goBack];
}

- (void)goForward
{
    [self.delegate goForward];
}

- (void)reload
{
    [self.delegate reload];
}

- (void)stopLoading
{
    [self.delegate stopLoading];
}

- (void)loadURL:(NSURL *)url
{
    [self.delegate loadURL:url];
}


- (void)toggleScrollLock
{
    if ([self.delegate respondsToSelector:@selector(toggleScrollLock)]) {
        [self.delegate toggleScrollLock];
    }
}

/// SEB WebView Delegate Methods

- (void)SEBWebViewDidStartLoad:(SEBAbstractWebView *)sebWebView
{
    if ([self.delegate respondsToSelector:@selector(SEBWebViewDidStartLoad:)]) {
        [self.delegate SEBWebViewDidStartLoad:sebWebView];
    }
}

- (void)SEBWebViewDidFinishLoad:(SEBAbstractWebView *)sebWebView
{
    if ([self.delegate respondsToSelector:@selector(SEBWebViewDidFinishLoad:)]) {
        [self.delegate SEBWebViewDidFinishLoad:sebWebView];
    }
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didFailLoadWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(SEBWebView:didFailLoadWithError:)]) {
        [self.delegate SEBWebView:sebWebView didFailLoadWithError:error];
    }
}

- (BOOL)SEBWebView:(SEBAbstractWebView *)sebWebView shouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
{
    if ([self.delegate respondsToSelector:@selector(SEBWebView:shouldStartLoadWithRequest:navigationAction:)]) {
        return [self.delegate SEBWebView:sebWebView shouldStartLoadWithRequest:request navigationAction:navigationAction];
    }
    return NO;
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateTitle:(nullable NSString *)title
{
    if ([self.delegate respondsToSelector:@selector(SEBWebView:didUpdateTitle:)]) {
        [self.delegate SEBWebView:sebWebView didUpdateTitle:title];
    }
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateProgress:(double)progress
{
    if ([self.delegate respondsToSelector:@selector(SEBWebView:didUpdateProgress:)]) {
        [self.delegate SEBWebView:sebWebView didUpdateProgress:progress];
    }
}


@end
