//
//  SEBServerLightUIViewController.swift
//  SEB
//
//  Created by Daniel Schneider on 05.02.24.
//

import Foundation

class SEBServerLightUIViewController: UITableViewController {
    
    var results: [NWBrowser.Result] = [NWBrowser.Result]()
    var name: String = "Default"
    var passcode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen immediately upon startup.
        applicationServiceListener = PeerListener(delegate: self)
        
        if sharedBrowser == nil {
            sharedBrowser = PeerBrowser(delegate: self)
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "serverInstanceCell")
    }
    
    @objc public func startDiscovery() {
        
        if sharedBrowser == nil {
            sharedBrowser = PeerBrowser(delegate: self)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return results.count > 0 ? "Nearby SEB Server Light" : "Searching Nearby SEB Server Light"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let serverInstanceCell = tableView.dequeueReusableCell(withIdentifier: "serverInstanceCell") ?? UITableViewCell(style: .default, reuseIdentifier: "serverInstanceCell")
        let peerEndpoint = results[indexPath.row].endpoint
        if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = peerEndpoint {
            serverInstanceCell.textLabel?.text = name
        } else {
            serverInstanceCell.textLabel?.text = "Unknown Endpoint"
        }
        serverInstanceCell.textLabel?.textAlignment = .left
        serverInstanceCell.textLabel?.textColor = .black
        return serverInstanceCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if sharedBrowser == nil {
                sharedBrowser = PeerBrowser(delegate: self)
            } else if !results.isEmpty {
                // Handle the user tapping a discovered server
                let result = results[indexPath.row]
                performSegue(withIdentifier: "showPasscodeSegue", sender: result)
            }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SEBServerLightUIViewController: PeerBrowserDelegate {
    // When the discovered peers change, update the list.
    func refreshResults(results: Set<NWBrowser.Result>) {
        self.results = [NWBrowser.Result]()
        for result in results {
            if case let NWEndpoint.url(url) = result.endpoint {
                let host = url.host()
                let port = url.port
                print("Endpoint found with URL \(url), host \(String(describing: host)), port \(String(describing: port))")
            }
            if case let NWEndpoint.service(name: name, type: _, domain: domain, interface: _) = result.endpoint {
                print("Endpoint domain: \(domain)")
                if name != self.name {
                    self.results.append(result)
                }
            }
        }
        tableView.reloadData()
    }

    // Show an error if peer discovery fails.
    func displayBrowseError(_ error: NWError) {
        var message = "Error \(error)"
        if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
            message = "Not allowed to access the network"
        }
        let alert = UIAlertController(title: "Cannot discover other players",
                                      message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

extension SEBServerLightUIViewController: PeerConnectionDelegate {
    // When a connection becomes ready, move into game mode.
    func connectionReady() {

    }

    // When the you can't advertise a game, show an error.
    func displayAdvertiseError(_ error: NWError) {
        var message = "Error \(error)"
        if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
            message = "Not allowed to access the network"
        }
        let alert = UIAlertController(title: NSLocalizedString("Cannot Connect to SEB Server Light", comment: ""),
                                      message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    // Ignore connection failures and messages prior to starting a game.
    func connectionFailed() { }
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message) { }
}

