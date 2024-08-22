//
//  SEBScreenProctoringController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 09.04.24.
//

import Foundation
import CocoaLumberjackSwift

private struct keysSPS {
    static let screenProctoringMethod = "method"
    static let screenProctoringMethodJoin = "JOIN"
    static let screenProctoringMethodLeave = "LEAVE"
    static let screenProctoringServiceURL = "screenProctoringServiceURL"
    static let screenProctoringClientId = "screenProctoringClientId"
    static let screenProctoringClientSecret = "screenProctoringClientSecret"
    static let screenProctoringGroupId = "screenProctoringGroupId"
    static let screenProctoringClientSessionId = "screenProctoringClientSessionId"
    
    static let accessTokenEndpoint = "/oauth/token"
    static let accessTokenEndpointAuthorization = "Basic"
    
    static let headerAuthorizationBearer = "Bearer"
    static let headerTimestamp = "timestamp"
    static let headerImageFormat = "imageFormat"
    static let headerMetaData = "metaData"
    static let responseHeaderServerHealth = "sps_server_health"
    static let dispatchQueueLabel = "org.safeexambrowser.SEB.ScreenShot"
    
    static let timeIntervalForHealthCheck = 15.0
    static let maxDelayForResumeTransmitting = 3 * 60
}

public enum ColorQuantization:Int {
    case blackWhite
    case grayscale2Bpp
    case grayscale4Bpp
    case grayscale8Bpp
    case color8Bpp
    case color16Bpp
    case color24Bpp
}

private struct SPSHealth {
    static let GOOD = 0
    static let BAD = 10
}

private struct SPSTransmittingState {
    static let normal = 0
    static let waitingForRecovery = 1
    static let delayForResuming = 2
}

@objc public protocol ScreenProctoringDelegate: AnyObject {
    
    func getScreenProctoringMetadataURL() -> String?
    func getScreenProctoringMetadataActiveAppWindow() -> [String:String]?
    @objc optional func getScreenProctoringMetadataUserAction() -> String?
    @objc optional func collectedTriggerEvent(eventData: String)
}

@objc public protocol SPSControllerUIDelegate: AnyObject {
    
    func updateStatus(string: String?, append: Bool)
    func setScreenProctoringButtonState(_: ScreenProctoringButtonStates)
}

struct MetadataSettings {
    var urlEnabled: Bool = false
    var activeWindowEnabled: Bool = false
    var activeAppEnabled: Bool = false
}

@objc public class SEBScreenProctoringController : NSObject, URLSessionDelegate, ScreenProctoringDelegate, ScreenShotTransmissionDelegate {
    
    @objc weak public var delegate: ScreenProctoringDelegate?
    @objc weak public var spsControllerUIDelegate: SPSControllerUIDelegate?
    
    private lazy var screenCaptureController: ScreenCaptureController = ScreenCaptureController()
    private lazy var metadataCollector: SEBSPMetadataCollector = SEBSPMetadataCollector(delegate: self, settings: self.metadataSettings)

    private var session: URLSession?
    private let pendingRequestsQueue = DispatchQueue.init(label: UUID().uuidString, attributes: .concurrent)
    
    private var _pendingRequests: [PendingServerRequest] = []
    public var pendingRequests: [PendingServerRequest] {
        get {
            var result: [PendingServerRequest] = []
            pendingRequestsQueue.sync() {
                result = self._pendingRequests
            }
            return result
        }
        
        set {
            pendingRequestsQueue.async(group: nil, qos: .default, flags: .barrier) {
                self._pendingRequests = newValue
            }
        }
    }
    
    private var accessToken: String?
    private var gettingAccessToken = false
    
    private var serviceURL: URL?
    private var clientId: String?
    private var clientSecret: String?
    private var groupId: String?
    private var sessionId: String?
    private var instructionConfirm: String?
    
    private var screenshotMinInterval: Int?
    private var screenshotMaxInterval: Int?
    private var imageFormat: Int?
    private var imageQuantization: ColorQuantization?
    private var imageDownscale: Double?
    private var imageScale = 0.5

    private var metadataSettings = MetadataSettings()
    
    private var maxRequestAttemps = 5
    private var fallbackAttemptInterval = 2000.0
    private var fallbackTimeout = 30000.0
    private var cancelAllRequests = false
    
    public var currentServerHealth = SPSHealth.GOOD
    private var transmittingState = SPSTransmittingState.normal
    private var latestCaptureScreenShotTimestamp: TimeInterval?
    private var latestTransmissionTimestamp: TimeInterval?
    private var screenShotDeferredTransmissionIntervalTimer: Timer?
    private lazy var screenShotCache = ScreenShotCache(delegate: self)

    private let timerQueue = DispatchQueue(label: keysSPS.dispatchQueueLabel, qos: .utility)
    private var screenShotMinIntervalTimer: Timer?
    private var screenShotMaxIntervalTimer: Timer?
    private lazy var repeatingTimerForHealthCheck = RepeatingTimer(timeInterval: TimeInterval(keysSPS.timeIntervalForHealthCheck), queue: DispatchQueue(label: keysSPS.dispatchQueueLabel, qos: .utility))
    private var delayForResumingTimer: DispatchWorkItem?
    
    private var sendingScreenShot = false
    private var latestTriggerEvent: String?
    private var latestTriggerEventTimestamp: TimeInterval?

    
    public func getScreenProctoringMetadataURL() -> String? {
        return delegate?.getScreenProctoringMetadataURL()
    }
    
    public func getScreenProctoringMetadataActiveAppWindow() -> [String : String]? {
        return delegate?.getScreenProctoringMetadataActiveAppWindow()
    }
    
    public func getScreenProctoringMetadataUserAction() -> String? {
        return delegate?.getScreenProctoringMetadataUserAction?()
    }
    

    @objc public override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
        DDLogInfo("SEB Screen Proctoring Controller: Initialize with max. request attempts \(self.maxRequestAttemps), fallback attempt interval \(self.fallbackAttemptInterval) and fallback timeout \(self.fallbackTimeout).")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = self.fallbackTimeout
        
        self.screenshotMinInterval = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringScreenshotMinInterval")
        self.screenshotMaxInterval = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringScreenshotMaxInterval")
        self.imageFormat = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringImageFormat")
        self.imageQuantization = ColorQuantization(rawValue: UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringImageQuantization"))
        self.imageDownscale = UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_screenProctoringImageDownscale")
        if self.imageDownscale == 0 {
            self.imageDownscale = 1
        }
        self.imageScale = 1/((self.imageDownscale ?? 1) * 2)

        self.metadataSettings.urlEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringMetadataURLEnabled")
        self.metadataSettings.activeWindowEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringMetadataWindowTitleEnabled")
        self.metadataSettings.activeAppEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringMetadataActiveAppEnabled")
        
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        DDLogError("SEB Screen Proctoring Controller: URLSession didBecomeInvalidWithError: \(String(describing: error)).")
        self.session = nil
    }

    @objc public func proctoringInstruction(attributes: [String: String]) {
        guard let method = attributes[keysSPS.screenProctoringMethod]
        else {
            return
        }
        guard let groupId = attributes[keysSPS.screenProctoringGroupId],
              let sessionId = attributes[keysSPS.screenProctoringClientSessionId],
              let instructionConfirm = attributes[keys.pingInstructionConfirm]
        else {
            return
        }
        self.groupId = groupId
        self.sessionId = sessionId
        self.instructionConfirm = instructionConfirm
        
        if method == keysSPS.screenProctoringMethodJoin {
            guard let serviceURL = attributes[keysSPS.screenProctoringServiceURL],
                  let clientId = attributes[keysSPS.screenProctoringClientId],
                  let clientSecret = attributes[keysSPS.screenProctoringClientSecret]
            else {
                return
            }
            self.serviceURL = URL(string: serviceURL)
            self.clientId = clientId
            self.clientSecret = clientSecret
            
            getServerAccessToken {
                self.startScreenProctoring()
            }
        }
        
        if method == keysSPS.screenProctoringMethodLeave {
            closeSession {
                // Session was closed
            }
        }
    }
}


extension SEBScreenProctoringController {

    private func load<Resource: ApiResource>(_ resource: Resource, httpMethod: String, body: Data, headers: [AnyHashable: Any]?, withCompletion resourceLoadCompletion: @escaping (Resource.Model?, Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        if !cancelAllRequests {
            let request = ApiRequest(resource: resource)
            let pendingRequest = PendingServerRequest(request: request)
            pendingRequests.append(pendingRequest)
            request.load(httpMethod: httpMethod, body: body, headers: headers, session: self.session, attempt: 0, completion: { [self] (response, statusCode, errorResponse, responseHeaders, attempt) in
                self.pendingRequests = self.pendingRequests.filter { $0 != pendingRequest }
                DDLogVerbose("SEB Screen Proctoring Controller: Load returned with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                if statusCode == statusCodes.unauthorized && errorResponse?.error == errors.invalidToken {
                    // Error: Unauthorized and token expired, get new token if not yet exceeded configured max attempts
                    DDLogError("SEB Screen Proctoring Controller: Load returned with invalid token error: expired, renew if not yet exceeded max. attempts (attempt: \(attempt)).")
                    if attempt <= self.maxRequestAttemps && !cancelAllRequests {
                        DispatchQueue.main.asyncAfter(deadline: (.now() + fallbackAttemptInterval)) {
                            self.getServerAccessToken {
                                // and try to perform the request again
                                request.load(httpMethod: httpMethod, body: body, headers: headers, session: self.session, attempt: attempt, completion: resourceLoadCompletion)
                            }
                        }
                    } else {
                        let errorDebugDescription = "Server reported Invalid Token for maxRequestAttempts"
                        let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("Repeating Error: Invalid Token", comment: ""),
                            NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your server administrator", comment: ""),
                                       NSDebugDescriptionErrorKey : errorDebugDescription]
                        let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
                        DDLogError("SEB Screen Proctoring Controller: Load failed because \(errorDebugDescription).")
                        self.didFail(error: error, fatal: true)
                    }
                    return
                }
                if !cancelAllRequests {
                    resourceLoadCompletion(response, statusCode, errorResponse, responseHeaders, attempt)
                }
            })
        }
    }

    private func loadWithFallback<Resource: ApiResource>(_ resource: Resource, httpMethod: String, body: Data, headers: [AnyHashable: Any]?, fallbackAttempt: Int, withCompletion resourceLoadCompletion: @escaping (Resource.Model?, Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        if !cancelAllRequests {
            load(resource, httpMethod: httpMethod, body: body, headers: headers, withCompletion: { (response, statusCode, errorResponse, responseHeaders, attempt) in
                DDLogVerbose("SEB Screen Proctoring Controller: Load with fallback returned with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                if statusCode == nil || statusCode ?? 0 >= statusCodes.notSuccessfullRange {
                    DDLogError("SEB Screen Proctoring Controller: Loading resource \(resource) with fallback not successful, status code: \(String(describing: statusCode)), attempt: \(fallbackAttempt).")
                    // Error: Try to load the resource again if maxRequestAttemps weren't reached yet
                    let currentAttempt = fallbackAttempt+1
                    if currentAttempt <= self.maxRequestAttemps {
                        self.spsControllerUIDelegate?.updateStatus(string: NSLocalizedString("Request failed, retrying...", comment: ""), append: true)
                        DispatchQueue.main.asyncAfter(deadline: (.now() + self.fallbackAttemptInterval)) {
                            // and try to perform the request again
                            self.loadWithFallback(resource, httpMethod: httpMethod, body: body, headers: headers, fallbackAttempt: currentAttempt, withCompletion: resourceLoadCompletion)
                            return
                        }
                        return
                    } //if maxRequestAttemps reached, report failure to load resource
                    DDLogError("SEB Screen Proctoring Controller: Load with fallback max. request attempts reached, aborting.")
                    self.spsControllerUIDelegate?.updateStatus(string: NSLocalizedString("Request failed", comment: ""), append: false)
                }
                if !self.cancelAllRequests {
                    resourceLoadCompletion(response, statusCode, errorResponse, responseHeaders, fallbackAttempt)
                }
            })
        }
    }

    private func getServerAccessToken(completionHandler: @escaping () -> Void) {
        if !gettingAccessToken {
            guard let baseURL = self.serviceURL else {
                return
            }
            gettingAccessToken = true
            let accessTokenResource = SPSAccessTokenResource(baseURL: baseURL, endpoint: keysSPS.accessTokenEndpoint)
            
            let authorizationString = keysSPS.accessTokenEndpointAuthorization + " " + ((clientId ?? "") + ":" + (clientSecret ?? "")).data(using: .utf8)!.base64EncodedString()
            let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                                  keys.headerAuthorization : authorizationString]
            
            load(accessTokenResource, httpMethod: accessTokenResource.httpMethod, body: accessTokenResource.body ?? Data(), headers: requestHeaders, withCompletion: { (accessTokenResponse, statusCode, errorResponse, responseHeaders, attempt) in
                self.gettingAccessToken = false
                if let accessToken = accessTokenResponse, let tokenString = accessToken?.access_token {
                    self.accessToken = tokenString
                    DDLogInfo("SEB Screen Proctoring Controller: Received server access token.")
                } else {
                    self.spsControllerUIDelegate?.updateStatus(string: NSLocalizedString("Request failed", comment: ""), append: false)
                    let errorDebugDescription = "Server didn't return \(accessTokenResponse == nil ? "access token response" : "access token") because of error \(errorResponse?.error ?? "Unspecified"), details: \(errorResponse?.error_description ?? "n/a")"
                    let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("Cannot access server because of error: ", comment: "") + (errorResponse?.error ?? errorDebugDescription),
                        NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your exam administrator", comment: ""),
                                   NSDebugDescriptionErrorKey : errorDebugDescription]
                    let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
                    DDLogError("SEB Screen Proctoring Controller: Cannot get server access token. \(errorDebugDescription).")
                    self.didFail(error: error, fatal: true)
                    return
                }
                if !self.cancelAllRequests {
                    completionHandler()
                }
            })
        } else {
            if !self.cancelAllRequests {
                completionHandler()
            }
        }
    }
    
    private func startScreenProctoring() {
        startMaxIntervalTimer()
        startMinIntervalTimer()
        metadataCollector.monitorEvents()
        spsControllerUIDelegate?.setScreenProctoringButtonState(ScreenProctoringButtonStateActive)
    }
    
    private func sendScreenShot(triggerMetadata: String, timeStamp: TimeInterval?) {
        if let screenShotData = self.screenCaptureController.takeScreenShot(scale: self.imageScale, quantization: self.imageQuantization ?? .grayscale4Bpp) {
            self.sendScreenShot(data: screenShotData, metaData: self.metadataCollector.collectMetaData(triggerMetadata: triggerMetadata) ?? "", timeStamp: timeStamp)
        }
        self.sendingScreenShot = false
    }
    
    private func sendScreenShot(data: Data, metaData: String, timeStamp: TimeInterval?) {
        
        var timeInterval: TimeInterval
        if timeStamp == nil {
            timeInterval = NSDate().timeIntervalSince1970
        } else {
            timeInterval = timeStamp!
        }
        latestCaptureScreenShotTimestamp = timeInterval

        if currentServerHealth == SPSHealth.BAD {
            if transmittingState != SPSTransmittingState.waitingForRecovery {
                if transmittingState == SPSTransmittingState.normal {
                    transmittingState = SPSTransmittingState.waitingForRecovery
                }
                if transmittingState == SPSTransmittingState.delayForResuming {
                    // Stop random timer for delay to resume sending cached screen shots
                    transmittingState = SPSTransmittingState.waitingForRecovery
                }
                // Start repeating timer to check server health on separate endpoint each 15 seconds
                repeatingTimerForHealthCheck.eventHandler = {
                    // Check server health without sending screen shot
                }
                repeatingTimerForHealthCheck.resume()
            }
            if transmittingState == SPSTransmittingState.normal {
                transmittingState = SPSTransmittingState.waitingForRecovery
            }
            if transmittingState == SPSTransmittingState.delayForResuming {
                transmittingState = SPSTransmittingState.waitingForRecovery
            }
        }
        
        if transmittingState == SPSTransmittingState.waitingForRecovery && currentServerHealth != SPSHealth.BAD {
            // If waiting for recovery and server health is no longer BAD, then start random delay to resume transmitting cached screen shots
            transmittingState = SPSTransmittingState.delayForResuming
            // Stop timer to check server health on separate endpoint and start random delay of max 3 minutes
            repeatingTimerForHealthCheck.reset()
            delayForResumingTimer = DispatchWorkItem { [weak self] in
                self?.transmittingState = SPSTransmittingState.normal
            }
            //we just created the work item, it is safe to force unwrap in this situation
            timerQueue.asyncAfter(deadline:.now() + 3, execute: self.delayForResumingTimer!)
            // { after that resume transmitting cached screen shots }
        }

        if currentServerHealth == SPSHealth.GOOD && transmittingState == SPSTransmittingState.normal {
            transmitScreenShot(data: data, metaData: metaData, timeStamp: timeInterval, resending: false, completion: {success in })
        } else {
            // Server health is not good, deferr transmitting screen shot and cache it to the file system
            // if waiting for recovery or in subsequent delay state, don't attempt to transmit those cached screen shots
            deferScreenShotTransmission(data: data, metaData: metaData, timeStamp: timeInterval, transmitNextCachedScreenShot: transmittingState == SPSTransmittingState.normal)
        }
    }
    
    private func deferScreenShotTransmission(data: Data, metaData: String, timeStamp: TimeInterval, transmitNextCachedScreenShot: Bool) {
        var transmissionInterval = Int(NSDate().timeIntervalSince1970 - (latestCaptureScreenShotTimestamp ?? 0))
        if transmissionInterval == 0 {
            transmissionInterval = 1
        }
        screenShotCache.cacheScreenShotForSending(data: data, metaData: metaData, timeStamp: timeStamp, transmissionInterval: transmissionInterval)
        if transmitNextCachedScreenShot {
            screenShotCache.transmitNextCachedScreenShot()
        }
    }
    
    private func transmitNextScreenShot() {
        if !screenShotCache.isEmpty {
            screenShotCache.transmitNextCachedScreenShot()
        }
    }

    func transmitScreenShot(data: Data, metaData: String, timeStamp: TimeInterval, resending: Bool, completion: @escaping (_ success: Bool) -> Void) {
        guard let baseURL = self.serviceURL, let sessionId = self.sessionId else {
            return
        }
        let screenShotResource = SPSScreenShotResource(baseURL: baseURL, endpoint: "/seb-api/v1/session/\(sessionId)/screenshot")
        
        let authorizationString = keysSPS.headerAuthorizationBearer + " " + (self.accessToken ?? "")
        
        let requestHeaders = [keys.headerContentType : keys.contentTypeOctetStream,
                              keys.headerAuthorization : authorizationString,
                              keysSPS.headerTimestamp : String(format: "%.0f", timeStamp * 1000),
                              keysSPS.headerMetaData : metaData] //,
//                              keysSPS.headerImageFormat : "png"]
        
        load(screenShotResource, httpMethod: screenShotResource.httpMethod, body: data, headers: requestHeaders, withCompletion: { (screenShotResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode != nil && statusCode ?? 0 == statusCodes.ok {
                if let health = Int((responseHeaders?.first(where: { ($0.key as? String)?.caseInsensitiveCompare(keysSPS.responseHeaderServerHealth) == .orderedSame}))?.value as? String ?? "") {
                    self.currentServerHealth = health
                    self.latestTransmissionTimestamp = NSDate().timeIntervalSince1970
                    completion(true)
                }
            } else {
                DDLogError("SEB Screen Proctoring Controller: Could not upload screen shot with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                // Cache screen shot and retry sending it
                self.currentServerHealth = SPSHealth.BAD
                if !resending {
                    self.deferScreenShotTransmission(data: data, metaData: metaData, timeStamp: timeStamp, transmitNextCachedScreenShot: false)
                }
                completion(false)
                return
            }
        })
    }
    
    private func startMaxIntervalTimer() {
        if self.screenShotMaxIntervalTimer == nil {
            timerQueue.async { [unowned self] in
                let timer = Timer(timeInterval: TimeInterval((self.screenshotMaxInterval ?? 5000)/1000), repeats: false, block: { Timer in
                    self.screenShotMaxIntervallTriggered()
                })
                self.screenShotMaxIntervalTimer = timer
                let currentRunLoop = RunLoop.current
                currentRunLoop.add(timer, forMode: .common)
                currentRunLoop.run()
            }
        }
    }
    
    private func startMinIntervalTimer() {
        if self.screenShotMinIntervalTimer == nil {
            timerQueue.async { [unowned self] in
                let timer = Timer(timeInterval: TimeInterval((self.screenshotMinInterval ?? 1000)/1000), repeats: false, block: { Timer in
                    self.screenShotMinIntervallTriggered()
                })
                self.screenShotMinIntervalTimer = timer
                let currentRunLoop = RunLoop.current
                currentRunLoop.add(timer, forMode: .common)
                currentRunLoop.run()
            }
        }
    }
    
    func stopMaxIntervalTimer() {
      timerQueue.async { [unowned self] in
         if self.screenShotMaxIntervalTimer != nil {
             self.screenShotMaxIntervalTimer?.invalidate()
             self.screenShotMaxIntervalTimer = nil
        }
      }
    }

    func stopMinIntervalTimer() {
      timerQueue.async { [unowned self] in
        if self.screenShotMinIntervalTimer != nil {
            self.screenShotMinIntervalTimer?.invalidate()
            self.screenShotMinIntervalTimer = nil
        }
      }
    }

    private func screenShotMinIntervallTriggered() {
        if !self.sendingScreenShot {
            if self.latestTriggerEvent != nil {
                self.sendingScreenShot = true
                self.stopMaxIntervalTimer()
                self.stopMinIntervalTimer()
                let triggerEventString = self.latestTriggerEvent
                self.latestTriggerEvent = nil
                self.sendScreenShot(triggerMetadata: triggerEventString ?? "", timeStamp: self.latestTriggerEventTimestamp)
                self.startMinIntervalTimer()
                self.startMaxIntervalTimer()
            } else {
                self.stopMinIntervalTimer()
            }
        }
    }
    
    private func screenShotMaxIntervallTriggered() {
        if !self.sendingScreenShot {
            self.sendingScreenShot = true
            self.stopMinIntervalTimer()
            self.stopMaxIntervalTimer()
            let triggerEventString = self.latestTriggerEvent
            if triggerEventString == nil {
                self.sendScreenShot(triggerMetadata: "Maximum interval of \(String(self.screenshotMaxInterval ?? 5000))ms has been reached.", timeStamp: nil)
            } else {
                self.latestTriggerEvent = nil
                self.sendScreenShot(triggerMetadata: triggerEventString ?? "", timeStamp: self.latestTriggerEventTimestamp)
            }
            self.startMaxIntervalTimer()
            self.startMinIntervalTimer()
        }
    }
    
    func startDeferredTransmissionTimer(_ interval: Int) {
        if self.screenShotDeferredTransmissionIntervalTimer == nil {
            timerQueue.async { [unowned self] in
                let timer = Timer(timeInterval: TimeInterval(interval), repeats: false, block: { Timer in
                    self.screenShotDeferredTransmissionIntervallTriggered()
                })
                self.screenShotDeferredTransmissionIntervalTimer = timer
                let currentRunLoop = RunLoop.current
                currentRunLoop.add(timer, forMode: .common)
                currentRunLoop.run()
            }
        }
    }
    
    func stopDeferredTransmissionIntervalTimer() {
      timerQueue.async { [unowned self] in
         if self.screenShotDeferredTransmissionIntervalTimer != nil {
             self.screenShotDeferredTransmissionIntervalTimer?.invalidate()
             self.screenShotDeferredTransmissionIntervalTimer = nil
        }
      }
    }


    private func screenShotDeferredTransmissionIntervallTriggered() {
        self.stopDeferredTransmissionIntervalTimer()
        transmitNextScreenShot()
    }
    
    @objc func closeSession(completionHandler: @escaping () -> Void) {
        stopMinIntervalTimer()
        stopMaxIntervalTimer()
        spsControllerUIDelegate?.setScreenProctoringButtonState(ScreenProctoringButtonStateInactive)
        guard let baseURL = self.serviceURL, let sessionId = self.sessionId else {
            return
        }
        let closeSessionResource = SPSCloseSessionResource(baseURL: baseURL, endpoint: "/seb-api/v1/session/\(sessionId)")
        
        let authorizationString = keysSPS.headerAuthorizationBearer + " " + (self.accessToken ?? "")
        let requestHeaders = [keys.headerAuthorization : authorizationString]
        
        load(closeSessionResource, httpMethod: closeSessionResource.httpMethod, body: Data(), headers: requestHeaders, withCompletion: { (closeSessionResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode != nil && statusCode ?? 0 == statusCodes.ok {
                DDLogInfo("SEB Screen Proctoring Controller: Session was closed.")
            } else {
                DDLogError("SEB Screen Proctoring Controller: Could not close session with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
            }
            if !self.cancelAllRequests {
                completionHandler()
            }
        })
    }
    
    private func checkHealth(completionHandler: @escaping () -> Void) {
        guard let baseURL = self.serviceURL else {
            return
        }
        let healthCheckResource = SPSHealthCheckResource(baseURL: baseURL, endpoint: "/health")
        
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded]
        
        load(healthCheckResource, httpMethod: healthCheckResource.httpMethod, body: Data(), headers: requestHeaders, withCompletion: { (healthCheckResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode != nil || statusCode ?? 0 == statusCodes.ok {
                if let health = Int((responseHeaders?.first(where: { ($0.key as? String)?.caseInsensitiveCompare(keysSPS.responseHeaderServerHealth) == .orderedSame}))?.value as? String ?? "") {
                    self.currentServerHealth = health
                    DDLogDebug("SEB Screen Proctoring Controller: Current server health: \(health).")
                }
            } else {
                DDLogError("SEB Screen Proctoring Controller: Could not get server health with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                // ToDo: Cache screen shot and retry sending it
                return
            }
            if !self.cancelAllRequests {
                completionHandler()
            }
        })
    }
    
    private func didFail(error: NSError, fatal: Bool) {
        spsControllerUIDelegate?.setScreenProctoringButtonState(ScreenProctoringButtonStateActiveError)
        if !cancelAllRequests {
//            self.delegate?.didFail(error: error, fatal: fatal)
        }
    }

    public func collectedTriggerEvent(eventData:String) {
        latestTriggerEvent = eventData
        latestTriggerEventTimestamp = NSDate().timeIntervalSince1970
        if screenShotMinIntervalTimer == nil {
            // The minimum interval has passed, trigger screen shot immediately
            timerQueue.async { [unowned self] in
                screenShotMinIntervallTriggered()
            }
        }
    }
}

