//
//  Moodle.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.08.18.
//

import Foundation

public struct UserToken: Codable {
    let token: String
    let privatetoken: String?
    
    enum CodingKeys: String, CodingKey {
        case token
        case privatetoken
    }
}

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
