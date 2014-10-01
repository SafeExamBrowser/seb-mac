//
//  SEBDockItem.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 01/10/14.
//
//

#import "SEBDockItem.h"

@implementation SEBDockItem


- (id) initWithTitle:(NSString *)newTitle icon:(NSImage *)newIcon toolTip:(NSString *)newToolTip menu:(NSMenu *)newMenu target:(id)newTarget action:(SEL)newAction
{
    self = [super init];
    if (self) {
        _title = newTitle;
        _icon = newIcon;
        _toolTip = newToolTip;
        _menu = newMenu;
        _target = newTarget;
        _action = newAction;
    }
    return self;
}

@end
