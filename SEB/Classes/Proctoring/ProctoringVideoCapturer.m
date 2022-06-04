//
//  ProctoringVideoCapturer.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "ProctoringVideoCapturer.h"
#import "MethodSwizzling.h"


@implementation RTCCameraVideoCapturer (ProctoringVideoCapturer)

+ (void)setupCaptureOutputHook
{
    [self swizzleMethod:@selector(captureOutput:didOutputSampleBuffer:fromConnection:)
             withMethod:@selector(newCaptureOutput:didOutputSampleBuffer:fromConnection:)];
}

- (void)newCaptureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    [[[MyGlobals sharedMyGlobals] sebViewController] detectFace:sampleBuffer];
    [self newCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

@end


@implementation RTCVideoSource (ProctoringVideoCapturer)

+ (void)setupCaptureVideoFrameHook
{
    [self swizzleMethod:@selector(capturer:didCaptureVideoFrame:)
             withMethod:@selector(newCapturer:didCaptureVideoFrame:)];
}

- (void)newCapturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame
{
    @synchronized(self) {
        RTCVideoFrame *modifiedFrame = [[[MyGlobals sharedMyGlobals] sebViewController] overlayFrame:frame];
        [self newCapturer:capturer didCaptureVideoFrame:modifiedFrame];
    }
}

@end


@implementation RTCAudioSession (ProctoringVideoCapturer)

+ (void)setupIsAudioEnabledHook
{
    [self swizzleMethod:@selector(useManualAudio)
             withMethod:@selector(newUseManualAudio)];
    [self swizzleMethod:@selector(isAudioEnabled)
             withMethod:@selector(newIsAudioEnabled)];
    [self swizzleMethod:@selector(inputAvailable)
             withMethod:@selector(newInputAvailable)];
}

- (BOOL)newUseManualAudio
{
    return NO;
}

- (BOOL)newIsAudioEnabled
{
    BOOL overrideIsAudioEnabled = YES;
    return overrideIsAudioEnabled;
}

- (BOOL)newInputAvailable
{
    return [[[MyGlobals sharedMyGlobals] sebViewController] rtcAudioInputEnabled];;
}

@end


@implementation RTCMediaStreamTrack (ProctoringVideoCapturer)

+ (void)setupIsTrackEnabledHook
{
    [self swizzleMethod:@selector(isEnabled)
             withMethod:@selector(newIsEnabled)];
    [self swizzleMethod:@selector(setIsEnabled:)
             withMethod:@selector(newSetIsEnabled:)];
}

- (BOOL)newIsEnabled
{
    BOOL isEnabled = [self newIsEnabled];
    return isEnabled;
}

- (void)newSetIsEnabled:(BOOL)isEnabled {
    [self newSetIsEnabled:isEnabled];
}

@end


@implementation RTCMediaStream (ProctoringVideoCapturer)

+ (void)setupAudioTracksHook
{
    [self swizzleMethod:@selector(audioTracks)
             withMethod:@selector(newAudioTracks)];
    [self swizzleMethod:@selector(videoTracks)
             withMethod:@selector(newVideoTracks)];
    [self swizzleMethod:@selector(addVideoTrack:)
             withMethod:@selector(newAddVideoTrack:)];
    [self swizzleMethod:@selector(removeVideoTrack:)
             withMethod:@selector(newRemoveVideoTrack:)];
}

- (NSArray<RTCAudioTrack *> *)newAudioTracks
{
    NSArray<RTCAudioTrack *> *audioTracks = [self newAudioTracks];
    if (audioTracks.count > 0) {
        RTCAudioTrack *remoteAudioTrack = audioTracks[0];
        BOOL rtcAudioReceivingEnabled = [[[MyGlobals sharedMyGlobals] sebViewController] rtcAudioReceivingEnabled];
        DDLogDebug(@"%@ remote RTCAudioTrack: %@", rtcAudioReceivingEnabled ? @"Unmuting" : @"Muting", remoteAudioTrack);
        [remoteAudioTrack setIsEnabled:rtcAudioReceivingEnabled];
    }
    return audioTracks;
}

- (NSArray<RTCVideoTrack *> *)newVideoTracks
{
    NSArray<RTCVideoTrack *> *videoTracks = [self newVideoTracks];
    if (videoTracks.count > 0) {
        RTCVideoTrack *videoTrack = videoTracks[0];
        BOOL isLocalVideoTrack = [[[MyGlobals sharedMyGlobals] sebViewController] rtcVideoTrackIsLocal:videoTrack];
        BOOL enableVideoTrack = isLocalVideoTrack ?
        [[[MyGlobals sharedMyGlobals] sebViewController] rtcVideoSendingEnabled] :
        [[[MyGlobals sharedMyGlobals] sebViewController] rtcVideoReceivingEnabled];

        NSString *trackId = videoTrack.trackId;
        DDLogDebug(@"%@ %@ RTCVideoTrack: Id %@", enableVideoTrack ? @"Enable" : @"Disable", isLocalVideoTrack ? @"local" : @"remote", trackId);
        [videoTrack setIsEnabled:enableVideoTrack];
    }
    return videoTracks;
}

- (void)newAddVideoTrack:(RTCVideoTrack *)videoTrack
{
    DDLogDebug(@"Adding local RTCVideoTrack: %@", videoTrack);
    [[[MyGlobals sharedMyGlobals] sebViewController].localRTCTracks addObject:videoTrack];
    [self newAddVideoTrack:videoTrack];
}

- (void)newRemoveVideoTrack:(RTCVideoTrack *)videoTrack
{
//    DDLogDebug(@"Removing RTCVideoTrack: %@", videoTrack);
//    [[[MyGlobals sharedMyGlobals] sebViewController].localRTCTracks removeObject:videoTrack];
//    [self newRemoveVideoTrack:videoTrack];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation RTCVideoTrack (ProctoringVideoCapturer)

+ (void)setupVideoTrackHook
{
    [self swizzleMethod:@selector(initWithFactory:source:trackId:)
             withMethod:@selector(newInitWithFactory:source:trackId:)];
}

- (instancetype)newInitWithFactory:(RTCPeerConnectionFactory *)factory
 source:(RTCVideoSource *)source
trackId:(NSString *)trackId
{
    id newInstance = [self newInitWithFactory:factory source:source trackId:trackId];
    return newInstance;
}

@end

#pragma clang diagnostic pop
