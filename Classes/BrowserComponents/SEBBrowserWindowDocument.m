//
//  SEBBrowserWindowDocument.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.12.10.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SEBBrowserWindowDocument.h"
#import "SEBBrowserWindow.h"

@implementation SEBBrowserWindowDocument

@synthesize browserWindowController;

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

/*
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SEBBrowserDocument";
}
*/


- (void)makeWindowControllers {
    // Create the window controller and keep a reference to it.
    SEBBrowserWindowController *aBrowserWindowController = [[SEBBrowserWindowController alloc] initWithWindowNibName:@"SEBBrowserWindow"];
    
    // Set the reference to the browser controller in the browser window controller instance
    aBrowserWindowController.browserController = _browserController;

    [aBrowserWindowController setShouldCloseDocument:YES];
    [aBrowserWindowController showWindow:self];
    [self addWindowController:aBrowserWindowController];
    self.browserWindowController = aBrowserWindowController;
    [self.browserWindowController setDocumentEdited:NO];
}


- (SEBBrowserWindowController*)mainWindowController
{
    // Get window controllers
    NSArray*    windowControllers;
    windowControllers = [self windowControllers];
    if (!windowControllers || [windowControllers count] < 1) {
        return nil;
    }
    
    // Get first window controller
    id  windowController;
    windowController = [windowControllers objectAtIndex:0];
    if (![windowController isKindOfClass:[SEBBrowserWindowController class]]) {
        return nil;
    }
    
    return windowController;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    //[webView setUIDelegate:self];
    //[webView setGroupName:@"SEBBrowserDocument"];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
     You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
     */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    /*
     Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
     You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
     */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}


- (BOOL)isDocumentEdited
{
    // The browser windows are never edited
    return NO;
}


//- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldClose contextInfo:(void *)contextInfo
//{
//    DDLogDebug(@"%s: Closing document!", __FUNCTION__);
//    [self document:self shouldClose:YES contextInfo:nil];
//}

 
//- (void)document:(NSDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void  *)contextInfo
//{
//    if (shouldClose) {
//        DDLogDebug(@"%s: Closing document!", __FUNCTION__);
//        NSArray *windowControllers = [self windowControllers];
//        // Get first window controller
//        NSWindowController *windowController;
//        windowController = [windowControllers objectAtIndex:0];
//        [[(SEBBrowserWindow*)[windowController window] webView] close];
//        [self removeWindowController:windowController];
//        [windowController close];
//
//        [self close];
//    }
//}

@end
