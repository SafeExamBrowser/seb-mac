//
//  MoodleController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.10.18.
//

import Foundation

@objc public protocol ServerControllerDelegate: class {
    
    func queryCredentialsPresetUsername(_ username: String)
    
    func didGetUserToken()
}

public class SEBServerController : NSObject {
    
    fileprivate var pendingRequests: [AnyObject]? = []
    fileprivate var serverAPI: SEB_Endpoints?
    fileprivate var accessToken: String?
    fileprivate var username: String
    fileprivate var password: String

    @objc weak public var delegate: ServerControllerDelegate?
    
    let baseURL: URL
    @objc public var institution: String
//    @objc public var username: String
//    @objc public var password: String
    @objc public var discoveryEndpoint: String

    
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
            
//            for serverEndpoint in serverAPIEndpoints {
//                let endpointName = serverEndpoint.name
//                sebEndpoints.
//            }
            
            sebEndpoints.accessToken.endpoint = serverAPIEndpoints.endpoint(name: sebEndpoints.accessToken.name)
            
//            let mirror = Mirror(reflecting: sebEndpoints)
//            for child in mirror.children {
//                let endpointName = (child.value as! SEB_Endpoint).name
//
//                var sebEndpoint = sebEndpoints.endpointName
//            }
            self.serverAPI = sebEndpoints
            
            self.getAccessToken()
            

//            if token?.token == nil {
//                self.delegate?.queryCredentialsPresetUsername(self.username)
//            } else {
//                self.token = token?.token
//
//                self.delegate?.didGetUserToken()
//
//                //self.getCourseList(token: (token?.token)!)
//                //self?.configureUI(with: topQuestion)
//            }
        }
    }

    
    
    
    
    func getAccessToken() {
        
        

//        guard let endpoint = serverAPI
        let accessTokenResource = AccessTokenResource(baseURL: self.baseURL, endpoint: (serverAPI?.accessToken.endpoint?.location)!, username: self.username, password: self.password)
        
        let accessTokenRequest = ApiRequest(resource: accessTokenResource)
        pendingRequests?.append(accessTokenRequest)
        // ToDo: Implement timeout and sebServerFallback
        accessTokenRequest.load(httpMethod: accessTokenResource.httpMethod, body:accessTokenResource.body, username: self.username, password: self.password, completion: { (accessTokenResponse) in
            // ToDo: This guard check doesn't work, userToken seems to be a double optional?
            guard let accessToken = accessTokenResponse else {
                return
            }
            guard let tokenString = accessToken?.access_token else {
                return
            }
            self.accessToken = tokenString
            
            //                self.delegate?.didGetUserToken()
            //
            //                //self.getCourseList(token: (token?.token)!)
        })
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
