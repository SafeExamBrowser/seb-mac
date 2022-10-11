//
//  SEBNetworkManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 05.07.22.
//  About the original author: https://stackoverflow.com/a/67758105/705761
//

import Foundation
import Network

@available(iOS 14.0, *)
@objc public class LocalNetworkAuthorizationManager: NSObject {
    private var browser: NWBrowser?
    private var netService: NetService?
    private var completion: ((Bool) -> Void)?
    
    @objc public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        
        // Create parameters, and allow browsing over peer-to-peer link.
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        // Browse for a custom service type.
        let browser = NWBrowser(for: .bonjour(type: "_bonjour._tcp", domain: nil), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                DDLogError("Requesting local network permission failed: \(error.debugDescription) \(error.localizedDescription)")
            case .ready, .cancelled:
                break
            case let .waiting(error):
                DDLogError("Local network permission has been denied: \(error)")
                self.reset()
                self.completion?(false)
            default:
                break
            }
        }
        
        self.netService = NetService(domain: "local.", type:"_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
        self.netService?.delegate = self
        
        self.browser?.start(queue: .main)
        self.netService?.publish()
    }
    
    private func reset() {
        self.browser?.cancel()
        self.browser = nil
        self.netService?.stop()
        self.netService = nil
    }
}

@available(iOS 14.0, *)
extension LocalNetworkAuthorizationManager : NetServiceDelegate {
    public func netServiceDidPublish(_ sender: NetService) {
        self.reset()
        DDLogInfo("Local network permission available")
        completion?(true)
    }
}
