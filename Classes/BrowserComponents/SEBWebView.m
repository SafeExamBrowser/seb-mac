//
//  SEBWebView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.12.14.
//
//

#import "SEBWebView.h"

@implementation SEBWebView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


- (void) reload:(id)sender
{
    // Reset the list of dismissed URLs and the dismissAll flag
    // (for the Teach allowed/blocked URLs mode)
    [self.notAllowedURLs removeAllObjects];
    self.dismissAll = NO;
    
    // Reload page
    [super reload:sender];
}

@end
