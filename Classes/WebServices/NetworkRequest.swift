//
//  NetworkRequest.swift
//
//
//

import Foundation
import UIKit

protocol NetworkRequest: AnyObject {
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
    fileprivate func load(_ url: URL, httpMethod: String, body: String, headers: [AnyHashable: Any]?, withCompletion completion: @escaping ((Model?), Int?, [AnyHashable: Any]?) -> Void) {
        let configuration = URLSessionConfiguration.ephemeral
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = httpMethod
        if let additionalHeaders = headers {
            for header in additionalHeaders {
                request.addValue(header.value as! String, forHTTPHeaderField: header.key as! String)
            }
        }
        request.httpBody = body.data(using: .utf8)!

        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            print(data as Any)
            if (data != nil) {
                print(String(decoding: data!, as: UTF8.self))
            }
            print(response as Any)
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            let responseHeaders = httpResponse?.allHeaderFields
            print(error as Any)
            guard let receivedData = data else {
                completion(nil, statusCode, [:])
                return
            }
            completion(self?.decode(receivedData), statusCode, responseHeaders)
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

    func load(httpMethod: String, body: String, headers: [AnyHashable: Any]?, completion: @escaping ((Resource.Model?), Int?, [AnyHashable: Any]?) -> Void) {
        load(resource.url, httpMethod: httpMethod, body: body, headers: headers, withCompletion: completion)
    }
}

class DataRequest <Resource: ApiResource> {
    let resource: Resource
    
    init(resource: Resource) {
        self.resource = resource
    }
}

extension DataRequest: NetworkRequest {
	func decode(_ data: Data) -> Data? {
		return data
	}
	
	func load(withCompletion completion: @escaping (Data?) -> Void) {
		load(resource.url, withCompletion: completion)
	}
    
    func load(httpMethod: String, body: String, headers: [AnyHashable: Any]?, completion: @escaping ((Data?), Int?, [AnyHashable: Any]?) -> Void) {
        load(resource.url, httpMethod: httpMethod, body: body, headers: headers, withCompletion: completion)
    }
}


