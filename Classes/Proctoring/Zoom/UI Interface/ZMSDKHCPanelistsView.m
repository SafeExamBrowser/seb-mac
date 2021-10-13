//
//  ZMSDKHCPanelistsView.m
//  ZoomSDKSample
//
//  Created by derain on 17/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ZMSDKHCPanelistsView.h"
#import "ZMSDKHCTableItemView.h"
#import <ZoomSDK/ZoomSDK.h>

static CGFloat const Panelist_Row_Height = 40.0f;

@implementation ZMSDKHCPanelistsView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        _panelistUserArray = [[NSMutableArray alloc] init];
        [self initUI];
        return self;
    }
    return nil;
}
- (void)cleanUp
{
    if(_panelistUserArray)
    {
        [_panelistUserArray removeAllObjects];
        _panelistUserArray = nil;
    }
}
-(void)dealloc
{
    [self cleanUp];
}
- (void)initUI
{
    NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:self.bounds];
    [tableContainer setHasVerticalScroller:YES];
    [tableContainer setAutohidesScrollers:YES];
    tableContainer.layer.cornerRadius = 50.0f;
    [tableContainer setBackgroundColor:[NSColor grayColor]];
    
    _panelistTableView = [[NSTableView alloc] initWithFrame:tableContainer.contentView.bounds];
    [_panelistTableView setHeaderView:nil];
    [_panelistTableView setCornerView:nil];
    [_panelistTableView setAllowsColumnResizing:YES];
    [_panelistTableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    
    [_panelistTableView setDelegate:self];
    [_panelistTableView setDataSource:self];
    [_panelistTableView reloadData];
    // embed the table view in the scroll view, and add the scroll view to self.
    [tableContainer setDocumentView:_panelistTableView];
    
    [self addSubview:tableContainer];
}

#pragma mark - NSTableViewDelegate and NSTableViewDataSource
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return Panelist_Row_Height;
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == _panelistTableView)
    {
        if(_panelistUserArray)
            return _panelistUserArray.count;
        else
            return 0;
    }
    return 0;
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    if(aTableView == _panelistTableView)
        return YES;
    return NO;
}
- (NSView*)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
}
- (NSTableRowView*)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    if(tableView == _panelistTableView)
    {
        ZMSDKHCTableItemView* rowView = [tableView makeViewWithIdentifier:@"panelistItem" owner:self];
        if(!rowView)
        {
            rowView = [[ZMSDKHCTableItemView alloc] initWithFrame:NSMakeRect(tableView.frame.origin.x, tableView.frame.origin.y, NSWidth(tableView.bounds), Panelist_Row_Height)];
            rowView.identifier = @"panelistItem";
        }
        unsigned int userID = [[_panelistUserArray objectAtIndex:row] unsignedIntValue];
        if(userID)
        {
            [rowView setUserInfo:userID];
            [rowView setSelected:NO];
            [rowView updateUI];
        }
        return rowView;
    }
    return [[ZMSDKHCTableItemView alloc] initWithFrame:NSZeroRect];
}
- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    return;
}
- (void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    return;
}
- (void)initUserListArray
{
    NSArray* userList = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getParticipantsList];
    if(!_panelistUserArray)
        return;
    if(_panelistUserArray.count > 0)
    {
        [_panelistUserArray removeAllObjects];
    }
    if(userList && userList.count > 0)
    {
        for(NSNumber* userID in userList)
        {
            [_panelistUserArray addObject:userID];
        }
        [_panelistTableView reloadData];
    }
}
- (void)onUserJoin:(unsigned int)userID
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", [NSNumber numberWithUnsignedInt:userID]];
    NSArray *results = [_panelistUserArray filteredArrayUsingPredicate:predicate];
    
    if(results.count == 0)
    {
        [_panelistUserArray addObject:[NSNumber numberWithUnsignedInt:userID]];
        [_panelistTableView reloadData];
    }
}
- (void)onUserleft:(unsigned int)userID
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", [NSNumber numberWithUnsignedInt:userID]];
    
     NSArray *results = [_panelistUserArray filteredArrayUsingPredicate:predicate];
     if(results.count > 0)
     {
         [_panelistUserArray removeObject:[NSNumber numberWithUnsignedInt:userID]];
         [_panelistTableView reloadData];
     }
}

- (void)resetInfo
{
    if(_panelistUserArray && _panelistUserArray.count > 0)
    {
        [_panelistUserArray removeAllObjects];
        [_panelistTableView reloadData];
    }
}

@end
