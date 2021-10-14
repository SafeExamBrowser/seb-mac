//
//  ZMVideoPlayerView.h
//  zChatUI
//
//  Created by simon shang on 2021/1/19.
//  Copyright © 2021 Zoom. All rights reserved.
//

#import "ZMBaseView.h"
#import "ZMVideoPlayerControlView.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kPauseOthersVideoPlay = @"kPauseOthersVideoPlay";

@class ZMVideoPlayerView;

@protocol ZMVideoPlayerViewDelegate <NSObject>

@optional
- (void)fullScreenButtonClicked:(ZMVideoPlayerControlStyle)currentPlayerControlStyle videoPlayerView:(ZMVideoPlayerView *)playerView fileModel:(ZMFileEntity *)fileModel;
- (void)videoPlayStateChanged:(BOOL)isPlayingState videoPlayerView:(ZMVideoPlayerView *)playerView;
- (void)mouseUpInVideoPlayerView:(NSEvent *)event;
- (void)mouseEnterInVideoPlayerView:(NSPoint)locationPoint;
- (void)clickRetryButton;

@end

@interface ZMVideoPlayerView : ZMBaseView

@property (nonatomic, retain) ZMFileEntity *fileModel;

@property (nonatomic, readonly) AVPlayer *avPlayer;

@property (nonatomic, assign) ZMVideoPlayerControlStyle controlStyle;

@property (nonatomic, assign) BOOL playDisable;

@property (nonatomic, weak) id<ZMVideoPlayerViewDelegate> delegate;

- (instancetype)initWithStyle:(ZMVideoPlayerControlStyle)style frameRect:(NSRect)rect;

- (void)updateUI;

- (void)pauseVideo;

- (void)displayWithAVPlayer:(AVPlayer *)avplayer;

- (void)displayWithFilePath:(NSString *)videoPath;

- (void)resetVideoPlayer;

@end

// ---------------------------------------------------------------------------------
// ZMAVPlayerView replaces the AVPlayerView provided by Apple. ZMAVPlayerView is a view only used for visual output, and solves the problem that the subviews added to the AVPlayerView on the lower version of macOS are covered by AVPlayerView.

@interface ZMAVPlayerView : NSView

@property (nonatomic, retain) AVPlayer *player;

@end

NS_ASSUME_NONNULL_END
