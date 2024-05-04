//
//  SEBScreenProctoringController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 09.04.24.
//

import Foundation
import CocoaLumberjackSwift

fileprivate struct keysSPS {
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
}

@objc public protocol ScreenProctoringDelegate: AnyObject {
    
    func updateStatus(string: String?, append: Bool)
}

@objc public protocol SPSControllerUIDelegate: AnyObject {
    
    func updateStatus(string: String?, append: Bool)
}

@objc public class SEBScreenProctoringController : NSObject, URLSessionDelegate {
    
    @objc weak public var delegate: ScreenProctoringDelegate?
    @objc weak public var spsControllerUIDelegate: SPSControllerUIDelegate?

    fileprivate var session: URLSession?
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

    fileprivate var accessToken: String?
    fileprivate var gettingAccessToken = false
    
    private var serviceURL: URL?
    private var clientId: String?
    private var clientSecret: String?
    private var groupId: String?
    private var sessionId: String?
    private var instructionConfirm: String?
    
    private var screenshotMinInterval: Int?
    private var screenshotMaxInterval: Int?
    private var imageFormat: Int?
    private var imageQuantization: Int?
    private var imageDownscale: Double?
    
    private var metadataURLEnabled: Bool?
    private var metadataWindowTitleEnabled: Bool?
    private var metadataActiveAppEnabled: Bool?
    
    private var maxRequestAttemps = 5
    private var fallbackAttemptInterval = 2000.0
    private var fallbackTimeout = 30000.0
    private var cancelAllRequests = false
    
    private var currentServerHealth = 0
    
    private var screenShotTimer: RepeatingTimer?
//    private var screenShotDispatchQueue = DispatchQueue.global(qos: .utility) //DispatchQueue(label: "org.safeexambrowser.SEB.ScreenShot", qos: .utility)

    @objc public override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
        DDLogInfo("SEB Screen Proctoring Controller: Initialize with max. request attempts \(self.maxRequestAttemps), fallback attempt interval \(self.fallbackAttemptInterval) and fallback timeout \(self.fallbackTimeout).")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = self.fallbackTimeout
        
        self.screenshotMinInterval = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringScreenshotMinInterval")
        self.screenshotMaxInterval = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringScreenshotMaxInterval")
        self.imageFormat = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringImageFormat")
        self.imageQuantization = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_screenProctoringImageQuantization")
        self.imageDownscale = UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_screenProctoringImageDownscale")
        if self.imageDownscale == 0 {
            self.imageDownscale = 1
        }
        
        self.metadataURLEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringMetadataURLEnabled")
        self.metadataWindowTitleEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringMetadataWindowTitleEnabled")
        self.metadataActiveAppEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_screenProctoringMetadataActiveAppEnabled")
        
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
//                if let sampleScreenShotURL = Bundle.main.url(forResource: "SampleScreenshotRGB248", withExtension: "png") {
//                    if let screenShotData = try? Data(contentsOf:  sampleScreenShotURL) {
//                        self.sendScreenShot(data: screenShotData, metaData: "")
//                    }
//                }
            }
        }
        
        if method == keysSPS.screenProctoringMethodLeave {
            closeSession {
                // Session was closed
            }
        }
    }
}


public extension SEBScreenProctoringController {

    fileprivate func load<Resource: ApiResource>(_ resource: Resource, httpMethod: String, body: Data, headers: [AnyHashable: Any]?, withCompletion resourceLoadCompletion: @escaping (Resource.Model?, Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
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

    fileprivate func loadWithFallback<Resource: ApiResource>(_ resource: Resource, httpMethod: String, body: Data, headers: [AnyHashable: Any]?, fallbackAttempt: Int, withCompletion resourceLoadCompletion: @escaping (Resource.Model?, Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        if !cancelAllRequests {
            load(resource, httpMethod: httpMethod, body: body, headers: headers, withCompletion: { (response, statusCode, errorResponse, responseHeaders, attempt) in
                DDLogVerbose("SEB Screen Proctoring Controller: Load with fallback returned with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                if statusCode == nil || statusCode ?? 0 >= statusCodes.notSuccessfullRange {
                    DDLogError("SEB Screen Proctoring Controller: Loading resource \(resource) with fallback not successful, status code: \(String(describing: statusCode)), attempt: \(fallbackAttempt).")
                    // Error: Try to load the resource again if maxRequestAttemps weren't reached yet
                    let currentAttempt = fallbackAttempt+1
                    if currentAttempt <= self.maxRequestAttemps {
//                        self.serverControllerUIDelegate?.updateStatus(string: NSLocalizedString("Failed, retrying...", comment: ""), append: true)
                        DispatchQueue.main.asyncAfter(deadline: (.now() + self.fallbackAttemptInterval)) {
                            // and try to perform the request again
                            self.loadWithFallback(resource, httpMethod: httpMethod, body: body, headers: headers, fallbackAttempt: currentAttempt, withCompletion: resourceLoadCompletion)
                            return
                        }
                        return
                    } //if maxRequestAttemps reached, report failure to load resource
                    DDLogError("SEB Screen Proctoring Controller: Load with fallback max. request attempts reached, aborting.")
                    self.spsControllerUIDelegate?.updateStatus(string: NSLocalizedString("Failed", comment: ""), append: false)
                }
                if !self.cancelAllRequests {
                    resourceLoadCompletion(response, statusCode, errorResponse, responseHeaders, fallbackAttempt)
                }
            })
        }
    }

    fileprivate func getServerAccessToken(completionHandler: @escaping () -> Void) {
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
                    self.spsControllerUIDelegate?.updateStatus(string: NSLocalizedString("Failed", comment: ""), append: false)
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
    
    fileprivate func startScreenProctoring() {
        let timer = RepeatingTimer(timeInterval: TimeInterval((self.screenshotMaxInterval ?? 5000)/1000), queue: DispatchQueue(label: "org.safeexambrowser.SEB.ScreenShot", qos: .utility))
        let imageScale = 1/(self.imageDownscale ?? 1)
        timer.eventHandler = {
            if let screenShotData = self.takeScreenShot(scale: imageScale) {
                self.sendScreenShot(data: screenShotData, metaData: "")
            }
        }
        screenShotTimer = timer
        screenShotTimer?.resume()
    }
    
    fileprivate func takeScreenShot(scale: Double) -> Data? {
        let displayID = CGMainDisplayID()
        guard var imageRef = CGDisplayCreateImage(displayID) else {
            return nil
        }
        if scale != 1 {
            guard let scaledImage = imageRef.resize(size: CGSize(width: scale, height: scale)) else {
                return nil
            }
            imageRef = scaledImage
        }
        let pngData = imageRef.pngData()
        return pngData
    }
    
    fileprivate func sendScreenShot(data: Data, metaData: String) {
        guard let baseURL = self.serviceURL, let sessionId = self.sessionId else {
            return
        }
        let screenShotResource = SPSScreenShotResource(baseURL: baseURL, endpoint: "/seb-api/v1/session/\(sessionId)/screenshot")
        
        let authorizationString = keysSPS.headerAuthorizationBearer + " " + (self.accessToken ?? "")
        let requestHeaders = [keys.headerContentType : keys.contentTypeOctetStream,
                              keys.headerAuthorization : authorizationString,
                              keysSPS.headerTimestamp : String(format: "%.0f", NSDate().timeIntervalSince1970 * 1000)] //,
//                              keysSPS.headerImageFormat : "png"]
        
        load(screenShotResource, httpMethod: screenShotResource.httpMethod, body: data, headers: requestHeaders, withCompletion: { (screenShotResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode != nil || statusCode ?? 0 == statusCodes.ok {
                if let health = Int((responseHeaders?.first(where: { ($0.key as? String)?.caseInsensitiveCompare(keysSPS.responseHeaderServerHealth) == .orderedSame}))?.value as? String ?? "") {
                    self.currentServerHealth = health
                }
            } else {
                DDLogError("SEB Screen Proctoring Controller: Could not upload screen shot with status code \(String(describing: statusCode)), error response \(String(describing: errorResponse)).")
                // ToDo: Cache screen shot and retry sending it
                return
            }
            if !self.cancelAllRequests {
//                completionHandler()
            }
        })
    }
    
    @objc func closeSession(completionHandler: @escaping () -> Void) {
        screenShotTimer = nil
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
    
    fileprivate func checkHealth(completionHandler: @escaping () -> Void) {
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
    
    fileprivate func didFail(error: NSError, fatal: Bool) {
        if !cancelAllRequests {
//            self.delegate?.didFail(error: error, fatal: fatal)
        }
    }

}

import CoreGraphics
import CoreImage
import ImageIO

extension CIImage {
  
  public func convertToCGImage() -> CGImage? {
    let context = CIContext(options: nil)
    if let cgImage = context.createCGImage(self, from: self.extent) {
      return cgImage
    }
    return nil
  }
  
  public func data() -> Data? {
    convertToCGImage()?.pngData()
  }
}

extension CGImage {
  
  public func pngData() -> Data? {
    let cfdata: CFMutableData = CFDataCreateMutable(nil, 0)
    if let destination = CGImageDestinationCreateWithData(cfdata, kUTTypePNG as CFString, 1, nil) {
      CGImageDestinationAddImage(destination, self, nil)
      if CGImageDestinationFinalize(destination) {
        return cfdata as Data
      }
    }
    
    return nil
  }
}

extension CGImage {
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel


        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}

