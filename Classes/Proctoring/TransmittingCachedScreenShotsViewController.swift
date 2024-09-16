//
//  TransmittingCachedScreenShotsViewController.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 27.08.2024.
//

import Foundation
import Cocoa

class TransmittingCachedScreenShotsViewController: NSViewController {

    @IBOutlet weak var message: NSTextField!
    @IBOutlet weak var operations: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var quitButton: NSButton!
    
    @objc weak public var uiDelegate: SPSControllerUIDelegate?
    
    @IBAction func quitButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "requestQuitNotification"), object: self))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
