//
//  NetworkRequest.swift
//
//  Created by Daniel R. Schneider on 15.10.18.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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


