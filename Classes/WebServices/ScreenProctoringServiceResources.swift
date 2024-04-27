//
//  ScreenProctoringService.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 23.04.24.
//

import Foundation
import CocoaLumberjackSwift

protocol ScreenProctoringServiceResources : ApiResource {
    
}

struct SPSAccessTokenResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    let body = "grant_type=client_credentials&scope=read write".data(using: .utf8)
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    func makeModel(data: Data) -> AccessToken? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
#if DEBUG
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
        do {
            let accessToken = try decoder.decode(AccessToken.self, from: data)
            return accessToken
        } catch let error {
            DDLogError("SEB Server API Access Token Resource failed: \(String(describing: error))")
        }
        return nil
    }
}

struct SPSScreenShotResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    var body = Data()
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }

    func makeModel(data: Data) -> Data? {
#if DEBUG
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
        return data
    }
}

struct SPSCloseSessionResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "DELETE"
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    func makeModel(data: Data) -> Data? {
#if DEBUG
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
        return data
    }
}

struct SPSHealthCheckResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "GET"
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    func makeModel(data: Data) -> Data? {
#if DEBUG
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
        return data
    }
}
