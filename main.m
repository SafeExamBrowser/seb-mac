//
//  main.m
//  SEB
//
//  Created by Daniel R. Schneider on 29.04.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSWindow+SEBWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

int main(int argc, char *argv[])
{
    // Swizzle NSWindow setLevel: Method
    [NSWindow setupChangingWindowLevels];
    
    [NSUserDefaults setSecret:@"shh, this is secret!"];

        
    return NSApplicationMain(argc,  (const char **) argv);
}
