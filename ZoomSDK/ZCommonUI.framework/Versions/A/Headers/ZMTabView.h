//
//  ZMTabView.h
//  ZCommonUI
//
//  Created by John on 11/25/14.
//  Copyright (c) 2014 zoom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMTrackingScrollView.h"

@interface ZMTabView : NSTabView
{
    NSColor*    _backgroundColor;
}
@property(nonatomic, retain) NSColor* backgroundColor;
@end

@interface ZMTableRowView : NSTableRowView
{
    NSColor* _hoverColor;
    BOOL    _hovered;
}
@property (nonatomic, readwrite, retain)NSColor*    hoverColor;
@property (nonatomic, readwrite, assign)BOOL        hovered;

- (void)updateState;
@end

@interface ZMTrackingTableView : NSTableView <ZMTrackingScrollViewProtocol>
{
    ZMTableRowView*     _lastSelectItemView;
    BOOL                _isEnableTrack;
    BOOL                _isMouseEntered;
}
@property(readwrite,retain)ZMTableRowView*      lastSelectItemView;
@property(readwrite,assign)BOOL                 isEnableTrack;
@property(readwrite,assign)BOOL                 isMouseEntered;
- (void)mouseEnteredView:(id)sender;
- (void)mouseMovedOnView:(id)sender;
- (void)mouseExitedView:(id)sender;
- (void)selectItemViewDidChange;

@end

