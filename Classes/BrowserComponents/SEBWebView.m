//
//  SEBWebView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.12.14.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBWebView.h"
#import "WebPluginDatabase.h"
#import "NSPasteboard+SaveRestore.h"


@implementation SEBWebView


- (NSTouchBar *)makeTouchBar
{
    return nil;
}


- (NSArray *)plugins
{
    NSArray *plugins = [[WebPluginDatabase sharedDatabase] plugins];
    return plugins;
}


- (void) reload:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:
         (self.window == self.browserController.mainBrowserWindow ?
          @"org_safeexambrowser_SEB_browserWindowAllowReload" : @"org_safeexambrowser_SEB_newBrowserWindowAllowReload")]) {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:
             (self.window == self.browserController.mainBrowserWindow ?
              @"org_safeexambrowser_SEB_showReloadWarning" : @"org_safeexambrowser_SEB_newBrowserWindowShowReloadWarning")]) {
            // Display warning and ask if to reload page
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Reload Current Page", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Do you really want to reload the current web page?", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Reload", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [newAlert setAlertStyle:NSWarningAlertStyle];
            
            void (^conditionalReload)(NSModalResponse) = ^void (NSModalResponse answer) {
                switch(answer) {
                    case NSAlertFirstButtonReturn:
                        // Reset the list of dismissed URLs and the dismissAll flag
                        // (for the Teach allowed/blocked URLs mode)
                        [self.notAllowedURLs removeAllObjects];
                        self.dismissAll = NO;
                        
                        // Reload page
                        DDLogInfo(@"Reloading current webpage");
                        [super reload:sender];
                        
                        break;
                        
                    default:
                        // Return without reloading page
                        return;
                }
            };
            
            if ((self.window.styleMask == NSBorderlessWindowMask ||
                 floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_9) &&
                floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_15) {
                [self.browserController.sebController.modalAlertWindows addObject:newAlert.window];
                NSModalResponse answer = [newAlert runModal];
                [self.browserController.sebController removeAlertWindow:newAlert.window];
                conditionalReload(answer);
                
            } else {
                [newAlert beginSheetModalForWindow:self.window completionHandler:(void (^)(NSModalResponse answer))conditionalReload];
            }
            
        } else {
            // Reload page without displaying warning
            DDLogInfo(@"Reloading current webpage");
            [super reload:sender];
        }
    }
}


// Optional blocking of dictionary lookup (by 3-finger tap)
-(void)quickLookWithEvent:(NSEvent *)event
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictionaryLookup"]) {
        [super quickLookWithEvent:event];
        DDLogInfo(@"Dictionary look-up was used! %s", __FUNCTION__);
    } else {
        DDLogInfo(@"Dictionary look-up was blocked! %s", __FUNCTION__);
    }
}


+ (BOOL)_canShowMIMEType:(NSString *)MIMEType allowingPlugins:(BOOL)allowPlugins
{
    if (!allowPlugins && [MIMEType isEqualToString:@"application/pdf"])
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
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MIMEType isEqualToString:@"application/pdf"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPDFPlugIn"])
    {
        return nil;
    }
    else
    {
        WebBasePluginPackage *plugInPackage = [super _pluginForMIMEType:MIMEType];
        return plugInPackage;
    }
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    
    NSString * chars = [theEvent characters];
    BOOL status = NO;
    
    if ([theEvent modifierFlags] & NSCommandKeyMask){
        
        if ([chars isEqualTo:@"c"]){
            [self copy:nil];
            status = YES;
        }
        
        if ([chars isEqualTo:@"v"]){
            [self paste:nil];
            status = YES;
        }
        
        if ([chars isEqualTo:@"x"]){
            [self cut:nil];
            status = YES;
        }
    }
    
    if (status)
        return YES;
    
    return [super performKeyEquivalent:theEvent];
}


- (void)copy:(id)sender
{
    [super copy:sender];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboard"] ||
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboardMacEnforce"]) {
        NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
        NSArray *archive = [generalPasteboard archiveObjects];
        _browserController.privatePasteboardItems = archive;
        [generalPasteboard clearContents];
    }
}


- (void)cut:(id)sender
{
    [super cut:sender];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboard"] ||
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboardMacEnforce"]) {
        NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
        NSArray *archive = [generalPasteboard archiveObjects];
        _browserController.privatePasteboardItems = archive;
        [generalPasteboard clearContents];
    }
}


- (void)paste:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboard"] ||
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboardMacEnforce"]) {
        NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
        [generalPasteboard clearContents];
        NSArray *archive = _browserController.privatePasteboardItems;
        [generalPasteboard restoreArchive:archive];
        [super paste:sender];
        [generalPasteboard clearContents];
    } else {
        [super paste:sender];
    }
}


- (BOOL)isAutomaticSpellingCorrectionEnabled
{
    return _browserController.allowSpellCheck;
}


@end
