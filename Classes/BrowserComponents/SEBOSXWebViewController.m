//
//  SEBOSXWebViewController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 09.08.21.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBOSXWebViewController.h"


@implementation SEBOSXWebViewController


- (instancetype)initNewTabMainWebView:(BOOL)mainWebView withCommonHostWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    if (self) {
        SEBAbstractWebView *sebAbstractWebView = [[SEBAbstractWebView alloc] initNewTabMainWebView:mainWebView withCommonHost:commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck delegate:delegate];
        _sebAbstractWebView = sebAbstractWebView;
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

//- (void)viewDidLayout
//{
//    [_sebAbstractWebView view]
//    
//}


@end
