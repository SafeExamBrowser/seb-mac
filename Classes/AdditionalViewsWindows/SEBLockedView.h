//
//  SEBLockedView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import <Cocoa/Cocoa.h>
#import "SEBController.h"

@class SEBController;

@interface SEBLockedView : NSView

@property (nonatomic, strong) SEBController *sebController;

@end
