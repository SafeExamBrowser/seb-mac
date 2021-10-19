//
//  zoomController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 13.10.21.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKMeetingStatusMgr.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ProctoringUIDelegate <NSObject>

- (void) setProctoringViewButtonState:(BOOL)remoteProctoringViewButtonState;

@end

@class ZMSDKMeetingStatusMgr;

@interface SEBZoomController : NSObject <ZoomSDKAuthDelegate, ZoomProctoringDelegate> {
    @private
    BOOL openZoomWithOverrideParameters;
    BOOL _receiveAudioFlag;
    BOOL _receiveVideoFlag;
    BOOL _useChatFlag;
}

@property (strong, nonatomic) id proctoringUIDelegate;

@property (strong, nonatomic) ZoomSDKAuthService* authService;
@property (strong, nonatomic) ZMSDKMeetingStatusMgr *meetingStatusMgr;

@property (strong, nonatomic) NSURL *serverURL;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *room;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *sdkToken;
@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSString *meetingKey;

@property (readonly) BOOL zoomReceiveAudio;
@property (readonly) BOOL zoomReceiveAudioOverride;
@property (readonly) BOOL zoomReceiveVideo;
@property (readonly) BOOL zoomReceiveVideoOverride;
@property (readonly) BOOL zoomSendAudio;
@property (readonly) BOOL zoomSendVideo;
@property (readonly) NSUInteger remoteProctoringViewShowPolicy;
@property (readonly) BOOL audioMuted;
@property (readonly) BOOL videoMuted;
@property (readonly) BOOL useChat;
@property (readonly) BOOL closeCaptions;
@property (readonly) BOOL raiseHand;
@property (readonly) BOOL tileView;

@property (readwrite) BOOL viewIsVisible;
@property (readwrite) BOOL zoomActive;

@property (strong, nonatomic) void (^meetingEndedCompletionHandler)(void);

- (void) openZoomWithSender:(id)sender;

- (void) openZoomWithServerURL:(NSURL *)serverURL
                      userName:(NSString *)userName
                          room:(NSString *)room
                       subject:(NSString *)subject
                         token:(NSString *)token
                      sdkToken:(NSString *)sdkToken
                        apiKey:(NSString *)apiKey
                    meetingKey:(NSString *)meetingKey;

- (void) openZoomWithReceiveAudioOverride:(BOOL)receiveAudioFlag
                     receiveVideoOverride:(BOOL)receiveVideoFlag
                          useChatOverride:(BOOL)useChatFlag;

- (void) toggleZoomViewVisibilityWithSender:(id)sender;

- (void) updateProctoringViewButtonState;

- (void) closeZoomMeeting:(id)sender;

@end

NS_ASSUME_NONNULL_END
