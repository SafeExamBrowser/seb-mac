//
//  SEBZoomController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 13.10.21.
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
