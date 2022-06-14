//
//  SEBBrowserWindowAccessoryView.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 23.03.22.
//

#import "SEBBrowserWindowAccessoryView.h"

@implementation SEBBrowserWindowAccessoryView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL okToChange = [super becomeFirstResponder];
    return okToChange;
}

- (BOOL)resignFirstResponder
{
    BOOL okToChange = [super resignFirstResponder];
    return okToChange;
}

@end
