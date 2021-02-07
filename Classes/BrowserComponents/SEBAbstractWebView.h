//
//  SEBAbstractWebView.h
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SEBAbstractWebView;

@protocol SEBAbstractWebViewDelegate <NSObject>

@required
- (id)nativeWebView;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;
- (void)loadURL:(NSURL *)url;

@optional
- (void)toggleScrollLock;

- (void)SEBWebViewDidStartLoad:(SEBAbstractWebView *)sebWebView;
- (void)SEBWebViewDidFinishLoad:(SEBAbstractWebView *)sebWebView;
- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didFailLoadWithError:(NSError *)error;
- (BOOL)SEBWebView:(SEBAbstractWebView *)sebWebView shouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction;

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateTitle:(nullable NSString *)title;
- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateProgress:(double)progress;

@end


@interface SEBAbstractWebView : NSObject

@property (weak, nonatomic) id<SEBAbstractWebViewDelegate> delegate;

- (id)nativeWebView;

- (void)toggleScrollLock;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;
- (void)loadURL:(NSURL *)url;

/// SEB WebView Delegate Methods
- (void)SEBWebViewDidStartLoad:(SEBAbstractWebView *)sebWebView;
- (void)SEBWebViewDidFinishLoad:(SEBAbstractWebView *)sebWebView;
- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didFailLoadWithError:(NSError *)error;
- (BOOL)SEBWebView:(SEBAbstractWebView *)sebWebView shouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction;

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateTitle:(nullable NSString *)title;
- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateProgress:(double)progress;

@end

NS_ASSUME_NONNULL_END
