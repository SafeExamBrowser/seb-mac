//
//  TransmittingCachedScreenShotsViewController.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 27.08.2024.
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
