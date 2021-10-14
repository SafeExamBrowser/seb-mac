//
//  ZMBaseTableCellView.h
//  zChatUI
//
//  Created by groot.ding on 2018/5/8.
//  Copyright © 2018年 Zoom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZMBaseTableRowView : NSTableRowView

@end


@interface ZMBaseTableCellView : NSTableCellView

@property (nonatomic,assign) NSEdgeInsets selectedEdgeInset;

@property (nonatomic,assign) CGFloat selectedRadius;

@property (nonatomic,retain) NSColor *fullFillBackgroundColor;

@property (nonatomic,retain) NSColor *backgroundColor;

@property (nonatomic,retain) NSColor *selectedBackgroundColor;

@property (nonatomic,retain) NSColor *inactiveSelectedBackgroundColor;

@property (nonatomic,retain) NSColor *hoverSelectedBackgroundColor;

@property(getter=isSelected) BOOL selected;

@property(getter=isHoverSelected) BOOL hoverSelected;

@property(nonatomic,assign) BOOL ignoreSelected;

@property(nonatomic,assign) BOOL ignoreHoverSelected;


- (NSColor *)currentBackgroudColor;

- (void)updateUI;

- (void)backgroundColorDidChange;

@end
