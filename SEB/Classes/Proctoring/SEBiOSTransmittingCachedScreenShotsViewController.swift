//
//  SEBiOSTransmittingCachedScreenShotsViewController.swift
//  SEB
//
//  Created by Daniel Schneider on 20.09.2024.
//

import Foundation
import UIKit

class SEBiOSTransmittingCachedScreenShotsViewController: UIViewController {
    
    @IBOutlet weak var windowTitle: UILabel!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var operations: UILabel!
    @IBOutlet weak var quitButton: UIButton!
    
    @IBOutlet weak var alertView: UIView!
    
    @objc weak public var uiDelegate: SPSControllerUIDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertView.layer.cornerRadius = 8.0
        alertView.layer.shadowColor = UIColor.black.cgColor
        alertView.layer.shadowOpacity = 0.2
        alertView.layer.shadowOffset = .zero
        alertView.layer.shadowRadius = 10
    }
    
    @IBAction func quitButtonTapped(_ sender: Any) {
        uiDelegate?.closeTransmittingCachedScreenShotsWindow()
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "requestQuit"), object: self))
    }
}
