/*
 * THIS FILE WAS AUTOMATICALLY GENERATED, DO NOT EDIT.
 *
 * Copyright (C) 2011 Google Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#pragma once

namespace WebCore {

enum EventInterface {
#if ENABLE(APPLE_PAY)
    ApplePayCancelEventInterfaceType = 1,
    ApplePayPaymentAuthorizedEventInterfaceType = 2,
    ApplePayPaymentMethodSelectedEventInterfaceType = 3,
    ApplePayShippingContactSelectedEventInterfaceType = 4,
    ApplePayShippingMethodSelectedEventInterfaceType = 5,
    ApplePayValidateMerchantEventInterfaceType = 6,
#endif
#if ENABLE(DEVICE_ORIENTATION)
    DeviceMotionEventInterfaceType = 7,
    DeviceOrientationEventInterfaceType = 8,
#endif
#if ENABLE(ENCRYPTED_MEDIA)
    MediaEncryptedEventInterfaceType = 9,
    MediaKeyMessageEventInterfaceType = 10,
#endif
#if ENABLE(GAMEPAD)
    GamepadEventInterfaceType = 11,
#endif
#if ENABLE(INDEXED_DATABASE)
    IDBVersionChangeEventInterfaceType = 12,
#endif
#if ENABLE(IOS_GESTURE_EVENTS) || ENABLE(MAC_GESTURE_EVENTS)
    GestureEventInterfaceType = 13,
#endif
#if ENABLE(LEGACY_ENCRYPTED_MEDIA)
    WebKitMediaKeyMessageEventInterfaceType = 14,
    WebKitMediaKeyNeededEventInterfaceType = 15,
#endif
#if ENABLE(MEDIA_STREAM)
    BlobEventInterfaceType = 16,
    MediaRecorderErrorEventInterfaceType = 17,
    MediaStreamTrackEventInterfaceType = 18,
    OverconstrainedErrorEventInterfaceType = 19,
#endif
#if ENABLE(ORIENTATION_EVENTS)
#endif
#if ENABLE(PAYMENT_REQUEST)
    MerchantValidationEventInterfaceType = 20,
    PaymentMethodChangeEventInterfaceType = 21,
    PaymentRequestUpdateEventInterfaceType = 22,
#endif
#if ENABLE(PICTURE_IN_PICTURE_API)
    EnterPictureInPictureEventInterfaceType = 23,
#endif
#if ENABLE(SERVICE_WORKER)
    ExtendableEventInterfaceType = 24,
    ExtendableMessageEventInterfaceType = 25,
    FetchEventInterfaceType = 26,
#endif
#if ENABLE(SPEECH_SYNTHESIS)
    SpeechSynthesisEventInterfaceType = 27,
#endif
#if ENABLE(TOUCH_EVENTS)
    TouchEventInterfaceType = 28,
#endif
#if ENABLE(VIDEO)
    TrackEventInterfaceType = 29,
#endif
#if ENABLE(WEBGL)
    WebGLContextEventInterfaceType = 30,
#endif
#if ENABLE(WEBGPU)
    GPUUncapturedErrorEventInterfaceType = 31,
#endif
#if ENABLE(WEBXR)
    XRInputSourceEventInterfaceType = 32,
    XRInputSourcesChangeEventInterfaceType = 33,
    XRReferenceSpaceEventInterfaceType = 34,
    XRSessionEventInterfaceType = 35,
#endif
#if ENABLE(WEB_AUDIO)
    AudioProcessingEventInterfaceType = 36,
    OfflineAudioCompletionEventInterfaceType = 37,
#endif
#if ENABLE(WEB_RTC)
    RTCDTMFToneChangeEventInterfaceType = 38,
    RTCDataChannelEventInterfaceType = 39,
    RTCPeerConnectionIceEventInterfaceType = 40,
    RTCTrackEventInterfaceType = 41,
#endif
#if ENABLE(WIRELESS_PLAYBACK_TARGET)
    WebKitPlaybackTargetAvailabilityEventInterfaceType = 42,
#endif
    AnimationEventInterfaceType = 43,
    AnimationPlaybackEventInterfaceType = 44,
    BeforeLoadEventInterfaceType = 45,
    BeforeUnloadEventInterfaceType = 46,
    ClipboardEventInterfaceType = 47,
    CloseEventInterfaceType = 48,
    CompositionEventInterfaceType = 49,
    CustomEventInterfaceType = 50,
    DragEventInterfaceType = 51,
    ErrorEventInterfaceType = 52,
    EventInterfaceType = 53,
    FocusEventInterfaceType = 54,
    HashChangeEventInterfaceType = 55,
    InputEventInterfaceType = 56,
    KeyboardEventInterfaceType = 57,
    MediaQueryListEventInterfaceType = 58,
    MessageEventInterfaceType = 59,
    MouseEventInterfaceType = 60,
    MutationEventInterfaceType = 61,
    OverflowEventInterfaceType = 62,
    PageTransitionEventInterfaceType = 63,
    PointerEventInterfaceType = 64,
    PopStateEventInterfaceType = 65,
    ProgressEventInterfaceType = 66,
    PromiseRejectionEventInterfaceType = 67,
    SVGZoomEventInterfaceType = 68,
    SecurityPolicyViolationEventInterfaceType = 69,
    SpeechRecognitionErrorEventInterfaceType = 70,
    SpeechRecognitionEventInterfaceType = 71,
    StorageEventInterfaceType = 72,
    TextEventInterfaceType = 73,
    TransitionEventInterfaceType = 74,
    UIEventInterfaceType = 75,
    WebKitAnimationEventInterfaceType = 76,
    WebKitTransitionEventInterfaceType = 77,
    WheelEventInterfaceType = 78,
    XMLHttpRequestProgressEventInterfaceType = 79,
};

} // namespace WebCore
