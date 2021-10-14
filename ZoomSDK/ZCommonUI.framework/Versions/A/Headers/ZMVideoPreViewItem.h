//
//  ZMVideoPreViewItem.h
//  ZCommonUI
//
//  Created by simon shang on 2021/1/19.
//  Copyright © 2021 zoom. All rights reserved.
//

#import "ZMFilePreViewItem.h"
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZMVideoPreViewItem : ZMFilePreViewItem

@property (nonatomic, retain) AVPlayer *avPlayer;

@end

NS_ASSUME_NONNULL_END
