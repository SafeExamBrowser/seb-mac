//
//  ProctoringVideoCapturer.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
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
    CMSampleBufferRef modifiedSampleBuffer = [[[MyGlobals sharedMyGlobals] sebViewController] detectFace:sampleBuffer];
    
    [self newCaptureOutput:captureOutput
     didOutputSampleBuffer:modifiedSampleBuffer
            fromConnection:connection];
}

@end
