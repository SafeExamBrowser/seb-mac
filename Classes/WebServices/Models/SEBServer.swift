//
//  SEBServer.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.08.18.
//

import Foundation

public struct keys {
    static let headerAuthorization = "Authorization"
    static let headerContentType = "Content-Type"
    static let contentTypeFormURLEncoded = "application/x-www-form-urlencoded"
    static let contentTypeJSON = "application/json;charset=UTF-8"
    static let institutionId = "institutionId"
    static let examId = "examId"
    static let sebConnectionToken = "SEBConnectionToken"
    static let sebUserSessionId = "seb_user_session_id"
    static let timestamp = "timestamp"
    static let pingNumber = "ping-number"
    static let logType = "type"
    static let logNumericValue = "numericValue"
    static let logText = "text"
    static let logLevelError = "ERROR_LOG"
    static let logLevelWarning = "WARN_LOG"
    static let logLevelInfo = "INFO_LOG"
    static let logLevelDebug = "DEBUG_LOG"
    static let logLevelUnknown = "UNKNOWN"
}

public struct Discovery: Codable {
    let title: String
    let description: String
    let server_location: String
    let api_versions: [API_Version]
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case server_location = "server-location"
        case api_versions = "api-versions"
    }
}

public struct API_Version: Codable {
    let name: String
    let endpoints: [Endpoint]
}

public struct Endpoint: Codable {
    let name: String
    let description: String
    let location: String
    let authorization: String
}

public struct SEB_Endpoint {
    var name: String
    var endpoint: Endpoint?
    
    init(_ name: String,_ endpoint: Endpoint?) {
        self.name = name
        self.endpoint = endpoint
    }
}

public struct SEB_Endpoints {
    var accessToken = SEB_Endpoint("access-token-endpoint", nil)
    var handshake = SEB_Endpoint("seb-handshake-endpoint", nil)
    var configuration = SEB_Endpoint("seb-configuration-endpoint", nil)
    var ping = SEB_Endpoint("seb-ping-endpoint", nil)
    var log = SEB_Endpoint("seb-log-endpoint", nil)
}

public struct AccessToken: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let scope: String
    let jti: String
}


//public struct Exams: Codable {
//    let exams: [Exam]
//}


public struct Exam: Codable {
    let examId: String
    let name: String
    let url: String
    let lmsType: String
}


@objc public class ExamObject: NSObject {
    let exam: Exam
    
    init(_ exam: Exam) {
        self.exam = exam
    }

    @objc public func examId() -> String { return exam.examId }
    @objc public func name() -> String { return exam.name }
    @objc public func url() -> String { return exam.url }
    @objc public func lmsType() -> String { return exam.lmsType }
}


// Moodle: ToDo: remove
public struct AutologinKey: Codable {
    let key: String
    let autologinurl: String
    let warnings: [String]
}

public struct Course: Codable {
    let id: Int
    let shortname: String
    let categoryid: Int
    let categorysortorder: Int
    let fullname: String
    let displayname: String
    let idnumber: String
    let summary: String
    let summaryformat: Int
    let format: String
    let showgrades: Int
    let newsitems: Int
    let startdate: Int
    let enddate: Int
    let numsections: Int
    let maxbytes: Int
    let showreports: Int
    let visible: Int
    let groupmode: Int
    let groupmodeforce: Int
    let defaultgroupingid: Int
    let timecreated: Int
    let timemodified: Int
    let enablecompletion: Int
    let completionnotify: Int
    let lang: String
    let forcetheme: String
    let courseformatoptions: [CourseFormatOptions]
    
    var quizzesObject: [Quiz]?
}
public struct CourseFormatOptions: Codable {
    let name: String
    let value: Int
}

public struct Quizzes: Codable {
    let quizzes: [Quiz]
    let warnings: [Warning]
}
public struct Quiz: Codable {
    let id: Int
    let course: Int
    let coursemodule: Int
    let name: String
    let intro: String
    let introformat: Int
    let introfiles: [IntroFiles]
    let timeopen: Int
    let timeclose: Int
    let timelimit: Int
    let preferredbehaviour: String
    let attempts: Int
    let grademethod: Int
    let decimalpoints: Int
    let questiondecimalpoints: Int
    let shuffleanswers: Int
    let sumgrades: Int
    let grade: Int
    let timecreated: Int
    let timemodified: Int
    let password: String
    let subnet: String
    let hasfeedback: Int
    let section: Int
    let visible: Int
    let groupmode: Int
    let groupingid: Int
    
    var courseObject: Course?
}
public struct IntroFiles: Codable {
    
}
public struct Warning: Codable {
    
}
