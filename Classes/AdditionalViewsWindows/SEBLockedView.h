//
//  SEBLockedView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import <Cocoa/Cocoa.h>
#import "SEBController.h"
#import "SEBKeychainManager.h"

@class SEBController;

@interface SEBLockedView : NSView

@property (strong) SEBController *sebController;
@property (strong) SEBKeychainManager *keychainManager;

@end
