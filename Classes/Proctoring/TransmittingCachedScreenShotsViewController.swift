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
       
    @objc weak public var uiDelegate: SPSControllerUIDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
