//
//  ZMVideoPlayerControlView.h
//  zChatUI
//
//  Created by simon shang on 2020/12/11.
//  Copyright © 2020 Zoom. All rights reserved.
//

#import "ZMBaseView.h"
#import <ZCommonUI/ZCommonUI.h>

typedef NS_ENUM(NSInteger, ZMVideoPlayState)
{
    ZMVideoPlayState_None,
    ZMVideoPlayState_Pause,
    ZMVideoPlayState_Play
};

typedef NS_ENUM(NSInteger, ZMVideoPlayerControlStyle)
{
    ZMVideoPlayerControlStyle_Small,
    ZMVideoPlayerControlStyle_Large,
    ZMVideoPlayerControlStyle_FullScreen
};

NS_ASSUME_NONNULL_BEGIN

@protocol ZMVideoPlayerControlViewDelegate <NSObject>

- (void)playButtonClicked:(ZMVideoPlayState)state;
- (void)fullScreenButtonClicked:(ZMVideoPlayerControlStyle)currentPlayerControlStyle;
- (void)volumeButtonClicked:(BOOL)isMute;
- (void)sliderValueChanged:(NSTimeInterval)currentPlayedTime;
- (void)volumeSliderValueChanged:(CGFloat)currentVolume;

@end

@interface ZMVideoPlayerTimeInfo : NSObject

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval playedTime;

@end

@interface ZMVideoPlayerControlView : ZMBaseView

- (instancetype)initWithStyle:(ZMVideoPlayerControlStyle)style;

@property (nonatomic, retain) ZMVideoPlayerTimeInfo *timeInfo;

@property (nonatomic, assign) ZMVideoPlayState playState;

@property (nonatomic, assign) CGFloat volumeValue;

@property (nonatomic, weak) id<ZMVideoPlayerControlViewDelegate> delegate;

- (void)updatePlayedTime:(NSTimeInterval)playedTime;

- (void)updateControlStyle:(ZMVideoPlayerControlStyle)style;

@end

NS_ASSUME_NONNULL_END
