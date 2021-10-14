//
//  ZMHMenuWindow.h
//  zChatUI
//
//  Created by Huxley Yang on 2018/1/24.
//  Copyright © 2018年 Zipow. All rights reserved.
//

#import "ZMPureWindow.h"
#import "ZMBase.h"

@class ZMHMenu, ZMHMenuItem, ZMHMenuListView;
@interface ZMHMenuWindow : NSPanel <NSTextFieldDelegate>
{
    BOOL _loaded;
    ZMHMenu *_menu;
    ZMHMenuItem * _representedItem;
}

@property (weak, nonatomic) ZMHMenuWindow *subMenuWindow;
@property (retain) ZMHMenuListView *menuListView;
@property (retain, readonly) ZMHMenuItem * representedItem;
@property NSRectCorner preferredAnchorConner;
@property (assign) NSSize maxListSize;
@property (assign) BOOL hasSearchField;
@property (assign) BOOL assignKeyWindow;

- (instancetype)initWithMenu:(ZMHMenu *)menu representedItem:(ZMHMenuItem *)item;
- (instancetype)initWithMenu:(ZMHMenu *)menu representedItem:(ZMHMenuItem *)item maxSize:(NSSize)maxSize;
- (BOOL)isDescendantOf:(ZMHMenuWindow *)window;

- (void)show;
- (void)showInScreen:(NSScreen *)screen;
- (void)close;

- (BOOL)mouseOnSelfOrDescendantWindows;

- (void)performShowSubWindowWithItem:(ZMHMenuItem *)menuItem;

- (void)reloadMenuData;

- (ZMHMenuItem *)getSelectedItem;

//- (void)noteViewCliked:(NSView *)view;//

@end
