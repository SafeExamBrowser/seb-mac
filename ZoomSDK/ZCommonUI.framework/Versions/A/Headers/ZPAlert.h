//
//  ZPAlert.h
//  ZCommonUI
//
//  Created by John on 13-3-11.
//  Copyright (c) 2013年 zoom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ZPAlertDelegate
@optional
- (void)buttonDidClickedWithAlertType:(long)inAlertType buttonTag:(long)inButtonTag;

- (void)alertCancelWithAlertType:(long)inAlertType;

@end

@interface ZPAlert : NSWindow<NSWindowDelegate>
{
    NSImageView*    _logoImageView;
    NSTextField*    _contentTextField;
    int             _type;
}
@property(nonatomic, weak) id actionDelegate;
@property(nonatomic, assign) int type;

- (void)invisibleInSharing;

- (void)cleanUp;
- (void)showAlert;
- (void)showAlertInScreen:(NSScreen*)inScreen;
- (void)showAlertInWindow:(NSWindow*)inWindow;
- (void)showSheetInWindow:(NSWindow*)inWindow;

- (void)setAlertContent:(NSString*)inString;
- (void)setAttributedAlertContent:(NSAttributedString*)inString;

- (void)setAlertImage:(NSImage*)inImage;
- (void)setAlertTitle:(NSString*)inTitle;

- (void)setAlertContent:(NSString *)inString title:(NSString*)inTitle;
- (void)setAttributedAlertContent:(NSAttributedString *)inString title:(NSString*)inTitle;

- (void)setAlertContent:(NSString *)inString image:(NSImage*)inImage title:(NSString*)inTitle;
- (void)setAttributedAlertContent:(NSAttributedString *)inString image:(NSImage*)inImage title:(NSString*)inTitle;

- (void)addButtonWithTitle:(NSString*)inTitle tag:(NSInteger)inTag isDefaultButton:(BOOL)inbDefault;

//- (void)addButtonWithAttributedTitle:(NSAttributedString*)inTitle tag:(NSInteger)inTag;
@end



