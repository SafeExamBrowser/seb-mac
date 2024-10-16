//
//  SEBScreenProctoringController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 09.04.24.
//

import Foundation
import CocoaLumberjackSwift

public struct keysSPS {
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
    
    static let alphanumericKeyString = "alphanumeric key"
}

public enum ColorQuantization: Int {
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
    func getScreenProctoringMetadataBrowser() -> String?
    @objc optional func getScreenProctoringMetadataUserAction() -> String?
    @objc optional func collectedTriggerEvent(eventData: String)
    @objc optional func collectedKeyboardShortcutEvent(_ eventData: String)
    @objc optional func collectedAlphanumericKeyEvent()
}

@objc public protocol SPSControllerUIDelegate: AnyObject {
    
    func updateStatus(string: String?, append: Bool)
    func setScreenProctoringButtonState(_: ScreenProctoringButtonStates)
    func setScreenProctoringButtonInfoString(_: String)
    func showTransmittingCachedScreenShotsWindow(remainingScreenShots: Int, message: String?, operation: String?)
    func updateTransmittingCachedScreenShotsWindow(remainingScreenShots: Int, message: String?, operation: String?, totalScreenShots: Int)
    func updateTransmittingCachedScreenShotsWindow(remainingScreenShots: Int, message: String?, operation: String?, append: Bool, totalScreenShots: Int)
    func allowQuit(_ allowQuit: Bool)
    func closeTransmittingCachedScreenShotsWindow(_ completion: @escaping () -> Void)
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
    private var fallbackAttemptInterval = 2000.0/1000
    private var fallbackTimeout = 30000.0/1000
    private var cancelAllRequests = false
    
    public var currentServerHealth = SPSHealth.GOOD
    private var transmittingState = SPSTransmittingState.normal
    private var closingSession = false
    @objc public var sessionIsClosing: Bool {
        get {
            return self.closingSession
        }
    }
    private var closingSessionCompletionHandler: (() -> Void)?
    
    private var latestCaptureScreenShotTimestamp: TimeInterval?
    private var latestTransmissionTimestamp: TimeInterval?
    
    // Could do this much easier if lazy vars could be reset! private lazy var screenShotCache = ScreenShotCache(delegate: self)
    private var screenShotCache: ScreenShotCache {
        get {
            if _screenShotCache == nil {
                _screenShotCache = ScreenShotCache(delegate: self)
            }
            return _screenShotCache!
        }
        set {
            _screenShotCache = newValue
        }
    }
    var _screenShotCache: ScreenShotCache? = nil
    
//    private let minIntervalTimerQueue = DispatchQueue.global(qos: .utility) //DispatchQueue(label: keysSPS.dispatchQueueLabel+".minInterval", qos: .utility)
//    private let maxIntervalTimerQueue = DispatchQueue.global(qos: .utility) //DispatchQueue(label: keysSPS.dispatchQueueLabel+".maxInterval", qos: .utility)
//    private let screenShotTimerQueue = DispatchQueue.global(qos: .utility) //DispatchQueue(label: keysSPS.dispatchQueueLabel+".screenShot", qos: .utility)
//    private let screenShotTimerQueue = DispatchQueue(label: keysSPS.dispatchQueueLabel+".screenShot", qos: .utility)
    private let minIntervalTimerQueue = DispatchQueue(label: keysSPS.dispatchQueueLabel+".minInterval", qos: .utility)
    private let maxIntervalTimerQueue = DispatchQueue(label: keysSPS.dispatchQueueLabel+".maxInterval", qos: .utility)
    private var screenShotMinIntervalTimer: RepeatingTimer?
    private var screenShotMaxIntervalTimer: RepeatingTimer?
//    private let deferredTimerQueue = DispatchQueue.global(qos: .utility) //DispatchQueue(label: keysSPS.dispatchQueueLabel+".deferredTransmission", qos: .utility)
    private let deferredTimerQueue = DispatchQueue(label: keysSPS.dispatchQueueLabel+".deferredTransmission", qos: .utility)
    private let delayForResumingTimerQueue = DispatchQueue(label: keysSPS.dispatchQueueLabel+".resumingDelay", qos: .utility)
    private var screenShotDeferredTransmissionIntervalTimer: RepeatingTimer?
    private var transmittingDeferredScreenShotsWhileClosingErrorCount = 0
    private let transmittingDeferredScreenShotsWhileClosingMaxErrorCount = 5
    private var numberOfCachedScreenShotsWhileClosing = 0
    private let timeIntervalForHealthCheck = 15.0
    private let maxDelayForResumingTransmitting = 3.0 * 60
    private var repeatingTimerForHealthCheck: RepeatingTimer?
    private var delayForResumingTimer: DispatchWorkItem?
    
    private var sendingScreenShot = false
    private var latestTriggerEvent: String?
    private var latestTriggerEventTimestamp: TimeInterval?
    private var alphanumericKeyCount = 0
    private var keyboardShortcuts = Array<String>()

    // UI
    private var indicateHealthAndCaching = false
    private var screenProctoringButtonState = ScreenProctoringButtonStateInactive
    private var screenProctoringButtonInfoString: String?
    
    public func getScreenProctoringMetadataURL() -> String? {
        return delegate?.getScreenProctoringMetadataURL()
    }
    
    public func getScreenProctoringMetadataActiveAppWindow() -> [String : String]? {
        return delegate?.getScreenProctoringMetadataActiveAppWindow()
    }
    
    public func getScreenProctoringMetadataUserAction() -> String? {
        return delegate?.getScreenProctoringMetadataUserAction?()
    }
    
    public func getScreenProctoringMetadataBrowser() -> String? {
        return delegate?.getScreenProctoringMetadataBrowser()
    }
    

    @objc public override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
        DDLogInfo("SEB Screen Proctoring Controller: Initialize with max. request attempts \(self.maxRequestAttemps), fallback attempt interval \(self.fallbackAttemptInterval) and fallback timeout \(self.fallbackTimeout).")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = self.fallbackTimeout
        
        self.maxRequestAttemps = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_sebServerFallbackAttempts")
        self.fallbackAttemptInterval = UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_sebServerFallbackAttemptInterval") / 1000
        self.fallbackTimeout = UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_sebServerFallbackTimeout") / 1000
        DDLogInfo("SEB Screen Proctoring Controller: Initialize with max. request attempts \(self.maxRequestAttemps), fallback attempt interval \(self.fallbackAttemptInterval) and fallback timeout \(self.fallbackTimeout).")

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
        
#if DEBUG
        self.indicateHealthAndCaching = true
#else
        self.indicateHealthAndCaching = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringIndicateHealthAndCaching")
#endif
        
        super.init()
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    deinit {
        DDLogDebug("SEB Screen Proctoring Controller: deint called")
        _screenShotCache = nil
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
//        screenShotTimerQueue.async { [unowned self] in
            startMaxIntervalTimer()
            startMinIntervalTimer()
//        }
        metadataCollector.monitorEvents()
        self.setScreenProctoringButtonState(ScreenProctoringButtonStateActive)
    }
    
    private func captureScreenShot(triggerMetadata: String, timeStamp: TimeInterval?) {
        if let screenShotData = self.screenCaptureController.takeScreenShot(scale: self.imageScale, quantization: self.imageQuantization ?? .grayscale4Bpp) {
            self.sendScreenShot(data: screenShotData, metaData: self.metadataCollector.collectMetaData(triggerMetadata: triggerMetadata) ?? "", timeStamp: timeStamp, resending: false) { success in
            }
        }
    }
    
    private var totalNumberOfCachedScreenShotsWhileClosing: Int {
        let totalCached = max(numberOfCachedScreenShotsWhileClosing, self.screenShotCache.count)
        if totalCached > numberOfCachedScreenShotsWhileClosing {
            numberOfCachedScreenShotsWhileClosing = totalCached
        }
        return totalCached
    }
    
    public func sendScreenShot(data: Data, metaData: String, timeStamp: TimeInterval?, resending: Bool, completion: ((_ success: Bool) -> Void)?) {
        DDLogDebug("SEB Screen Proctoring Controller sendScreenShot")

        var timeInterval: TimeInterval
        if timeStamp == nil {
            timeInterval = NSDate().timeIntervalSince1970
        } else {
            timeInterval = timeStamp!
        }
        if !resending {
            latestCaptureScreenShotTimestamp = timeInterval
        }

        if currentServerHealth == SPSHealth.BAD {
            DDLogDebug("SEB Screen Proctoring Controller: Server health is BAD")
            if transmittingState != SPSTransmittingState.waitingForRecovery {
                if transmittingState == SPSTransmittingState.normal {
                    DDLogDebug("SEB Screen Proctoring Controller: Transmitting state was normal, set to waitingForRecovery")
                    transmittingState = SPSTransmittingState.waitingForRecovery
                }
                if transmittingState == SPSTransmittingState.delayForResuming {
                    DDLogDebug("SEB Screen Proctoring Controller: Transmitting state was delayForResuming, set to waitingForRecovery")
                    // Stop random timer for delay to resume sending cached screen shots
                    transmittingState = SPSTransmittingState.waitingForRecovery
                }
                self.setScreenProctoringButtonState(ScreenProctoringButtonStateActiveError)
                // Start repeating timer to check server health on separate endpoint each 15 seconds
                repeatingTimerForHealthCheck = timerForHealthCheck()
                repeatingTimerForHealthCheck?.eventHandler = {
                    // Check server health without sending screen shot
                    DDLogDebug("SEB Screen Proctoring Controller: Check server health")
                    if self.closingSession {
                        self.spsControllerUIDelegate?.updateTransmittingCachedScreenShotsWindow(remainingScreenShots: self.screenShotCache.count, message: nil, operation: NSLocalizedString("Checking server health", comment: ""), totalScreenShots: self.totalNumberOfCachedScreenShotsWhileClosing)
                    }
                    self.checkHealth {
                        if self.closingSession {
                            self.spsControllerUIDelegate?.updateTransmittingCachedScreenShotsWindow(remainingScreenShots: self.screenShotCache.count, message: nil, operation: String.localizedStringWithFormat(NSLocalizedString("Server health %d out of 10", comment: ""), 10-self.currentServerHealth), append: true, totalScreenShots: self.totalNumberOfCachedScreenShotsWhileClosing)
                        }
                        if self.currentServerHealth != SPSHealth.BAD {
                            if !self.closingSession {
//                                self.screenShotTimerQueue.async { [unowned self] in
                                    self.screenShotMaxIntervallTriggered()
//                                }
                            } else {
                                // When closing session, restart sending cached screeen shots
                                self.transmitNextScreenShot()
                            }
                        } else if self.closingSession {
                            self.transmittingDeferredScreenShotsWhileClosingError()
                        }
                    }
                }
                DDLogDebug("SEB Screen Proctoring Controller: Start checking server health every \(timeIntervalForHealthCheck) seconds.")
                repeatingTimerForHealthCheck?.resume()
            } else if self.closingSession {
                // If server healt is bad and we are waiting for recovery, increase the error counter with every deferred screen shot when resending while closing session
                self.transmittingDeferredScreenShotsWhileClosingError()
            }
        }
        
        if transmittingState == SPSTransmittingState.waitingForRecovery && currentServerHealth != SPSHealth.BAD {
            DDLogDebug("SEB Screen Proctoring Controller: Transmitting state is waitingForRecovery and server health not BAD")
            // If waiting for recovery and server health is no longer BAD, then start random delay to resume transmitting cached screen shots
            transmittingState = SPSTransmittingState.delayForResuming
            // Stop timer to check server health on separate endpoint and start random delay of max 3 minutes
            DDLogDebug("SEB Screen Proctoring Controller: Stop server health check repeating timer and start delay for resuming timer.")
            repeatingTimerForHealthCheck?.reset()
            repeatingTimerForHealthCheck = nil
            delayForResumingTimer = DispatchWorkItem { [weak self] in
                DDLogDebug("SEB Screen Proctoring Controller: Delay for resuming timer fired, set transmitting state to normal.")
                self?.transmittingState = SPSTransmittingState.normal
                self?.setScreenProctoringButtonInfoString(String.localizedStringWithFormat(NSLocalizedString("Sending cached screen shots, server health %d out of 10", comment: ""), 10-(self?.currentServerHealth ?? 11)))
                self?.transmitNextScreenShot()
            }
            let randomDelay = Double.random(in: 0...(closingSession ? (currentServerHealth == SPSHealth.GOOD ? maxDelayForResumingTransmitting/3 : maxDelayForResumingTransmitting/2) : maxDelayForResumingTransmitting))
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            let date = Date() + randomDelay
            let waitingUntil = dateFormatter.string(from: date)
            DDLogInfo("SEB Screen Proctoring Controller: Start random delay of \(randomDelay/60) minutes")
            
            if currentServerHealth == SPSHealth.GOOD {
                self.setScreenProctoringButtonState(ScreenProctoringButtonStateActive)
                setScreenProctoringButtonInfoString(String.localizedStringWithFormat(NSLocalizedString("Good server health, waiting until %@ to resume sending cached screen shots", comment: ""), waitingUntil))
            } else {
                self.setScreenProctoringButtonState(ScreenProctoringButtonStateActiveWarning)
                setScreenProctoringButtonInfoString(String.localizedStringWithFormat(NSLocalizedString("Server health %d out of 10, waiting until %@ to resume sending cached screen shots", comment: ""), 10-currentServerHealth, waitingUntil))
            }
            if closingSession {
                spsControllerUIDelegate?.updateTransmittingCachedScreenShotsWindow(remainingScreenShots: screenShotCache.count, message: nil, operation: String.localizedStringWithFormat(NSLocalizedString("Waiting until %@ to resume sending cached screen shots", comment: ""), waitingUntil), append: true, totalScreenShots: totalNumberOfCachedScreenShotsWhileClosing)
            }
            delayForResumingTimerQueue.asyncAfter(deadline:.now() + randomDelay, execute: self.delayForResumingTimer!)
            // After that resume transmitting cached screen shots
        }

        if (currentServerHealth == SPSHealth.GOOD && (transmittingState == SPSTransmittingState.normal || transmittingState == SPSTransmittingState.delayForResuming) ||
            resending && currentServerHealth != SPSHealth.BAD) {
            self.setScreenProctoringButtonState(ScreenProctoringButtonStateActive)
            if (transmittingState == SPSTransmittingState.normal) {
                transmitScreenShot(data: data, metaData: metaData, timeStamp: timeInterval, resending: resending, completion: completion)
            }
            return
        } else {
            // Server health is not good, deferr transmitting screen shot and cache it to the file system
            // if waiting for recovery or in subsequent delay state, don't attempt to transmit those cached screen shots
            if currentServerHealth == SPSHealth.BAD {
                self.setScreenProctoringButtonInfoString(String.localizedStringWithFormat(NSLocalizedString("Server health %d out of 10, deferring sending screen shots", comment: ""), 10-currentServerHealth))
            }
            if !resending {
                DDLogDebug("SEB Screen Proctoring Controller: Server health is not good, deferr transmitting screen shot and cache it to the file system. \(transmittingState == SPSTransmittingState.normal ? "Attempt to transmit cached screen shots with a delay" : "Transmit state is waitingForRecovery or delayForResuming, so don't transmit cached screen shots yet.")")
                deferScreenShotTransmission(data: data, metaData: metaData, timeStamp: timeInterval, transmitNextCachedScreenShot: transmittingState == SPSTransmittingState.normal)
            }
        }
        completion?(false)
    }
    
    private func deferScreenShotTransmission(data: Data, metaData: String, timeStamp: TimeInterval, transmitNextCachedScreenShot: Bool) {
        var transmissionInterval = Int(NSDate().timeIntervalSince1970 - (latestCaptureScreenShotTimestamp ?? 0))
        if transmissionInterval == 0 {
            transmissionInterval = 1
        }
        DDLogDebug("SEB Screen Proctoring Controller: Cache screen shot and defer transmission with an interval of \(transmissionInterval)")
        screenShotCache.cacheScreenShotForSending(data: data, metaData: metaData, timeStamp: timeStamp, transmissionInterval: transmissionInterval)
        if transmitNextCachedScreenShot {
            screenShotCache.transmitNextCachedScreenShot(interval: nil)
        }
    }
    
    public func transmitNextScreenShot() {
        if !screenShotCache.isEmpty {
            let transmissionInterval = closingSession ? (currentServerHealth + 2) * ((screenshotMinInterval ?? 1000)/1000) : nil
            screenShotCache.transmitNextCachedScreenShot(interval: transmissionInterval)
        } else {
            setScreenProctoringButtonInfoString(NSLocalizedString("All cached screenshots transmitted", comment: ""))
            conditionallyCloseSession()
        }
    }

    public func conditionallyCloseSession() {
        if closingSession {
            spsControllerUIDelegate?.closeTransmittingCachedScreenShotsWindow {
                self.setScreenProctoringButtonInfoString(NSLocalizedString("Closing Session", comment: ""))
                let completionHandler = self.closingSessionCompletionHandler
                self.continueClosingSession(completionHandler: completionHandler)
            }
        }
    }
    
    private func transmitScreenShot(data: Data, metaData: String, timeStamp: TimeInterval, resending: Bool, completion: ((_ success: Bool) -> Void)?) {
        DDLogDebug("SEB Screen Proctoring Controller transmitScreenShot, resending: \(resending)")
        guard let baseURL = self.serviceURL, let sessionId = self.sessionId else {
            completion?(false)
            return
        }
        let screenShotResource = SPSScreenShotResource(baseURL: baseURL, endpoint: "/seb-api/v1/session/\(sessionId)/screenshot")
        
        let authorizationString = keysSPS.headerAuthorizationBearer + " " + (self.accessToken ?? "")
        
        let requestHeaders = [keys.headerContentType : keys.contentTypeOctetStream,
                              keys.headerAuthorization : authorizationString,
                              keysSPS.headerTimestamp : String(format: "%.0f", timeStamp * 1000),
                              keysSPS.headerMetaData : metaData.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? ""] //,
//                              keysSPS.headerImageFormat : "png"]
        
        if closingSession {
            let remainingScreenShots = screenShotCache.count
            spsControllerUIDelegate?.updateTransmittingCachedScreenShotsWindow(remainingScreenShots: remainingScreenShots, message: nil, operation: String.localizedStringWithFormat(NSLocalizedString("Transmitting screen shot %d of %d", comment: ""), remainingScreenShots-1, totalNumberOfCachedScreenShotsWhileClosing), totalScreenShots: totalNumberOfCachedScreenShotsWhileClosing)
        }
        
        load(screenShotResource, httpMethod: screenShotResource.httpMethod, body: data, headers: requestHeaders, withCompletion: { (screenShotResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode != nil && statusCode ?? 0 == statusCodes.ok {
                DDLogDebug("SEB Screen Proctoring Controller: Successfully transmitted screen shot to server.")
                if let health = Int((responseHeaders?.first(where: { ($0.key as? String)?.caseInsensitiveCompare(keysSPS.responseHeaderServerHealth) == .orderedSame}))?.value as? String ?? "") {
                    self.currentServerHealth = health
                    DDLogDebug("SEB Screen Proctoring Controller: Current server health is \(10-health) out of 10")
                    self.latestTransmissionTimestamp = NSDate().timeIntervalSince1970
                    if self.closingSession {
                        if self.currentServerHealth == SPSHealth.GOOD {
                            self.setScreenProctoringButtonState(ScreenProctoringButtonStateActive)
                            self.setScreenProctoringButtonInfoString("")
                            self.transmittingDeferredScreenShotsWhileClosingErrorCount = 0
                            self.spsControllerUIDelegate?.allowQuit(false)
                        } else {
                            if self.currentServerHealth == SPSHealth.BAD {
                                self.setScreenProctoringButtonState(ScreenProctoringButtonStateActiveError)
                                self.transmittingDeferredScreenShotsWhileClosingError()
                            } else {
                                self.setScreenProctoringButtonState(ScreenProctoringButtonStateActiveWarning)
                                self.transmittingDeferredScreenShotsWhileClosingErrorCount = 0
                                self.spsControllerUIDelegate?.allowQuit(false)
                            }
                            self.setScreenProctoringButtonInfoString(String.localizedStringWithFormat(NSLocalizedString("Server health %d out of 10, deferring sending screen shots", comment: ""), 10-self.currentServerHealth))
                        }
                    }
                }
                completion?(true)
            } else {
                DDLogError("SEB Screen Proctoring Controller: Could not upload screen shot with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                if self.closingSession {
                    self.transmittingDeferredScreenShotsWhileClosingError()
                    self.spsControllerUIDelegate?.updateTransmittingCachedScreenShotsWindow(remainingScreenShots: self.screenShotCache.count, message: nil, operation: String.localizedStringWithFormat(NSLocalizedString("Transmitting screen shot failed with error: %@", comment: ""), errorResponse?.error ?? "Unspecified."), totalScreenShots: self.totalNumberOfCachedScreenShotsWhileClosing)
                    self.setScreenProctoringButtonState(ScreenProctoringButtonStateActiveError)
                    self.setScreenProctoringButtonInfoString(String.localizedStringWithFormat(NSLocalizedString("Server health %d out of 10, deferring sending screen shots", comment: ""), 10-self.currentServerHealth))
                }
                // Cache screen shot and retry sending it
                self.currentServerHealth = SPSHealth.BAD
                if !resending {
                    self.deferScreenShotTransmission(data: data, metaData: metaData, timeStamp: timeStamp, transmitNextCachedScreenShot: false)
                }
                completion?(false)
                return
            }
        })
    }
    
    private func transmittingDeferredScreenShotsWhileClosingError() {
        transmittingDeferredScreenShotsWhileClosingErrorCount += 1
        if transmittingDeferredScreenShotsWhileClosingErrorCount >= transmittingDeferredScreenShotsWhileClosingMaxErrorCount {
            if self.closingSession {
                self.spsControllerUIDelegate?.allowQuit(true)
            }
        }
    }
    
    private func getScreenShotMinIntervalTimer() -> (RepeatingTimer) {
        let nonRepeatingTimer = RepeatingTimer(timeInterval: TimeInterval((self.screenshotMinInterval ?? 1000)/1000), queue: minIntervalTimerQueue, repeating: false)
        return nonRepeatingTimer
    }
    
    private func getScreenShotMaxIntervalTimer() -> (RepeatingTimer) {
        let nonRepeatingTimer = RepeatingTimer(timeInterval: TimeInterval((self.screenshotMaxInterval ?? 5000)/1000), queue: maxIntervalTimerQueue, repeating: false)
        return nonRepeatingTimer
    }

    private func startMaxIntervalTimer() {
#if DEBUG
        DDLogDebug("SEB Screen Proctoring Controller: startMaxIntervalTimer()")
#endif
        if screenShotMaxIntervalTimer == nil && !self.closingSession {
            screenShotMaxIntervalTimer = getScreenShotMaxIntervalTimer()
            screenShotMaxIntervalTimer?.eventHandler = {
                self.screenShotMaxIntervallTriggered()
            }
            screenShotMaxIntervalTimer?.resume()
        } else {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller startMaxIntervalTimer(): Not proceeding because timer maybe not nil (\(self.screenShotMaxIntervalTimer as Any))\(closingSession ? " or closing session" : "").")
#endif
        }
    }
    
    private func startMinIntervalTimer() {
#if DEBUG
        DDLogDebug("SEB Screen Proctoring Controller: startMinIntervalTimer()")
#endif
        if screenShotMinIntervalTimer == nil && !self.closingSession {
            screenShotMinIntervalTimer = getScreenShotMinIntervalTimer()
            screenShotMinIntervalTimer?.eventHandler = {
                self.screenShotMinIntervallTriggered()
            }
            screenShotMinIntervalTimer?.resume()
        } else {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller startMinIntervalTimer(): Not proceeding because timer maybe not nil (\(self.screenShotMaxIntervalTimer as Any))\(closingSession ? " or closing session" : "").")
#endif
        }
    }
    
    func stopMaxIntervalTimer() {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller stopMaxIntervalTimer()")
#endif
            if screenShotMaxIntervalTimer != nil {
                screenShotMaxIntervalTimer?.reset()
                screenShotMaxIntervalTimer = nil
            }
    }

    func stopMinIntervalTimer() {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller stopMinIntervalTimer()")
#endif
            if screenShotMinIntervalTimer != nil {
                screenShotMinIntervalTimer?.reset()
                screenShotMinIntervalTimer = nil
            }
    }

    private func getTriggerEventString() -> String {
        var triggerEventString = latestTriggerEvent ?? ""
        if !triggerEventString.isEmpty {
            triggerEventString += ". "
        }
        if alphanumericKeyCount > 1 {
            let alphanumericKeysString = "\(alphanumericKeyCount) " + keysSPS.alphanumericKeyString + "s"
            if triggerEventString.contains(keysSPS.alphanumericKeyString.firstUppercased)  {
                triggerEventString = triggerEventString.replacingOccurrences(of: keysSPS.alphanumericKeyString.firstUppercased, with: alphanumericKeysString)
            } else {
                triggerEventString.append(alphanumericKeysString + " pressed.")
            }
            alphanumericKeyCount = 0
        }
        if !keyboardShortcuts.isEmpty {
            if latestTriggerEvent != nil && keyboardShortcuts.count > 0 && latestTriggerEvent!.contains(keyboardShortcuts.last!) {
                // Don't repeat the latest shortcut in the list of shortcuts pressed between two screen shots
                keyboardShortcuts.removeLast()
            }
            if !keyboardShortcuts.isEmpty {
                triggerEventString.append(" Keyboard shortcut\(keyboardShortcuts.count > 1 ? "s" : "") pressed: \(keyboardShortcuts.joined(separator: "/"))")
                keyboardShortcuts.removeAll()
            }
        }
        latestTriggerEvent = nil
        return triggerEventString
    }
    
    private func screenShotMinIntervallTriggered() {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller screenShotMinIntervallTriggered()")
#endif
        if !self.closingSession {
            if self.latestTriggerEvent != nil {
                stopMinIntervalTimer()
                stopMaxIntervalTimer()
                let triggerEventString = getTriggerEventString()
                self.captureScreenShot(triggerMetadata: triggerEventString, timeStamp: self.latestTriggerEventTimestamp)
                self.startMaxIntervalTimer()
                self.startMinIntervalTimer()
            } else {
                self.stopMinIntervalTimer()
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller screenShotMinIntervallTriggered(): No new input trigger event, stop min intervall timer until next input event.")
#endif
            }
        } else {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller screenShotMinIntervallTriggered(): Not proceeding because closing session")
#endif
        }
    }
    
    private func screenShotMaxIntervallTriggered() {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller screenShotMaxIntervallTriggered()")
#endif
        if !self.closingSession {
            self.stopMinIntervalTimer()
            self.stopMaxIntervalTimer()
            let triggerEventString = getTriggerEventString()
            if triggerEventString.isEmpty {
                self.captureScreenShot(triggerMetadata: "Maximum interval of \(String(self.screenshotMaxInterval ?? 5000))ms has been reached.", timeStamp: nil)
            } else {
                self.captureScreenShot(triggerMetadata: triggerEventString, timeStamp: self.latestTriggerEventTimestamp)
            }
            if !self.closingSession {
                self.startMaxIntervalTimer()
                self.startMinIntervalTimer()
            }
        } else {
#if DEBUG
            DDLogDebug("SEB Screen Proctoring Controller screenShotMaxIntervallTriggered(): Not proceeding because closing session")
#endif
        }
    }
    
    private func timerForHealthCheck() -> (RepeatingTimer) {
        let repeatingTimer = RepeatingTimer(timeInterval: TimeInterval(timeIntervalForHealthCheck), queue: DispatchQueue(label: keysSPS.dispatchQueueLabel+".healthCheck", qos: .utility))
        return repeatingTimer
    }
    
    func startDeferredTransmissionTimer(_ interval: Int) {
        if self.screenShotDeferredTransmissionIntervalTimer == nil {
            DDLogDebug("SEB Screen Proctoring Controller startDeferredTransmissionTimer")
            if closingSession {
                spsControllerUIDelegate?.updateTransmittingCachedScreenShotsWindow(remainingScreenShots: screenShotCache.count, message: nil, operation: String.localizedStringWithFormat(NSLocalizedString("Waiting %d seconds", comment: ""), interval), append: true, totalScreenShots: totalNumberOfCachedScreenShotsWhileClosing)
            }
            screenShotDeferredTransmissionIntervalTimer = RepeatingTimer(timeInterval: TimeInterval(interval), queue: minIntervalTimerQueue, repeating: false)
            screenShotDeferredTransmissionIntervalTimer?.eventHandler = {
                self.screenShotDeferredTransmissionIntervallTriggered()
            }
            screenShotDeferredTransmissionIntervalTimer?.resume()
            
        } else {
            DDLogDebug("SEB Screen Proctoring Controller startDeferredTransmissionTimer: timer was still running")
            stopDeferredTransmissionIntervalTimer()
            DDLogDebug("SEB Screen Proctoring Controller try to call startDeferredTransmissionTimer again.")
            self.startDeferredTransmissionTimer(interval)
        }
    }
    
    func stopDeferredTransmissionIntervalTimer() {
        if self.screenShotDeferredTransmissionIntervalTimer != nil {
            self.screenShotDeferredTransmissionIntervalTimer?.reset()
            self.screenShotDeferredTransmissionIntervalTimer = nil
        }
    }


    private func screenShotDeferredTransmissionIntervallTriggered() {
#if DEBUG
        DDLogDebug("SEB Screen Proctoring Controller: screenShotDeferredTransmissionIntervallTriggered! Stop timer and transmit the screen shot.")
#endif
        stopDeferredTransmissionIntervalTimer()
#if DEBUG
        DDLogDebug("SEB Screen Proctoring Controller: screenShotDeferredTransmissionIntervallTriggered timer stopped, now transmit the screen shot.")
#endif
        transmitNextScreenShot()
    }
    
    @objc func closeSession(completionHandler: @escaping () -> Void) {
        DDLogInfo("SEB Screen Proctoring Controller: Closing Session")
        closingSessionCompletionHandler = completionHandler
        closingSession = true
        stopMinIntervalTimer()
        stopMaxIntervalTimer()
        if self.screenShotCache.isEmpty {
            DDLogInfo("SEB Screen Proctoring Controller: There are no cached screen shots, continue closing session.")
            spsControllerUIDelegate?.closeTransmittingCachedScreenShotsWindow {
                self.continueClosingSession(completionHandler: completionHandler)
            }
        } else {
            numberOfCachedScreenShotsWhileClosing = self.screenShotCache.count
            DDLogInfo("SEB Screen Proctoring Controller: There are \(numberOfCachedScreenShotsWhileClosing) cached screen shots which need to be transmitted to the server before session can be closed.")
            spsControllerUIDelegate?.showTransmittingCachedScreenShotsWindow(remainingScreenShots: max(numberOfCachedScreenShotsWhileClosing, self.screenShotCache.count), message: nil, operation: screenProctoringButtonInfoString)
            self.spsControllerUIDelegate?.allowQuit(false)
            self.transmitNextScreenShot()
        }
    }
    
    private func continueClosingSession(completionHandler: (() -> Void)?) {
        closingSession = false
        closingSessionCompletionHandler = nil
        transmittingDeferredScreenShotsWhileClosingErrorCount = 0
        metadataCollector.stopMonitoringEvents()
        screenShotCache.conditionallyRemoveCacheDirectory()
        _screenShotCache = nil
        self.setScreenProctoringButtonState(ScreenProctoringButtonStateInactive)
        guard let baseURL = self.serviceURL, let sessionId = self.sessionId else {
            completionHandler?()
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
            completionHandler?()
        })
    }
    
    private func checkHealth(completionHandler: @escaping () -> Void) {
        guard let baseURL = self.serviceURL else {
            completionHandler()
            return
        }
        let healthCheckResource = SPSHealthCheckResource(baseURL: baseURL, endpoint: "/health")
        
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded]
        
        load(healthCheckResource, httpMethod: healthCheckResource.httpMethod, body: Data(), headers: requestHeaders, withCompletion: { (healthCheckResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode != nil || statusCode ?? 0 == statusCodes.ok {
                if let health = Int((responseHeaders?.first(where: { ($0.key as? String)?.caseInsensitiveCompare(keysSPS.responseHeaderServerHealth) == .orderedSame}))?.value as? String ?? "") {
                    self.currentServerHealth = health
                    DDLogDebug("SEB Screen Proctoring Controller checkHealth: Current server health: \(10-self.currentServerHealth) out of 10.")
                }
            } else {
                DDLogError("SEB Screen Proctoring Controller: Could not get server health with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
            }
            completionHandler()
        })
    }
    
    private func didFail(error: NSError, fatal: Bool) {
        self.setScreenProctoringButtonState(ScreenProctoringButtonStateInactiveError)
        if !cancelAllRequests {
//            self.delegate?.didFail(error: error, fatal: fatal)
        }
    }

#if os(iOS)
    @objc public func receivedUIEvent(_ event: UIEvent?, view: UIView) {
        metadataCollector.receivedUIEvent(event, view: view)
    }
    
//    @objc public func touchesChange(_ change:UIEventChange, touches: Set<UITouch>, with event: UIEvent?) {
//        metadataCollector.touchesChange(change, touches: touches, with: event)
//    }
//
//    @objc public func pressesChange(_ change:UIEventChange, presses: Set<UIPress>, with event: UIPressesEvent?) {
//        metadataCollector.pressesChange(change, presses: presses, with: event)
//    }
#endif

        public func collectedTriggerEvent(eventData:String) {
            if latestTriggerEvent != nil {
                latestTriggerEvent = "\(latestTriggerEvent!) / \(eventData)"
            } else {
                latestTriggerEvent = eventData
            }
            latestTriggerEventTimestamp = NSDate().timeIntervalSince1970
            if !closingSession {
                if self.screenShotMinIntervalTimer == nil {
    #if DEBUG
                    DDLogDebug("SEB Screen Proctoring Controller collectedTriggerEvent(eventData): Minimum interval has passed, trigger screen shot immediately")
    #endif
                    self.screenShotMinIntervallTriggered()
                } else {
    #if DEBUG
                    DDLogDebug("SEB Screen Proctoring Controller collectedTriggerEvent(eventData): Minimum interval timer is running, not necessary to trigger it.")
    #endif
                }
            }
        }

    public func collectedAlphanumericKeyEvent() {
        alphanumericKeyCount += 1
    }
    
    public func collectedKeyboardShortcutEvent(_ eventData: String) {
        keyboardShortcuts.append(eventData)
    }
    
    // Update UI

    func setScreenProctoringButtonState(_ state: ScreenProctoringButtonStates) {
        if screenProctoringButtonState != state {
            var newState = state
            if !indicateHealthAndCaching {
                switch state {
                case ScreenProctoringButtonStateActiveWarning:
                    newState = ScreenProctoringButtonStateActive
                case ScreenProctoringButtonStateActiveError:
                    newState = ScreenProctoringButtonStateActive
                default:
                    newState = state
                }
            }
            screenProctoringButtonState = newState
            spsControllerUIDelegate?.setScreenProctoringButtonState(newState)
        }
    }
    
    func setScreenProctoringButtonInfoString(_ string: String) {
        DDLogInfo("SEB Screen Proctoring Controller state changed: \(string)")
        if indicateHealthAndCaching && screenProctoringButtonInfoString != string {
            screenProctoringButtonInfoString = string
            spsControllerUIDelegate?.setScreenProctoringButtonInfoString(string)
        }
    }

}
