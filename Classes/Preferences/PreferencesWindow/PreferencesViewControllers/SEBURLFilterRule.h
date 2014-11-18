//
//  SEBURLFilterRule.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 18.11.14.
//
//

#import <Foundation/Foundation.h>

@interface SEBURLFilterRule : NSMutableDictionary

@property (strong, nonatomic) NSString *title;

@property (strong, nonatomic) NSImage *icon;

@property (strong, nonatomic) NSString *toolTip;

@property (strong, nonatomic) NSMenu *menu;

@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL action;

@end
