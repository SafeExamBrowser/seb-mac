//
//  ScreenProctoringService.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 23.04.24.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8) ?? "")
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
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8) ?? "")
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
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8) ?? "")
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
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8) ?? "")
#endif
        return data
    }
}
