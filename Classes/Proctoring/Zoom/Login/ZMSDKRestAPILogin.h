//
//  ZMSDKRestAPILogin.h
//  ZoomSDKSample
//
//  Created by TOTTI on 2018/11/20.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ZMSDKLoginWindowController;
@interface ZMSDKRestAPILogin : NSObject
@property(nonatomic, weak, readwrite)ZMSDKLoginWindowController* loginWindowCtrl;

-(id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController;
-(void)loginRestApiWithUserID:(NSString*)userID zak:(NSString*)zak;
@end
