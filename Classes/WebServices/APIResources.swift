//
//  APIResources.swift
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
import CocoaLumberjackSwift

protocol ApiResource {
    associatedtype Model:Decodable
    var baseURL: URL { get }
	var methodPath: String { get }
    var queryParameters: [String] { get }
    func makeModel(data:Data) -> Model
}

extension ApiResource {
	var url: URL {
        let hostPath = baseURL.absoluteString + methodPath
        let url = hostPath + (queryParameters.count == 0 ? "" : ("?" + queryParameters.joined(separator: "&")))
		return URL(string: url)!
	}
}

struct DiscoveryResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    
    init(baseURL: URL, discoveryEndpoint: String) {
        self.baseURL = baseURL
        self.methodPath = discoveryEndpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    func makeModel(data: Data) -> Discovery? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
#if DEBUG
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
        do {
            let discovery = try decoder.decode(Discovery.self, from: data)
            return discovery
        } catch let error {
            DDLogError("SEB Server API Discovery Resource failed: \(String(describing: error))")
        }
        return nil
    }
}

struct AccessTokenResource: ApiResource {

    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    let body = "grant_type=client_credentials&scope=read write"

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

struct HandshakeResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    func makeModel(data: Data) -> [Exam]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
#if DEBUG
        DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
        do {
            let exams = try decoder.decode([Exam].self, from: data)
            return exams
        } catch let error {
            DDLogError("SEB Server API Handshake Resource failed: \(String(describing: error))")
        }
        return nil
    }
}

struct HandshakeUpdateResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "PATCH"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
    }
    
    func makeModel(data: Data) -> Data? {
        return data
    }
}

struct ExamConfigResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "GET"
    var body = ""
    
    init(baseURL: URL, endpoint: String, queryParameters: [String]) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = queryParameters
    }
    func makeModel(data: Data) -> Data? {
        return data
    }
}

struct MoodleUserIdResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
    }
    
    func makeModel(data: Data) -> Data? {
        return data
    }
}

struct HandshakeCloseResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "PUT"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
    }
    func makeModel(data: Data) -> Data? {
        return data
    }
}

struct PingResource: ApiResource {    
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    func makeModel(data: Data) -> Ping? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if data.count > 0 {
#if DEBUG
            DDLogDebug(String(data: data, encoding: String.Encoding.utf8)!)
#endif
            do {
                let ping = try decoder.decode(Ping.self, from: data)
                return ping
            } catch let error {
                DDLogError("SEB Server API Ping Resource failed: \(String(describing: error))")
            }
        }
        return nil
    }
}

struct LogResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "POST"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
    }
    func makeModel(data: Data) -> Data? {
        return data
    }
}

struct QuitSessionResource: ApiResource {
    
    var baseURL: URL
    var queryParameters: [String]
    let methodPath: String
    let httpMethod = "DELETE"
    var body = ""
    
    init(baseURL: URL, endpoint: String) {
        self.baseURL = baseURL
        self.methodPath = endpoint
        self.queryParameters = []
    }
    func makeModel(data: Data) -> Data? {
        return data
    }
}


//struct CoursesResource: ApiResource {
//
//    var baseUrl: String
//    var queryParameters: [String]
//
//    let methodPath = "/webservice/rest/server.php"
//    let function = "wsfunction=core_course_get_courses"
//    let restformat = "moodlewsrestformat=json"
//
//    init(baseUrl: String, token: String) {
//        let token = "wstoken=" + token
//        self.baseUrl = baseUrl
//        self.queryParameters = [token, function, restformat]
//    }
//
//    func makeModel(data: Data) -> [Course]? {
//        print(String(data: data, encoding: String.Encoding.utf8)!)
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .secondsSince1970
//        guard let courseList = try? decoder.decode([Course].self, from: data) else {
//            return nil
//        }
//        return courseList
//    }
//}
//
//struct QuizzesResource: ApiResource {
//
//    var baseUrl: String
//    var queryParameters: [String]
//
//    let methodPath = "/webservice/rest/server.php"
//    let function = "wsfunction=mod_quiz_get_quizzes_by_courses"
//    let restformat = "moodlewsrestformat=json"
//
//    init(baseUrl: String, token: String, courseID: Int) {
//        let token = "wstoken=" + token
//        let courseIDParameter = "courseids%5B0%5D=" + String(courseID)
//        self.baseUrl = baseUrl
//        self.queryParameters = [token, function, restformat, courseIDParameter]
//    }
//
//    func makeModel(data: Data) -> Quizzes? {
//        print(String(data: data, encoding: String.Encoding.utf8)!)
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .secondsSince1970
//        guard let quizzesList = try? decoder.decode(Quizzes.self, from: data) else {
//            return nil
//        }
//        return quizzesList
//    }
//}

//https://seb.let.ethz.ch/moodle/webservice/rest/server.php?wstoken=a86a10cf607f6997dce1014950afed41&wsfunction=core_course_get_courses&moodlewsrestformat=json
//https://seb.let.ethz.ch/moodle/webservice/rest/server.php?wstoken=a86a10cf607f6997dce1014950afed41&wsfunction=mod_quiz_get_quizzes_by_courses&moodlewsrestformat=json&courseids%5B0%5D=4
