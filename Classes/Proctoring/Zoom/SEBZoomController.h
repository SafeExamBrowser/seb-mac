//
//  zoomController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 13.10.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProctoringUIDelegate <NSObject>

- (void) setProctoringViewButtonState:(BOOL)remoteProctoringViewButtonState;

@end

@interface SEBZoomController : NSObject

@property (strong, nonatomic) id proctoringUIDelegate;

@property (strong, nonatomic) NSURL *serverURL;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *room;
@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *sdkToken;
@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSString *meetingKey;

@property (readwrite) BOOL zoomActive;
@property (readwrite) BOOL viewIsVisible;

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
