//
//  SEBWebView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.12.14.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBWebView.h"
#import "WebPluginDatabase.h"


@implementation SEBWebView


- (instancetype)initWithFrame:(NSRect)frameRect delegate:(SEBWebViewController <SEBAbstractWebViewNavigationDelegate>*)delegate
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _navigationDelegate = delegate;
    }
    return self;
}



- (NSTouchBar *)makeTouchBar
{
    return nil;
}


- (NSArray *)plugins
{
    NSArray *plugins = [[WebPluginDatabase sharedDatabase] plugins];
    return plugins;
}


// Optional blocking of dictionary lookup (by 3-finger tap)
-(void)quickLookWithEvent:(NSEvent *)event
{
    if (self.navigationDelegate.allowDictionaryLookup) {
        [super quickLookWithEvent:event];
        DDLogInfo(@"Dictionary look-up was used! %s", __FUNCTION__);
    } else {
        DDLogInfo(@"Dictionary look-up was blocked! %s", __FUNCTION__);
    }
}


+ (BOOL)_canShowMIMEType:(NSString *)MIMEType allowingPlugins:(BOOL)allowPlugins
{
    if (!allowPlugins && (MIMEType && [MIMEType caseInsensitiveCompare:mimeTypePDF] == NSOrderedSame))
    {
        return YES;
    }
    else
    {
        BOOL canShowType = [WebView _canShowMIMEType:MIMEType allowingPlugins:allowPlugins];
        return canShowType;
    }
}


- (WebBasePluginPackage *)_pluginForMIMEType:(NSString *)MIMEType
{
    if ((MIMEType && [MIMEType caseInsensitiveCompare:mimeTypePDF] == NSOrderedSame) && !self.navigationDelegate.allowPDFPlugIn)
    {
        return nil;
    }
    else
    {
        WebBasePluginPackage *plugInPackage = [super _pluginForMIMEType:MIMEType];
        return plugInPackage;
    }
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if (self.navigationDelegate.privateClipboardEnabled) {
        NSString * chars = [theEvent characters];
        BOOL status = NO;
        
        if ([theEvent modifierFlags] & NSCommandKeyMask) {
            
            if ([chars isEqualTo:@"c"]){
                [self privateCopy:nil];
                status = YES;
            }
            
            if ([chars isEqualTo:@"v"]){
                [self privatePaste:nil];
                status = YES;
            }
            
            if ([chars isEqualTo:@"x"]){
                [self privateCut:nil];
                status = YES;
            }
        }
        
        if (status) {
            return YES;
        }
    }
    return [super performKeyEquivalent:theEvent];
}


- (void)privateCopy:(id)sender
{
    [super copy:sender];
    if (self.navigationDelegate.privateClipboardEnabled) {
        [self.navigationDelegate storePasteboard];
    }
}


- (void)privateCut:(id)sender
{
    [super cut:sender];
    if (self.navigationDelegate.privateClipboardEnabled) {
        [self.navigationDelegate storePasteboard];
    }
}


- (void)privatePaste:(id)sender
{
    if (self.navigationDelegate.privateClipboardEnabled) {
        [self.navigationDelegate restorePasteboard];
        [super paste:sender];
        [[NSPasteboard generalPasteboard] clearContents];
    } else {
        [super paste:sender];
    }
}


- (BOOL)isAutomaticSpellingCorrectionEnabled
{
    return self.navigationDelegate.allowSpellCheck;
}


@end
