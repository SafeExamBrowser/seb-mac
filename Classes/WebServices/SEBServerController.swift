//
//  MoodleController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.10.18.
//

import Foundation

@objc public protocol ServerControllerDelegate: class {
    func loginToExam(_ examId: String, url: String)
}

@objc public protocol ServerControllerUIDelegate: class {
    
    func updateExamList()
}

@objc public class SEBServerController : NSObject {
    
    fileprivate var pendingRequests: [AnyObject]? = []
    fileprivate var serverAPI: SEB_Endpoints?
    fileprivate var accessToken: String?
    fileprivate var username: String
    fileprivate var password: String
    fileprivate var connectionToken: String?
    fileprivate var exams: [Exam]?
    fileprivate var selectedExamId: String?

    @objc weak public var delegate: ServerControllerDelegate?
    @objc weak public var serverControllerUIDelegate: ServerControllerUIDelegate?

    let baseURL: URL
    @objc public var institution: String
    @objc public var discoveryEndpoint: String
    @objc public var examList: [ExamObject]?
    
    @objc public init(baseURL: URL, institution:  String, username: String, password: String, discoveryEndpoint: String, delegate: ServerControllerDelegate) {
        self.baseURL = baseURL
        self.institution = institution
        self.username = username
        self.password = password
        self.discoveryEndpoint = discoveryEndpoint

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
        let requestHeaders = [keys.authorization : authorizationString]
        
        accessTokenRequest.load(httpMethod: accessTokenResource.httpMethod, body:accessTokenResource.body, headers: requestHeaders, completion: { (accessTokenResponse, responseHeaders) in
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
        handshakeResource.body = keys.institutionId + "=" + institution
        
        let handshakeRequest = ApiRequest(resource: handshakeResource)
        pendingRequests?.append(handshakeRequest)
        // ToDo: Implement timeout and sebServerFallback
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.authorization : authorizationString]
        handshakeRequest.load(httpMethod: handshakeResource.httpMethod, body:handshakeResource.body, headers: requestHeaders, completion: { (handshakeResponse, responseHeaders) in
            guard let connectionTokenString = (responseHeaders?.first(where: { $0.key as! String == keys.sebConnectionToken }))?.value else {
                return
            }
            self.connectionToken = connectionTokenString as? String
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
        })
    }
    
    
    @objc func examSelected(_ examId: String, url: String) {
        selectedExamId = examId
        getExamConfig()
    }
    
    
    func getExamConfig() {
        var examConfigResource = ExamConfigResource(baseURL: self.baseURL, endpoint: (serverAPI?.configuration.endpoint?.location)!)
        examConfigResource.body = keys.examId + "=" + (selectedExamId ?? "")
        
        let examConfigRequest = ApiRequest(resource: examConfigResource)
        pendingRequests?.append(examConfigRequest)
        let authorizationString = (serverAPI?.handshake.endpoint?.authorization ?? "") + " " + (accessToken ?? "")
        let requestHeaders = [keys.authorization : authorizationString, keys.sebConnectionToken : connectionToken!]
        examConfigRequest.load(httpMethod: examConfigResource.httpMethod, body:examConfigResource.body, headers: requestHeaders, completion: { (examConfigResponse, responseHeaders) in
            guard let config = examConfigResponse else {
                return
            }
            print(config as Any)
        })
    }
    
    
    @objc func loginToExam(_ examId: String, url: String) {
        delegate?.loginToExam(examId, url: url)
    }

    @objc func startMonitoring(examId: String, userSessionId: String) {
        
    }
    
    
    //    @objc func getCourseList() {
//        guard let token = self.token else {
//            return
//        }
//        let coursesResource = CoursesResource(baseUrl: self.baseURL, token: token)
//
//        let coursesRequest = ApiRequest(resource: coursesResource)
//        pendingRequests?.append(coursesRequest)
//        coursesRequest.load { (courses) in
//            // ToDo: This guard check doesn't work, userToken seems to be a double optional?
//            guard let coursesList = courses else {
//                return
//            }
//            if coursesList == nil {
//                return
//            }
//            //print(coursesList!)
//            self.storedCourses = coursesList
//            self.fetchedCourseActivities = 0
//
//            for index in 0..<self.storedCourses!.count
//            {
//                self.getQuizzesList(token: token, courseIndex: index)
//            }
//        }
//    }
//
//    func getQuizzesList(token: String, courseIndex: Int) {
//        let courseID = storedCourses![courseIndex].id
//        let quizzesResource = QuizzesResource(baseUrl: self.baseURL, token: token, courseID: courseID)
//
//        let quizzesRequest = ApiRequest(resource: quizzesResource)
//        pendingRequests?.append(quizzesRequest)
//        quizzesRequest.load { (quizzes) in
//            guard let quizzesObject = quizzes, var quizzesList = quizzesObject?.quizzes else {
//                return
//            }
//            //print(quizzesObject!)
//            //print(quizzesList)
//
//            let parentCourse = self.storedCourses![courseIndex]
//            for (index, var quiz) in quizzesList.enumerated() {
//                quiz.courseObject = parentCourse
//                quizzesList[index] = quiz
//            }
//
//            //let courses = self.storedCourses!
//            //_ = self.findCourseWithID(courses: courses, id: courseID)
//            self.storedCourses![courseIndex].quizzesObject = quizzesList
//            self.fetchedCourseActivities += 1
//            //print(self.storedCourses!)
//            if self.fetchedCourseActivities == (self.storedCourses?.count)! {
//            }
//        }
//    }
//
//    func findCourseWithID(courses: [Course], id: Int) -> Course? {
//        for course in courses {
//            if course.id == id {
//                return course
//            }
//        }
//        return nil
//    }
}
