//
//  APIResources.swift
//  TopQuestion
//
//  Created by Matteo Manferdini on 25/05/2017.
//  Copyright © 2017 Pure Creek. All rights reserved.
//

import Foundation

protocol ApiResource {
    associatedtype Model:Decodable
    var baseUrl: String { get }
	var methodPath: String { get }
    var queryParameters: [String] { get }
    func makeModel(data:Data) -> Model
}

extension ApiResource {
	var url: URL {
        let hostPath = baseUrl + methodPath
		let url = hostPath + "?" + queryParameters.joined(separator: "&")
		return URL(string: url)!
	}
}

struct UserTokenResource: ApiResource {
   
    var baseUrl: String
    var queryParameters: [String]

    let methodPath = "/login/token.php"
    let service = "service=moodle_mobile_app"

    init(baseUrl: String, username: String, password: String) {
        self.baseUrl = baseUrl
        self.queryParameters = [username, password, service]
    }
    
    func makeModel(data: Data) -> UserToken? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let userToken = try? decoder.decode(UserToken.self, from: data) else {
            return nil
        }
        return userToken
    }
}

struct CoursesResource: ApiResource {

    var baseUrl: String
    var queryParameters: [String]
    
    let methodPath = "/webservice/rest/server.php"
    let function = "wsfunction=core_course_get_courses"
    let restformat = "moodlewsrestformat=json"

    init(baseUrl: String, token: String) {
        let token = "wstoken=" + token
        self.baseUrl = baseUrl
        self.queryParameters = [token, function, restformat]
    }
    
    func makeModel(data: Data) -> [Course]? {
        print(String(data: data, encoding: String.Encoding.utf8)!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let courseList = try? decoder.decode([Course].self, from: data) else {
            return nil
        }
        return courseList
    }
}

struct QuizzesResource: ApiResource {
    
    var baseUrl: String
    var queryParameters: [String]
    
    let methodPath = "/webservice/rest/server.php"
    let function = "wsfunction=mod_quiz_get_quizzes_by_courses"
    let restformat = "moodlewsrestformat=json"
    
    init(baseUrl: String, token: String, courseID: Int) {
        let token = "wstoken=" + token
        let courseIDParameter = "courseids%5B0%5D=" + String(courseID)
        self.baseUrl = baseUrl
        self.queryParameters = [token, function, restformat, courseIDParameter]
    }
    
    func makeModel(data: Data) -> Quizzes? {
        print(String(data: data, encoding: String.Encoding.utf8)!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let quizzesList = try? decoder.decode(Quizzes.self, from: data) else {
            return nil
        }
        return quizzesList
    }
}

//https://seb.let.ethz.ch/moodle/webservice/rest/server.php?wstoken=a86a10cf607f6997dce1014950afed41&wsfunction=core_course_get_courses&moodlewsrestformat=json
//https://seb.let.ethz.ch/moodle/webservice/rest/server.php?wstoken=a86a10cf607f6997dce1014950afed41&wsfunction=mod_quiz_get_quizzes_by_courses&moodlewsrestformat=json&courseids%5B0%5D=4
