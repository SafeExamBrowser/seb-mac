//
//  MoodleController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.10.18.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation

@objc public protocol SEBServerControllerDelegate: AnyObject {
    func didSelectExam(_ examId: String, url: String)
    func loginToExam(_ url: String)
    func didReceiveMoodleUserId(_ moodleUserId: String)
    func reconfigureWithServerExamConfig(_ configData: Data)
    func didEstablishSEBServerConnection()
    func executeSEBInstruction(_ sebInstruction: SEBInstruction)
    func didCloseSEBServerConnectionRestart(_ restart: Bool)
}

@objc public protocol ServerControllerUIDelegate: AnyObject {
    
    func updateExamList()
}

@objc public class SEBServerController : NSObject {
    
    fileprivate var pendingRequests: [AnyObject]? = []
    fileprivate var serverAPI: SEB_Endpoints?
    fileprivate var accessToken: String?
    fileprivate var connectionToken: String?
    fileprivate var exams: [Exam]?
    fileprivate var selectedExamId = ""
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

    @objc public init(baseURL: URL, institution:  String, exam: String?, username: String, password: String, discoveryEndpoint: String, pingInterval: Double, delegate: SEBServerControllerDelegate) {
        self.baseURL = baseURL
        self.institution = institution
        self.exam = exam
        self.username = username
        self.password = password
        self.discoveryEndpoint = discoveryEndpoint
        self.pingInterval = pingInterval
        self.delegate = delegate
    }
}

extension Array where Element == Endpoint {
    func endpoint(name: String) -> Endpoint? {
        return self.first(where: { $0.name == name })
    }
}

public extension SEBServerController {

    @objc func getServerAPI() {

        let discoveryResource = DiscoveryResource(baseURL: self.baseURL, discoveryEndpoint: self.discoveryEndpoint)

        let discoveryRequest = ApiRequest(resource: discoveryResource)
        pendingRequests?.append(discoveryRequest)
        // ToDo: Implement timeout and sebServerFallback
        discoveryRequest.load { (discoveryResponse) in
            // ToDo: This guard check doesn't work, userToken seems to be a double optional?
            guard let discovery = discoveryResponse else {
                return
            }
            guard let serverAPIEndpoints = discovery?.api_versions[0].endpoints else {
                return
            }
            var sebEndpoints = SEB_Endpoints()
                        
            sebEndpoints.accessToken.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.accessToken.name)
            sebEndpoints.handshake.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.handshake.name)
            sebEndpoints.configuration.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.configuration.name)
            sebEndpoints.ping.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.ping.name)
            sebEndpoints.log.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.log.name)

            self.serverAPI = sebEndpoints
            
            self.getAccessToken()
        }
    }
    
    func getAccessToken() {
        let accessTokenResource = AccessTokenResource(baseURL: self.baseURL, endpoint: (serverAPI?.accessToken.endpoint?.location)!)
        
        let accessTokenRequest = ApiRequest(resource: accessTokenResource)
        pendingRequests?.append(accessTokenRequest)
        // ToDo: Implement timeout and sebServerFallback -> on a higher level
        let authorizationString = (serverAPI?.accessToken.endpoint?.authorization ?? "") + " " + (username + ":" + password).data(using: .utf8)!.base64EncodedString()
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                              keys.headerAuthorization : authorizationString]
        
        accessTokenRequest.load(httpMethod: accessTokenResource.httpMethod, body:accessTokenResource.body, headers: requestHeaders, completion: { (accessTokenResponse, statusCode, responseHeaders) in
            guard let accessToken = accessTokenResponse else {
                return
            }
            guard let tokenString = accessToken?.access_token else {
                return
            }
            self.accessToken = tokenString
            // self.delegate?.didGetUserToken()

            self.getExamList()
        })
    }
    
    
    func getExamList() {
        var handshakeResource = HandshakeResource(baseURL: self.baseURL, endpoint: (serverAPI?.handshake.endpoint?.location)!)
        handshakeResource.body = keys.institutionId + "=" + institution + (exam == nil ? "" : ("&" + keys.examId + "=" + exam!))
        
        let handshakeRequest = ApiRequest(resource: handshakeResource)
        pendingRequests?.append(handshakeRequest)
        // ToDo: Implement timeout and sebServerFallback
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                              keys.headerAuthorization : authorizationString]
        handshakeRequest.load(httpMethod: handshakeResource.httpMethod, body:handshakeResource.body, headers: requestHeaders, completion: { (handshakeResponse, statusCode, responseHeaders) in
            guard let connectionTokenString = (responseHeaders?.first(where: { ($0.key as! String).caseInsensitiveCompare(keys.sebConnectionToken) == .orderedSame}))?.value else {
                return
            }
            self.connectionToken = connectionTokenString as? String
            
            self.startPingTimer()
            
            guard let exams = handshakeResponse else {
                return
            }
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
    
    
    @objc func examSelected(_ examId: String, url: String) {
        selectedExamId = examId
        selectedExamURL = url
        getExamConfig()
    }
    
    
    func getExamConfig() {
        let examConfigResource = ExamConfigResource(baseURL: self.baseURL, endpoint: (serverAPI?.configuration.endpoint?.location)!, queryParameters: [keys.examId + "=" + (selectedExamId)])
        
        let examConfigRequest = DataRequest(resource: examConfigResource)
        pendingRequests?.append(examConfigRequest)
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerAuthorization : authorizationString,
                              keys.sebConnectionToken : connectionToken!]
        examConfigRequest.load(httpMethod: examConfigResource.httpMethod, body:examConfigResource.body, headers: requestHeaders, completion: { (examConfigResponse, statusCode, responseHeaders) in
            guard let config = examConfigResponse else {
                return
            }
            self.delegate?.reconfigureWithServerExamConfig(config)
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

        let moodleUserIdRequest = DataRequest(resource: moodleUserIdResource)
        pendingRequests?.append(moodleUserIdRequest)
        let requestHeaders = ["Cookie" : "MoodleSession=\(moodleSession)"]
        moodleUserIdRequest.load(httpMethod: moodleUserIdResource.httpMethod, body:"", headers: requestHeaders, completion: { (moodleUserIdResponse, statusCode, responseHeaders) in
            if statusCode == 200 && moodleUserIdResponse != nil {
                guard let moodleUserId = String(data: moodleUserIdResponse!, encoding: .utf8) else {
                    DDLogDebug("No valid Moodle user ID found")
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

        let handshakeCloseRequest = DataRequest(resource: handshakeCloseResource)
        pendingRequests?.append(handshakeCloseRequest)
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                              keys.headerAuthorization : authorizationString,
                              keys.sebConnectionToken : connectionToken!]
        handshakeCloseRequest.load(httpMethod: handshakeCloseResource.httpMethod, body:handshakeCloseResource.body, headers: requestHeaders, completion: { (handshakeCloseResponse, statusCode, responseHeaders) in
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
            
            let pingRequest = ApiRequest(resource: pingResource)
            pendingRequests?.append(pingRequest)
            let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
            let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                                  keys.headerAuthorization : authorizationString,
                                  keys.sebConnectionToken : connectionToken!]
            pingRequest.load(httpMethod: pingResource.httpMethod, body:pingResource.body, headers: requestHeaders, completion: { (pingResponse, statusCode, responseHeaders) in
                guard let ping = pingResponse else {
                    return
                }
                self.pingInstruction = nil
                if (ping != nil) {
                    self.delegate?.executeSEBInstruction(SEBInstruction(ping!))
                }
            })
        }
    }
    
    
    func sendNotification(_ type: String, timestamp: String, numericValue: Double, text: String?) {
        if (serverAPI != nil) && (connectionToken != nil) {
            var logResource = LogResource(baseURL: self.baseURL, endpoint: (serverAPI?.log.endpoint?.location)!)
            var logJSON: [String : Any]
            if let notificationText = text {
                logJSON = [ keys.logType : type, keys.timestamp : timestamp, keys.logNumericValue : numericValue, keys.logText : notificationText ]
            } else {
                logJSON = [ keys.logType : type, keys.timestamp : timestamp, keys.logNumericValue : numericValue ]
            }
            let jsonData = try! JSONSerialization.data(withJSONObject: logJSON, options: [])
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            logResource.body = jsonString
            
            let logRequest = DataRequest(resource: logResource)
            pendingRequests?.append(logRequest)
            let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
            let requestHeaders = [keys.headerContentType : keys.contentTypeJSON,
                                  keys.headerAuthorization : authorizationString,
                                  keys.sebConnectionToken : connectionToken!]
            logRequest.load(httpMethod: logResource.httpMethod, body:logResource.body, headers: requestHeaders, completion: { (logResponse, statusCode, responseHeaders) in
//                if logResponse != nil  {
//                    let responseBody = String(data: logResponse!, encoding: .utf8)
//                    DDLogVerbose(responseBody as Any)
//                }
            })
        }
    }
    
    
    @objc func sendLogEvent(_ logLevel: UInt, timestamp: String, numericValue: Double, message: String) {
        if (serverAPI != nil) && (connectionToken != nil) {
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
            sendNotification(serverLogLevel, timestamp: timestamp, numericValue: numericValue, text: message)
        }
    }
    
    @objc func sendLockscreen(message: String?) -> Int64 {
        notificationNumber+=1
        sendNotification(keys.notificationType, timestamp: String(format: "%.0f", NSDate().timeIntervalSince1970 * 1000), numericValue: Double(notificationNumber), text: "<\(keys.notificationTagLockscreen)> \(message ?? "")")
        return notificationNumber
    }
    
    @objc func sendRaiseHand(message: String?) -> Int64 {
        notificationNumber+=1
        sendNotification(keys.notificationType, timestamp: String(format: "%.0f", NSDate().timeIntervalSince1970 * 1000), numericValue: Double(notificationNumber), text: "<\(keys.notificationTagRaisehand)> \(message ?? "")")
        return notificationNumber
    }
    
    @objc func sendLowerHand(notificationUID: Int64) {
        sendNotification(keys.notificationConfirmed, timestamp: String(format: "%.0f", NSDate().timeIntervalSince1970 * 1000), numericValue: Double(notificationNumber), text: nil)
    }
    
    @objc func quitSession(restart: Bool, completion: @escaping (Bool) -> Void) {
        let quitSessionResource = QuitSessionResource(baseURL: self.baseURL, endpoint: (serverAPI?.handshake.endpoint?.location)!)
        
        let quitSessionRequest = DataRequest(resource: quitSessionResource)
        pendingRequests?.append(quitSessionRequest)
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.headerContentType : keys.contentTypeFormURLEncoded,
                              keys.headerAuthorization : authorizationString,
                              keys.sebConnectionToken : connectionToken ?? ""]
        quitSessionRequest.load(httpMethod: quitSessionResource.httpMethod, body:quitSessionResource.body, headers: requestHeaders, completion: { (quitSessionResponse, statusCode, responseHeaders) in
            self.stopPingTimer()
            self.connectionToken = nil
//            if quitSessionResponse != nil  {
//                let responseBody = String(data: quitSessionResponse!, encoding: .utf8)
//                DDLogVerbose(responseBody as Any)
//            }
            completion(restart)
        })
    }
}
