//
//  zoomController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 13.10.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProctoringUIDelegate <NSObject>

- (void) setProctoringViewButtonState:(remoteProctoringButtonStates)remoteProctoringViewButtonState;
- (void) proctoringFailedWithErrorMessage:(NSString *)errorMessage;
- (void) successfullyRetriedToConnect;
- (NSRect) visibleFrameForScreen:(NSScreen *)screen;


@end

@interface SEBZoomController : NSObject 

@property (strong, nonatomic) id<ProctoringUIDelegate> proctoringUIDelegate;

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
@property (readonly) BOOL useChatOverride;
@property (readonly) BOOL closeCaptions;
@property (readonly) BOOL raiseHand;
@property (readonly) BOOL tileView;

@property (readwrite) BOOL viewIsVisible;
@property (readwrite) BOOL zoomActive;
@property (readwrite) BOOL zoomReconfiguring;

@property (strong, nonatomic) void (^meetingEndedCompletionHandler)(void);

- (void) openZoomWithSender:(id)sender;

@end

NS_ASSUME_NONNULL_END
