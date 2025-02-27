//
//  SEBiOSTransmittingCachedScreenShotsViewController.swift
//  SEB
//
//  Created by Daniel Schneider on 20.09.2024.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
        uiDelegate?.closeTransmittingCachedScreenShotsWindow {
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "quitExamConditionally"), object: self))
        }
    }
}
