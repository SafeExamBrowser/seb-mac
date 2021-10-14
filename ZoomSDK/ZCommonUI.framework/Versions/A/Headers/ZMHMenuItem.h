//
//  ZMHMenuItem.h
//  zChatUI
//
//  Created by Huxley Yang on 2018/1/24.
//  Copyright © 2018年 Zipow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMHMenuItemView.h"
#import "ZMBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSView (ZMHMenuItemSubview)

- (void)enclosingMenuItemSelected:(BOOL)selected;//<! To override, called by rowview selection changed

@end

@class ZMHMenu;

typedef BOOL(^ZMHMenuItemBackgroundDrawer)(NSRect bounds, NSRect dirtyRect, BOOL selected);

@interface ZMHMenuItem : ZMBaseViewController <NSUserInterfaceItemIdentification>
//{
//    ZMHMenuItemView *_view;
//}

@property (copy, nonatomic, nullable) NSString *informative;
@property (copy, nonatomic, nullable) NSImage *image;
@property (copy, nonatomic, nullable) NSImage *alternateImage;

@property (nonatomic, retain) NSColor *titleColor;
@property (nonatomic, retain) NSColor *highlightTitleColor;

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, retain, nullable) id representedValue;
@property (nullable, weak) id target;
@property (nullable) SEL action;

@property (copy, nonatomic, nullable) NSArray <ZMHMenuItem *> *subItems;
@property (copy, nonatomic, nullable) NSString *subItemsTitle;
@property (weak, nonatomic) ZMHMenu *hmenu;//do not call the setter

@property (class, readonly) ZMHMenuItem *rootItem;
@property (class, readonly) ZMHMenuItem *separatedItem;

@property (readonly, nonatomic) BOOL isRoot;
@property (readonly, nonatomic) BOOL isSeparated;
@property (readonly, nonatomic) BOOL isCustomView;
@property (nonatomic) BOOL canSelect;//can highlight
@property (nonatomic) BOOL enable;
@property (nullable, copy) ZMHMenuItemBackgroundDrawer backgroundDrawer;

@property (nonatomic) BOOL eventFree;

@property (nonatomic) BOOL checked;

@property (nonatomic) BOOL defaultSelectedWithChecked;

@property (copy) NSString *tooltip;

@property (nonatomic, assign) CGFloat minWidth;

@property (nonatomic) BOOL ignoreIsCustomView;	// lisa.si's build break fix

@property (nonatomic, copy) NSString* accessibilityLabel;

+ (instancetype)itemWithTitle:(nullable NSString *)title informative:(nullable NSString *)informative image:(nullable NSImage *)image;

+ (instancetype)itemWithView:(NSView *)customView;//become customViewOnly with zero paddings
+ (instancetype)itemWithView:(NSView *)customView edgePaddings:(NSEdgeInsets)edgePaddings;//become customViewOnly

//MARK: Utils
- (void)performAction;
- (BOOL)locationInFrame:(NSPoint)location from:(NSView *)aView;
//- (void)viewReceivedMouseDown;
- (void)viewReceivedMouseUp;

- (void)updateCheckedStatus;

- (void)adjustToFixedWidth:(float)width;

@property (assign, nonatomic) BOOL selected;

@end
NS_ASSUME_NONNULL_END

