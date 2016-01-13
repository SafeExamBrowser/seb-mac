//
//  OpenWebpages.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 29/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SEBWebViewController.h"

@interface OpenWebpages : NSObject

@property (nonatomic, retain) SEBWebViewController *webViewController;
@property (nonatomic, retain) NSNumber *loadDate;

@end
