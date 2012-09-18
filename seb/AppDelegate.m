//
//  AppDelegate.m
//  SEB
//
//  Created by Daniel R. Schneider on 29.04.10.
//  Copyright 2010 ETH Zurich LET. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
   /* [runningAppsWhileTerminating retain];
    runningAppsWhileTerminating = [[NSWorkspace sharedWorkspace] runningApplications];*/
}

                                   
/*
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	//return NO;
	
	int answer = NSRunAlertPanel(@"Quit",@"Are you sure you want to quit SEB?",
								 @"Quit",@"Cancel", nil);
	switch(answer)
	{
		case NSAlertDefaultReturn:
			return YES;
		default:
			return NO;
	}
}
*/

@end
