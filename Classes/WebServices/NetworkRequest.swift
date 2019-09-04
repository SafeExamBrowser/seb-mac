//
//  NetworkRequest.swift
//
//
//

import Foundation
import UIKit

protocol NetworkRequest: class {
	associatedtype Model
	func load(withCompletion completion: @escaping (Model?) -> Void)
	func decode(_ data: Data) -> Model?
}

extension NetworkRequest {
	fileprivate func load(_ url: URL, withCompletion completion: @escaping (Model?) -> Void) {
		let configuration = URLSessionConfiguration.ephemeral
		let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
		let task = session.dataTask(with: url, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
//            print(data as Any)
			guard let receivedData = data else {
				completion(nil)
				return
			}
			completion(self?.decode(receivedData))
		})
		task.resume()
	}
}

extension NetworkRequest {
    fileprivate func load(_ url: URL, httpMethod: String, body: String, username: String, password: String, withCompletion completion: @escaping (Model?) -> Void) {
        let configuration = URLSessionConfiguration.ephemeral
        let authorizationString = "Basic " + (username + ":" + password).data(using: .utf8)!.base64EncodedString()
//        configuration.httpAdditionalHeaders = ["Authorization" : authorizationString]
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue(authorizationString, forHTTPHeaderField: "Authorization")
        request.httpBody = body.data(using: .utf8)!

        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            print(data as Any)
            print(response as Any)
            print(error as Any)
            guard let receivedData = data else {
                completion(nil)
                return
            }
            completion(self?.decode(receivedData))
        })
        task.resume()
    }
}

class ApiRequest<Resource: ApiResource> {
	let resource: Resource
	
	init(resource: Resource) {
		self.resource = resource
	}
}

extension ApiRequest: NetworkRequest {
	func decode(_ data: Data) -> Resource.Model? {
		return resource.makeModel(data: data)
	}
	
	func load(withCompletion completion: @escaping (Resource.Model?) -> Void) {
		load(resource.url, withCompletion: completion)
	}

    func load(httpMethod: String, body: String, username: String, password: String, completion: @escaping (Resource.Model?) -> Void) {
        load(resource.url, httpMethod: httpMethod, body: body, username: username, password: password, withCompletion: completion)
    }
}

class ImageRequest {
	let url: URL
	
	init(url: URL) {
		self.url = url
	}
}

extension ImageRequest: NetworkRequest {
	func decode(_ data: Data) -> UIImage? {
		return UIImage(data: data)
	}
	
	func load(withCompletion completion: @escaping (UIImage?) -> Void) {
		load(url, withCompletion: completion)
	}
}


