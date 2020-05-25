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
    CMSampleBufferRef copiedSampleBuffer;
    OSStatus success = CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &copiedSampleBuffer);
    if (success == noErr) {
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(copiedSampleBuffer);
        if (pixelBuffer) {
            [[[MyGlobals sharedMyGlobals] sebViewController] detectFace:pixelBuffer];
        }
        CFRelease(copiedSampleBuffer);
    }
    [self newCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

@end
