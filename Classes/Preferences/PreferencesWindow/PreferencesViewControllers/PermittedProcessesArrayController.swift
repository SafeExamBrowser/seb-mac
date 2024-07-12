//
//  File.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 09.07.2024.
//

import Foundation
//import Cocoa
//import AppKit

@objc public protocol ApplicationsPreferencesDelegate: AnyObject {
    func selectedPermittedProccessChanged()
}

@objc class PermittedProcessesArrayController: NSArrayController {
    
    @objc weak public var prefsApplicationsViewController: ApplicationsPreferencesDelegate?
    
    override func newObject() -> Any {
        let newObject: NSDictionary
        newObject = UserDefaults.standard.getDefaultDictionary(forKey: "permittedProcesses") as NSDictionary
        let mutableDictionary = newObject.mutableCopy()
        return mutableDictionary
    }
    
    override func addObject(_ object: Any) {
        super.addObject(object)
        self.removeSelectedObjects(self.selectedObjects)
        self.setSelectedObjects([object])
    }
    
    override func remove(_ sender: Any?) {
        let selectedObjectIndex = self.selectionIndex
        super.remove(sender)
        if selectedObjectIndex != 0 {
            _ = self.setSelectionIndex(selectedObjectIndex-1)
        }
    }
    
    override func setSelectionIndex(_ index: Int) -> Bool {
        prefsApplicationsViewController?.selectedPermittedProccessChanged()
        return super.setSelectionIndex(index)
    }
}
