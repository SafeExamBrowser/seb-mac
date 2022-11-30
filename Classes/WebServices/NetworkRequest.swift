//
//  NetworkRequest.swift
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
    fileprivate func load(_ url: URL, httpMethod: String, body: String, headers: [AnyHashable: Any]?, timeout: Double, attempt: Int, withCompletion completion: @escaping ((Model?), Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue(keys.acceptJSON, forHTTPHeaderField: keys.headerAccept)
        if let additionalHeaders = headers {
            for header in additionalHeaders {
                request.addValue(header.value as? String ?? "", forHTTPHeaderField: header.key as? String ?? "")
            }
        }
        request.httpBody = body.data(using: .utf8)
        let currentAttempt = attempt+1
        
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode
            var errorResponse: ErrorResponse? = nil
            let responseHeaders = httpResponse?.allHeaderFields
            if error != nil {
                DDLogError("URLSession.dataTask returned error: \(String(describing: error))")
            }
            guard let receivedData = data else {
                DDLogError("Network Request didn't return response data (status code: \(String(describing: statusCode)))")
                completion(nil, statusCode, nil, [:], currentAttempt)
                return
            }
            if statusCode == nil || statusCode ?? 0 >= statusCodes.notSuccessfullRange {
                // Some error happened
                if statusCode == statusCodes.unauthorized {
                    if let unauthorizedErrorResponse = self?.decodeErrorResponse(receivedData) {
                        errorResponse = unauthorizedErrorResponse
                    }
                } else if statusCode == statusCodes.internalServerError {
                    if let internalServerErrorResponse = self?.decodeServerErrorResponse(receivedData) {
                        errorResponse = internalServerErrorResponse
                    }
                } else if (data != nil) {
                    let errorObjectString = String(decoding: data!, as: UTF8.self)
                    errorResponse = ErrorResponse(error: "Network Request load returned unspecified error object", error_description: errorObjectString)
                    DDLogError("\(errorResponse?.error ?? ""): \(errorResponse?.error_description ?? "Unspecified"))")
                } else {
                    DDLogError("Network Request load returned unspecified error.")
                }
                completion(nil, statusCode, errorResponse, [:], currentAttempt)
                return
            }

            completion(self?.decode(receivedData), statusCode, errorResponse, responseHeaders, currentAttempt)
        })
        task.resume()
    }
    
    fileprivate func decodeErrorResponse(_ data: Data) -> ErrorResponse? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            return try decoder.decode(ErrorResponse.self, from: data)
        } catch let error {
            return ErrorResponse(error: "\(NSLocalizedString("decoding error: ", comment: "") + error.localizedDescription)", error_description: String(describing: error))
        }
    }

    fileprivate func decodeServerErrorResponse(_ data: Data) -> ErrorResponse? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            let serverErrorResponse = try decoder.decode(ServerErrorResponse.self, from: data)
            if serverErrorResponse.systemMessage != errors.generic {
                return ErrorResponse(error: serverErrorResponse.systemMessage, error_description: serverErrorResponse.details)
            } else {
                return ErrorResponse(error: serverErrorResponse.details, error_description: nil)
            }
        } catch let error {
            return ErrorResponse(error: "\(NSLocalizedString("decoding error: ", comment: "") + error.localizedDescription)", error_description: String(describing: error))
        }
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

    func load(httpMethod: String, body: String, headers: [AnyHashable: Any]?, timeout: Double, attempt: Int, completion: @escaping ((Resource.Model?), Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        load(resource.url, httpMethod: httpMethod, body: body, headers: headers, timeout: timeout, attempt: attempt, withCompletion: completion)
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
    
    func load(httpMethod: String, body: String, headers: [AnyHashable: Any]?, timeout: Double, attempt: Int, completion: @escaping ((Data?), Int?, ErrorResponse?, [AnyHashable: Any]?, Int) -> Void) {
        load(resource.url, httpMethod: httpMethod, body: body, headers: headers, timeout: timeout, attempt: attempt, withCompletion: completion)
    }
}
