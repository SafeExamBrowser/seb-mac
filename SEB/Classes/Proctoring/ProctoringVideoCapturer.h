//
//  ProctoringVideoCapturer.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

#import <Foundation/Foundation.h>
#import "RTCCameraVideoCapturer.h"

NS_ASSUME_NONNULL_BEGIN

@interface RTCCameraVideoCapturer (ProctoringVideoCapturer)

+ (void)setupCaptureOutputHook;

- (void)newCaptureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
          fromConnection:(AVCaptureConnection *)connection;

@end

NS_ASSUME_NONNULL_END
