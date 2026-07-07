//
//  File.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 09.07.2024.
//

import Foundation
import Security

@objc public protocol ApplicationsPreferencesDelegate: AnyObject {
    func selectedPermittedProccessChanged()
    func selectedProhibitedProccessChanged()
}

@objc class PermittedProcessesArrayController: NSArrayController {
    
    @IBOutlet weak var prefsApplicationsDelegate: ApplicationsPreferencesDelegate?
    
    override func newObject() -> Any {
        var newObject: NSDictionary
        newObject = super.newObject() as! NSDictionary
        newObject = UserDefaults.standard.getDefaultDictionary(forKey: "permittedProcesses") as NSDictionary
        let mutableDictionary = newObject.mutableCopy()
        return mutableDictionary
    }
    
    override func addObject(_ object: Any) {
        super.addObject(object)
        self.removeSelectedObjects(self.selectedObjects)
        self.setSelectedObjects([object])
        self.prefsApplicationsDelegate?.selectedPermittedProccessChanged()
    }
    
    override func remove(_ sender: Any?) {
        let selectedObjectIndex = self.selectionIndex
        super.remove(sender)
        if selectedObjectIndex != 0 {
            _ = self.setSelectionIndex(selectedObjectIndex-1)
        }
    }
    
    @objc public func addApp(bundle: Bundle) {
        var newPermittedProcess: NSDictionary
        newPermittedProcess = newObject() as! NSDictionary
        let bundleID = bundle.bundleIdentifier
        var appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let executable = bundle.object(forInfoDictionaryKey: "CFBundleExecutable")
        if (appName ?? "").isEmpty {
            appName = executable as? String
        }
        let teamIdentifier = teamIdentifier(for: bundle)
        newPermittedProcess.setValue(bundleID, forKey: "identifier")
        newPermittedProcess.setValue(appName, forKey: "title")
        newPermittedProcess.setValue(executable, forKey: "executable")
        newPermittedProcess.setValue(teamIdentifier, forKey: "teamIdentifier")
        addObject(newPermittedProcess)
    }

    /// Extracts the Team Identifier from the code signature of the app bundle.
    /// Returns an empty string if the app isn't signed or the Team Identifier can't be read.
    private func teamIdentifier(for bundle: Bundle) -> String {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(bundle.bundleURL as CFURL, [], &staticCode) == errSecSuccess,
              let code = staticCode else {
            return ""
        }
        var signingInformation: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &signingInformation) == errSecSuccess,
              let info = signingInformation as? [String: Any],
              let teamIdentifier = info[kSecCodeInfoTeamIdentifier as String] as? String else {
            return ""
        }
        return teamIdentifier
    }
}
