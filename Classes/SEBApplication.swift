//
//  SEBApplication.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 04.05.24.
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
// Custom application subclass that attempts to block text replacement.
// In Info, set "Principal Class" to $(PRODUCT_MODULE_NAME).MyApplication  (instead of 'NSApplication')

import Cocoa


class SEBApplication: NSApplication {
    override init() {
        
        /*
         Clear out the global dictionary of replacement items
         (just for this app) before any UI stuff gets going.
         
         To undo this for testing,
         
         defaults remove com.example.shayman.BlockAutocomplete NSUserDictionaryReplacementItems
         
         */
        
        UserDefaults.standard.setValue([:], forKey:"NSUserDictionaryReplacementItems")
        UserDefaults.standard.setValue(false, forKey:"NSAllowContinuousSpellChecking")
        UserDefaults.standard.setValue(false, forKey:"NSAutomaticSpellingCorrectionEnabled")
        UserDefaults.standard.setValue(false, forKey:"NSAutomaticTextCompletionEnabled")
        UserDefaults.standard.setValue(false, forKey:"NSAutomaticInlinePredictionEnabled")
        UserDefaults.standard.setValue(false, forKey:"WebContinuousSpellCheckingEnabled")
        UserDefaults.standard.setValue(false, forKey:"WebAutomaticSpellingCorrectionEnabled")
        UserDefaults.standard.setValue(false, forKey:"WebGrammarCheckingEnabled")
        UserDefaults.standard.setValue(false, forKey:"WebAutomaticTextReplacementEnabled")
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
