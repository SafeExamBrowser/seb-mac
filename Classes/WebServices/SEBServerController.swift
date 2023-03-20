//
//  SEBServerController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.10.18.
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

import Foundation

@objc public protocol SEBServerControllerDelegate: AnyObject {
    func didEstablishSEBServerConnection()
    func didSelectExam(_ examId: String, url: String)
    func closeServerView(completion: @escaping () -> ())
    func startBatteryMonitoring(delegate: Any)
    func loginToExam(_ url: String)
    func didReceiveMoodleUserId(_ moodleUserId: String)
    func reconfigureWithServerExamConfig(_ configData: Data)
    func executeSEBInstruction(_ sebInstruction: SEBInstruction)
    func didCloseSEBServerConnectionRestart(_ restart: Bool)
    func didFail(error: NSError, fatal: Bool)
}

@objc public protocol ServerControllerUIDelegate: AnyObject {
    
    func updateExamList()
    func updateStatus(string: String?, append: Bool)
}

public class PendingServerRequest : NSObject {
    public var pendingRequest: AnyObject?
    
    public init(request: AnyObject) {
        pendingRequest = request
    }
}

@objc public class SEBServerController : NSObject, SEBBatteryControllerDelegate {
    
    fileprivate var session: URLSession
    private let pendingRequestsQueue = dispatch_queue_concurrent_t.init(label: UUID().uuidString)

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
    
    fileprivate var serverAPI: SEB_Endpoints?
    fileprivate var accessToken: String?
    fileprivate var gettingAccessToken = false
    fileprivate var connectionToken: String?
    fileprivate var exams: [Exam]?
    fileprivate var selectedExamId = ""
    @objc public var clientUserId = ""
    @objc public var osName = ""
    @objc public var sebVersion = ""
    @objc public var machineName = ""
    fileprivate var selectedExamURL = ""
    fileprivate var pingNumber: Int64 = 0
    fileprivate var notificationNumber: Int64 = 0

    @objc weak public var delegate: SEBServerControllerDelegate?
    @objc weak public var serverControllerUIDelegate: ServerControllerUIDelegate?

    private let baseURL: URL
    private let institution: String
    private let exam: String?
    private let username: String
    private let password: String
    private let discoveryEndpoint: String
    private let pingInterval: Double
    @objc public var examList: [ExamObject]?
    private var pingTimer: Timer?
    @objc public var pingInstruction: String?
    private var logSendigDispatchQueue = DispatchQueue(label: "org.safeexambrowser.SEB.LogSending", qos: .background)
    private var logQueue: Queue<LogEvent> = Queue()
    private var sendingLogEvent = false
    private var maxRequestAttemps: Int
    private var fallbackAttemptInterval: Double
    private var fallbackTimeout: Double
    private var cancelAllRequests = false

    struct Queue<T> {
         var list = [T]()
        
        mutating func enqueue(_ element: T) {
              list.append(element)
        }
        mutating func dequeue() -> T? {
             if !list.isEmpty {
               return list.removeFirst()
             } else {
               return nil
             }
        }
        var isEmpty: Bool {
             return list.isEmpty
        }
    }

    struct LogEvent {
        var logLevel: String
        var timestamp: String
        var numericValue: Double
        var message: String
        
        init(logLevel: String, timestamp: String, numericValue: Double, message: String) {
            self.logLevel = logLevel
            self.timestamp = timestamp
            self.numericValue = numericValue
            self.message = message
        }
    }
    
    @objc public init(baseURL: URL, institution:  String, exam: String?, username: String, password: String, discoveryEndpoint: String, pingInterval: Double, delegate: SEBServerControllerDelegate) {
        self.baseURL = baseURL
        self.institution = institution
        self.exam = exam
        self.username = username
        self.password = password
        self.discoveryEndpoint = discoveryEndpoint
        self.pingInterval = pingInterval
        self.delegate = delegate
        self.maxRequestAttemps = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_sebServerFallbackAttempts")
        self.fallbackAttemptInterval = UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_sebServerFallbackAttemptInterval") / 1000
        self.fallbackTimeout = UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_sebServerFallbackTimeout") / 1000
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = fallbackTimeout
        self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
    }
}

extension Array where Element == Endpoint {
    func endpoint(name: String) -> Endpoint? {
        return self.first(where: { $0.name == name })
    }
}

public extension SEBServerController {

    fileprivate func load<Resource: ApiResource>(_ resource: Resource, httpMethod: String, body: String, headers: [AnyHashable: Any]?, withCompletion resourceLoadCompletion: @escaping (Resource.Model?, Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        if !cancelAllRequests {
            let request = ApiRequest(resource: resource)
            let pendingRequest = PendingServerRequest(request: request)
            pendingRequests.append(pendingRequest)
            request.load(httpMethod: httpMethod, body: body, headers: headers, session: self.session, attempt: 0, completion: { [self] (response, statusCode, errorResponse, responseHeaders, attempt) in
                self.pendingRequests = self.pendingRequests.filter { $0 != pendingRequest }
                if statusCode == statusCodes.unauthorized && errorResponse?.error == errors.invalidToken {
                    // Error: Unauthorized and token expired, get new token if not yet exceeded configured max attempts
                    if attempt <= self.maxRequestAttemps && !cancelAllRequests {
                        DispatchQueue.main.asyncAfter(deadline: (.now() + fallbackAttemptInterval)) {
                            self.getServerAccessToken {
                                // and try to perform the request again
                                request.load(httpMethod: httpMethod, body: body, headers: headers, session: self.session, attempt: attempt, completion: resourceLoadCompletion)
                            }
                        }
                    } else {
                        let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("Repeating Error: Invalid Token", comment: ""),
                            NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your server administrator", comment: ""),
                                       NSDebugDescriptionErrorKey : "Server reported Invalid Token for maxRequestAttempts"]
                        let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
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

    fileprivate func loadWithFallback<Resource: ApiResource>(_ resource: Resource, httpMethod: String, body: String, headers: [AnyHashable: Any]?, fallbackAttempt: Int, withCompletion resourceLoadCompletion: @escaping (Resource.Model?, Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        if !cancelAllRequests {
            load(resource, httpMethod: httpMethod, body: body, headers: headers, withCompletion: { (response, statusCode, errorResponse, responseHeaders, attempt) in
                if statusCode == nil || statusCode ?? 0 >= statusCodes.notSuccessfullRange {
                    DDLogError("Loading resource \(resource) not successful, status code: \(String(describing: statusCode)))")
                    // Error: Try to load the resource again if maxRequestAttemps weren't reached yet
                    let currentAttempt = fallbackAttempt+1
                    if currentAttempt <= self.maxRequestAttemps {
                        self.serverControllerUIDelegate?.updateStatus(string: NSLocalizedString("Failed, retrying...", comment: ""), append: true)
                        DispatchQueue.main.asyncAfter(deadline: (.now() + self.fallbackAttemptInterval)) {
                            // and try to perform the request again
                            self.loadWithFallback(resource, httpMethod: httpMethod, body: body, headers: headers, fallbackAttempt: currentAttempt, withCompletion: resourceLoadCompletion)
                            return
                        }
                        return
                    } //if maxRequestAttemps reached, report failure to load resource
                    self.serverControllerUIDelegate?.updateStatus(string: NSLocalizedString("Failed", comment: ""), append: false)
                }
                if !self.cancelAllRequests {
                    resourceLoadCompletion(response, statusCode, errorResponse, responseHeaders, fallbackAttempt)
                }
            })
        }
    }

    @objc func getServerAPI() {
        let discoveryResource = DiscoveryResource(baseURL: self.baseURL, discoveryEndpoint: self.discoveryEndpoint)

        let discoveryRequest = ApiRequest(resource: discoveryResource)
        pendingRequests.append(PendingServerRequest(request: discoveryRequest))
        // ToDo: Implement timeout and sebServerFallback
        discoveryRequest.load(self.session) { (discoveryResponse) in
            // ToDo: Does this if let check work, response seems to be a double optional?
            if let discovery = discoveryResponse, let serverAPIEndpoints = discovery?.api_versions[0].endpoints {
                var sebEndpoints = SEB_Endpoints()
                            
                sebEndpoints.accessToken.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.accessToken.name)
                sebEndpoints.handshake.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.handshake.name)
                sebEndpoints.configuration.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.configuration.name)
                sebEndpoints.ping.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.ping.name)
                sebEndpoints.log.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.log.name)

                self.serverAPI = sebEndpoints
                
                self.getAccessToken()
            } else {
                let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("Cannot Get Server API", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your server administrator", comment: ""),
                               NSDebugDescriptionErrorKey : "Server didn't return \(discoveryResponse == nil ? "discovery response" : "API endpoints")."]
                let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
                self.didFail(error: error, fatal: true)
            }
        }
    }
    
    func getAccessToken() {
        getServerAccessToken {
            self.getExamList()
        }
    }
    
    fileprivate func getServerAccessToken(completionHandler: @escaping () -> Void) {
        if !gettingAccessToken {
            gettingAccessToken = true
            let accessTokenResource = AccessTokenResource(baseURL: self.baseURL, endpoint: (serverAPI?.accessToken.endpoint?.location)!)
            
            let authorizationString = (serverAPI?.accessToken.endpoint?.authorization ?? "") + " " + (username + ":" + password).data(using: .utf8)!.base64EncodedString()
            let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                                  keys.headerAuthorization : authorizationString]
            
            load(accessTokenResource, httpMethod: accessTokenResource.httpMethod, body: accessTokenResource.body, headers: requestHeaders, withCompletion: { (accessTokenResponse, statusCode, errorResponse, responseHeaders, attempt) in
                self.gettingAccessToken = false
                if let accessToken = accessTokenResponse, let tokenString = accessToken?.access_token {
                    self.accessToken = tokenString
                } else {
                    self.serverControllerUIDelegate?.updateStatus(string: NSLocalizedString("Failed", comment: ""), append: false)
                    let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("Cannot access server because of error: ", comment: "") + (errorResponse?.error ?? "unspecified"),
                        NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your exam administrator", comment: ""),
                                   NSDebugDescriptionErrorKey : "Server didn't return \(accessTokenResponse == nil ? "access token response" : "access token") because of error \(errorResponse?.error ?? "Unspecified"), details: \(errorResponse?.error_description ?? "n/a")."]
                    let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
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
    
    func getExamList() {
        var handshakeResource = HandshakeResource(baseURL: self.baseURL, endpoint: (serverAPI?.handshake.endpoint?.location)!)
        let environmentInfo = keys.clientId + "=" + (clientUserId) + "&" + keys.sebOSName + "=" + osName
        let clientInfo = keys.sebVersion + "=" + sebVersion + "&" + keys.sebMachineName + "=" + machineName
        handshakeResource.body = keys.institutionId + "=" + institution + (exam == nil ? "" : ("&" + keys.examId + "=" + exam!)) + "&" + environmentInfo + "&" + clientInfo

        // ToDo: Implement timeout and sebServerFallback
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                              keys.headerAuthorization : authorizationString]
        loadWithFallback(handshakeResource, httpMethod: handshakeResource.httpMethod, body: handshakeResource.body, headers: requestHeaders, fallbackAttempt: 0, withCompletion: { (handshakeResponse, statusCode, errorResponse, responseHeaders, attempt) in
            var connectionTokenSuccess = false
            if statusCode ?? statusCodes.badRequest < statusCodes.notSuccessfullRange {
                let connectionToken = (responseHeaders?.first(where: { ($0.key as? String)?.caseInsensitiveCompare(keys.sebConnectionToken) == .orderedSame}))?.value
                if let connectionTokenString = connectionToken {
                    connectionTokenSuccess = true
                    self.connectionToken = connectionTokenString as? String
                    
                    self.startPingTimer()
                    self.startBatteryMonitoring()
                    
                    if let exams = handshakeResponse  {
                        self.exams = exams
                        self.examList = [];

                        if (exams != nil) {
                            for exam in exams! {
                                self.examList?.append(ExamObject(exam))
                            }
                        }
                        self.serverControllerUIDelegate?.updateExamList()
                        if self.exam != nil {
                            self.delegate?.didSelectExam((exams?.first!.examId)!, url: (exams?.first!.url)!)
                        }
                        return
                    }
                }
            }
            let userInfo = [NSLocalizedDescriptionKey : connectionTokenSuccess ?
                            NSLocalizedString("Cannot Establish Server Connection", comment: "") :
                                NSLocalizedString("Cannot Get Exam List", comment: ""),
                NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your server/exam administrator (Server error: ", comment: "") + (errorResponse?.error ?? "Unspecified") + ").",
                           NSDebugDescriptionErrorKey : "Server didn't return \(connectionTokenSuccess ? "connection token" : "exams"), server error: \(errorResponse?.error ?? "Unspecified"), details: \(errorResponse?.error_description ?? "n/a")"]
            let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
            self.didFail(error: error, fatal: true)

        })
    }
    
    
    private func startPingTimer() {
        if self.pingTimer == nil {
            let timer = Timer.scheduledTimer(timeInterval: self.pingInterval, target: self, selector: #selector(self.sendPing), userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: .common)
            self.pingTimer = timer
        }
    }
    
    func stopPingTimer() {
        if pingTimer != nil {
            pingTimer?.invalidate()
            pingTimer = nil
        }
    }
    
    
    private func startBatteryMonitoring() {
        self.delegate?.startBatteryMonitoring(delegate: self)
    }
    
    func updateBatteryLevel(_ batteryLevel: Double, infoString: String) {
        sendBatteryEvent(numericValue: batteryLevel, message: infoString)
    }
    
    func setPowerConnected(_ powerConnected: Bool, warningLevel batteryWarningLevel: SEBLowBatteryWarningLevel) {
        // Currently reporting low battery warning levels to SEB Server is not supported
    }
    

    @objc func examSelected(_ examId: String, url: String) {
        selectedExamId = examId
        selectedExamURL = url
        getExamConfig()
    }
    
    
    func getExamConfig() {
        self.serverControllerUIDelegate?.updateStatus(string: NSLocalizedString("Getting Exam Config...", comment: ""), append: false)
        let examConfigResource = ExamConfigResource(baseURL: self.baseURL, endpoint: (serverAPI?.configuration.endpoint?.location)!, queryParameters: [keys.examId + "=" + (selectedExamId)])
        
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerAuthorization : authorizationString,
                              keys.sebConnectionToken : connectionToken!]
        loadWithFallback(examConfigResource, httpMethod: examConfigResource.httpMethod, body: examConfigResource.body, headers: requestHeaders, fallbackAttempt: 0, withCompletion: { (examConfigResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode ?? statusCodes.badRequest < statusCodes.notSuccessfullRange, let config = examConfigResponse  {
                self.delegate?.closeServerView(completion: {
                    self.delegate?.reconfigureWithServerExamConfig(config ?? Data())
                })
            } else {
                let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("Cannot Get Exam Config", comment: ""),
                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString("Contact your server/exam administrator (Server error: ", comment: "") + (errorResponse?.error ?? "Unspecified") + ").",
                               NSDebugDescriptionErrorKey : "Server didn't return exam configuration, server error: \(errorResponse?.error ?? "Unspecified"), details: \(errorResponse?.error_description ?? "n/a")"]
                let error = NSError(domain: sebErrorDomain, code: Int(SEBErrorGettingConnectionTokenFailed), userInfo: userInfo)
                self.didFail(error: error, fatal: true)
            }
        })
    }
    
    
    @objc func loginToExam() {
        delegate?.loginToExam(selectedExamURL)
    }


    @objc func loginToExamAborted(completion: @escaping (Bool) -> Void) {
        quitSession(restart: false, completion: completion)
    }
    
    
    @objc func getMoodleUserId(moodleSession: String, url: URL, endpoint: String) {
        let moodleUserIdResource = MoodleUserIdResource(baseURL: url, endpoint: endpoint)

        let requestHeaders = ["Cookie" : "MoodleSession=\(moodleSession)"]
        loadWithFallback(moodleUserIdResource, httpMethod: moodleUserIdResource.httpMethod, body: "", headers: requestHeaders, fallbackAttempt: 0, withCompletion: { (moodleUserIdResponse, statusCode, errorResponse, responseHeaders, attempt) in
            if statusCode == 200 && moodleUserIdResponse != nil {
                guard let moodleUserId = String(data: moodleUserIdResponse!!, encoding: .utf8) else {
//                    DDLogDebug("No valid Moodle user ID found")
                    return
                }
                if moodleUserId != "0" {
                    self.delegate?.didReceiveMoodleUserId(moodleUserId)
                }
            }
        })
    }
    
    
    @objc func startMonitoring(userSessionId: String) {
        var handshakeCloseResource = HandshakeCloseResource(baseURL: self.baseURL, endpoint: (serverAPI?.handshake.endpoint?.location)!)
        handshakeCloseResource.body = keys.examId + "=" + selectedExamId + "&" + keys.sebUserSessionId + "=" + userSessionId

        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                              keys.headerAuthorization : authorizationString,
                              keys.sebConnectionToken : connectionToken!]
        loadWithFallback(handshakeCloseResource, httpMethod: handshakeCloseResource.httpMethod, body: handshakeCloseResource.body, headers: requestHeaders, fallbackAttempt: 0, withCompletion: { (handshakeCloseResponse, statusCode, errorResponse, responseHeaders, attempt) in
//            if handshakeCloseResponse != nil  {
//                let responseBody = String(data: handshakeCloseResponse!, encoding: .utf8)
//                DDLogVerbose(responseBody as Any)
//            }
            self.delegate?.didEstablishSEBServerConnection()
        })
    }
    
    
    @objc func sendPing() {
        if connectionToken != nil {
            var pingResource = PingResource(baseURL: self.baseURL, endpoint: (serverAPI?.ping.endpoint?.location)!)
            pingNumber += 1
            pingResource.body = keys.timestamp + "=" + String(format: "%.0f", NSDate().timeIntervalSince1970 * 1000)
                + "&" + keys.pingNumber + "=" + String(pingNumber)
                + (pingInstruction == nil ? "" : "&" + keys.pingInstructionConfirm + "=" + pingInstruction!)
            
            let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
            let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                                  keys.headerAuthorization : authorizationString,
                                  keys.sebConnectionToken : connectionToken!]
            load(pingResource, httpMethod: pingResource.httpMethod, body: pingResource.body, headers: requestHeaders, withCompletion: { (pingResponse, statusCode, errorResponse, responseHeaders, attempt) in
                self.pingInstruction = nil
                guard let ping = pingResponse else {
                    return
                }
                if (ping != nil) {
                    self.delegate?.executeSEBInstruction(SEBInstruction(ping!))
                }
            })
        }
    }
    
    
    fileprivate func sendNotification(_ type: String, timestamp: String?, numericValue: Double, text: String?, withCompletion loadCompletion: @escaping (Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        if serverAPI != nil && connectionToken != nil {
            let timestampString = timestamp ?? String(format: "%.0f", NSDate().timeIntervalSince1970 * 1000)
            var logResource = LogResource(baseURL: self.baseURL, endpoint: (serverAPI?.log.endpoint?.location)!)
            var logJSON: [String : Any]
            if let notificationText = text {
                logJSON = [ keys.logType : type, keys.timestamp : timestampString, keys.logNumericValue : numericValue, keys.logText : notificationText ]
            } else {
                logJSON = [ keys.logType : type, keys.timestamp : timestampString, keys.logNumericValue : numericValue ]
            }
            let jsonData = try! JSONSerialization.data(withJSONObject: logJSON, options: [])
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            logResource.body = jsonString
            
//            let logRequest = DataRequest(resource: logResource)
//            pendingRequests?.append(logRequest)
            let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
            let requestHeaders = [keys.headerContentType : keys.contentTypeJSON,
                                  keys.headerAuthorization : authorizationString,
                                  keys.sebConnectionToken : connectionToken!]
            load(logResource, httpMethod: logResource.httpMethod, body: logResource.body, headers: requestHeaders, withCompletion: { (logResponse, statusCode, errorResponse, responseHeaders, attempt) in
                loadCompletion(statusCode, errorResponse, responseHeaders, attempt)
            })
        }
    }
    
    
    @objc func sendLogEvent(_ logLevel: UInt, timestamp: String, numericValue: Double, message: String) {
        
        var serverLogLevel: String
        switch logLevel {
        case 1:
            serverLogLevel = keys.logLevelError
        case 2:
            serverLogLevel = keys.logLevelWarning
        case 4:
            serverLogLevel = keys.logLevelInfo
        case 8:
            serverLogLevel = keys.logLevelDebug
        default:
            serverLogLevel = keys.logLevelUnknown
        }
        let logEvent = LogEvent(logLevel: serverLogLevel, timestamp: timestamp, numericValue: numericValue, message: message)
        logSendigDispatchQueue.async {
            self.logQueue.enqueue(logEvent)
        }
        if !sendingLogEvent && serverAPI != nil && connectionToken != nil {
            logSendigDispatchQueue.async {
                self.sendLogQueue()
            }
        }
    }
    
    private func sendLogQueue() {
        if !(logQueue.isEmpty) {
            sendingLogEvent = true
            guard let logEvent = self.logQueue.dequeue() else {
                return
            }
            sendLogNotification(logLevel: logEvent.logLevel, timestamp: logEvent.timestamp, numericValue: logEvent.numericValue, text: logEvent.message)
        } else {
            sendingLogEvent = false
        }
    }
    
    private func sendLogNotification(logLevel: String, timestamp: String?, numericValue: Double, text: String?) {
        sendNotification(logLevel, timestamp: timestamp, numericValue: numericValue, text: text) { statusCode, errorResponse, responseHeaders, attempt in
            if statusCode ?? statusCodes.badRequest < statusCodes.notSuccessfullRange { //sending was successful
                self.logSendigDispatchQueue.async {
                    self.sendLogQueue() //send next log event from the queue
                }
            } else {
                // Sending this event failed: wait for fallback interval and retry
                self.logSendigDispatchQueue.async {
                    Thread.sleep(forTimeInterval: self.fallbackAttemptInterval)
                    self.sendLogNotification(logLevel: logLevel, timestamp: timestamp, numericValue: numericValue, text: text)
                }
            }
        }
    }
    
    @objc func sendBatteryEvent(numericValue: Double, message: String?) {
        if (serverAPI != nil) && (connectionToken != nil) {
            let messageString = "<\(keys.notificationTagBattery)> \(message ?? "")"
            sendNotification(keys.logLevelInfo, timestamp: nil, numericValue: numericValue, text: messageString) { statusCode, errorResponse, responseHeaders, attempt in
            }
        }
    }
    
    @objc func sendLockscreen(message: String?) -> Int64 {
        notificationNumber+=1
        sendNotification(keys.notificationType, timestamp: nil, numericValue: Double(notificationNumber), text: "<\(keys.notificationTagLockscreen)> \(message ?? "")") { statusCode, errorResponse, responseHeaders, attempt in
        }
        return notificationNumber
    }
    
    @objc func sendLockscreenConfirm(notificationUID: Int64) {
        sendNotification(keys.notificationConfirmed, timestamp: nil, numericValue: Double(notificationUID), text: nil) { statusCode, errorResponse, responseHeaders, attempt in
        }
    }
    
    @objc func sendRaiseHand(message: String?) -> Int64 {
        notificationNumber+=1
        sendNotification(keys.notificationType, timestamp: nil, numericValue: Double(notificationNumber), text: "<\(keys.notificationTagRaisehand)> \(message ?? "")") { statusCode, errorResponse, responseHeaders, attempt in
        }
        return notificationNumber
    }
    
    @objc func sendLowerHand(notificationUID: Int64) {
        sendNotification(keys.notificationConfirmed, timestamp: nil, numericValue: Double(notificationUID), text: nil) { statusCode, errorResponse, responseHeaders, attempt in
        }
    }
    
    @objc func quitSession(restart: Bool, completion: @escaping (Bool) -> Void) {
        if accessToken != nil {
            let quitSessionResource = QuitSessionResource(baseURL: self.baseURL, endpoint: (serverAPI?.handshake.endpoint?.location)!)
            
            let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
            let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                                  keys.headerAuthorization : authorizationString,
                                  keys.sebConnectionToken : connectionToken ?? ""]
            load(quitSessionResource, httpMethod: quitSessionResource.httpMethod, body: quitSessionResource.body, headers: requestHeaders, withCompletion: { (quitSessionResponse, statusCode, errorResponse, responseHeaders, attempt) in
                self.cancelAllRequests = true
                self.stopPingTimer()
                self.connectionToken = nil
    //            if quitSessionResponse != nil  {
    //                let responseBody = String(data: quitSessionResponse!, encoding: .utf8)
    //                DDLogVerbose(responseBody as Any)
    //            }
                self.session.invalidateAndCancel()
                completion(restart)
            })
        } else {
            self.cancelAllRequests = true
            self.stopPingTimer()
            self.connectionToken = nil
            self.session.invalidateAndCancel()
            completion(restart)
        }
    }
    
    fileprivate func didFail(error: NSError, fatal: Bool) {
        if !cancelAllRequests {
            self.delegate?.didFail(error: error, fatal: fatal)
        }
    }
}
