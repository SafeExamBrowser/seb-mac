//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 01/10/14.
//
//

#import <Foundation/Foundation.h>
#import "SEBDockController.h"

@interface SEBDockItem : NSObject <SEBDockItem>

@property (strong, nonatomic) NSString *title;

@property (strong, nonatomic) NSImage *icon;

@property (strong, nonatomic) NSString *toolTip;

@property (strong, nonatomic) NSMenu *menu;

@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL action;


- (id) initWithTitle:(NSString *)newTitle icon:(NSImage *)newIcon toolTip:(NSString *)newToolTip menu:(NSMenu *)newMenu target:(id)newTarget action:(SEL)newAction;

@end
