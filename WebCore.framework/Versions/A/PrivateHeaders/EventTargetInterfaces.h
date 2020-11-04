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

enum EventTargetInterface {
#if ENABLE(APPLE_PAY)
    ApplePaySessionEventTargetInterfaceType = 1,
#endif
#if ENABLE(ENCRYPTED_MEDIA)
    MediaKeySessionEventTargetInterfaceType = 2,
#endif
#if ENABLE(INDEXED_DATABASE)
    IDBDatabaseEventTargetInterfaceType = 3,
    IDBOpenDBRequestEventTargetInterfaceType = 4,
    IDBRequestEventTargetInterfaceType = 5,
    IDBTransactionEventTargetInterfaceType = 6,
#endif
#if ENABLE(LEGACY_ENCRYPTED_MEDIA)
    WebKitMediaKeySessionEventTargetInterfaceType = 7,
#endif
#if ENABLE(MEDIA_SOURCE)
    MediaSourceEventTargetInterfaceType = 8,
    SourceBufferEventTargetInterfaceType = 9,
    SourceBufferListEventTargetInterfaceType = 10,
#endif
#if ENABLE(MEDIA_STREAM)
    MediaDevicesEventTargetInterfaceType = 11,
    MediaRecorderEventTargetInterfaceType = 12,
    MediaStreamEventTargetInterfaceType = 13,
    MediaStreamTrackEventTargetInterfaceType = 14,
#endif
#if ENABLE(NOTIFICATIONS)
    NotificationEventTargetInterfaceType = 15,
#endif
#if ENABLE(OFFSCREEN_CANVAS)
    OffscreenCanvasEventTargetInterfaceType = 16,
#endif
#if ENABLE(PAYMENT_REQUEST)
    PaymentRequestEventTargetInterfaceType = 17,
    PaymentResponseEventTargetInterfaceType = 18,
#endif
#if ENABLE(PICTURE_IN_PICTURE_API)
    PictureInPictureWindowEventTargetInterfaceType = 19,
#endif
#if ENABLE(SERVICE_WORKER)
    ServiceWorkerEventTargetInterfaceType = 20,
    ServiceWorkerContainerEventTargetInterfaceType = 21,
    ServiceWorkerGlobalScopeEventTargetInterfaceType = 22,
    ServiceWorkerRegistrationEventTargetInterfaceType = 23,
#endif
#if ENABLE(SPEECH_SYNTHESIS)
    SpeechSynthesisUtteranceEventTargetInterfaceType = 24,
#endif
#if ENABLE(VIDEO)
    AudioTrackListEventTargetInterfaceType = 25,
    MediaControllerEventTargetInterfaceType = 26,
    TextTrackEventTargetInterfaceType = 27,
    TextTrackCueEventTargetInterfaceType = 28,
    TextTrackListEventTargetInterfaceType = 29,
    VideoTrackListEventTargetInterfaceType = 30,
#endif
#if ENABLE(WEBGPU)
    WebGPUDeviceEventTargetInterfaceType = 31,
#endif
#if ENABLE(WEBXR)
    WebXRLayerEventTargetInterfaceType = 32,
    WebXRSessionEventTargetInterfaceType = 33,
    WebXRSpaceEventTargetInterfaceType = 34,
    WebXRSystemEventTargetInterfaceType = 35,
#endif
#if ENABLE(WEB_AUDIO)
    AudioNodeEventTargetInterfaceType = 36,
    BaseAudioContextEventTargetInterfaceType = 37,
#endif
#if ENABLE(WEB_RTC)
    RTCDTMFSenderEventTargetInterfaceType = 38,
    RTCDataChannelEventTargetInterfaceType = 39,
    RTCPeerConnectionEventTargetInterfaceType = 40,
#endif
#if ENABLE(WIRELESS_PLAYBACK_TARGET)
    RemotePlaybackEventTargetInterfaceType = 41,
#endif
    EventTargetInterfaceType = 42,
    AbortSignalEventTargetInterfaceType = 43,
    ClipboardEventTargetInterfaceType = 44,
    DOMApplicationCacheEventTargetInterfaceType = 45,
    DOMWindowEventTargetInterfaceType = 46,
    DedicatedWorkerGlobalScopeEventTargetInterfaceType = 47,
    EventSourceEventTargetInterfaceType = 48,
    FileReaderEventTargetInterfaceType = 49,
    FontFaceSetEventTargetInterfaceType = 50,
    MediaQueryListEventTargetInterfaceType = 51,
    MessagePortEventTargetInterfaceType = 52,
    NodeEventTargetInterfaceType = 53,
    PerformanceEventTargetInterfaceType = 54,
    SpeechRecognitionEventTargetInterfaceType = 55,
    VisualViewportEventTargetInterfaceType = 56,
    WebAnimationEventTargetInterfaceType = 57,
    WebSocketEventTargetInterfaceType = 58,
    WorkerEventTargetInterfaceType = 59,
    WorkletGlobalScopeEventTargetInterfaceType = 60,
    XMLHttpRequestEventTargetInterfaceType = 61,
    XMLHttpRequestUploadEventTargetInterfaceType = 62,
};

} // namespace WebCore
