//
//  ViewController.swift
//  SEBVerificator
//
//  Created by Daniel Schneider on 11.07.22.
//

import Foundation
import Cocoa
import CoreServices

class ViewController: NSViewController {

    @IBOutlet var applicationsArrayController: NSArrayController!
    var foundSEBApplications: [SEBApplication] = []
    @IBOutlet var consoleTextView: NSTextView!
    
    var verificationManager: VerificationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        verificationManager = VerificationManager()
        
        let foundSEBAlikeStrings = findAllSEBAlikes()
        
        for sebAlikeString in foundSEBAlikeStrings {
            print(sebAlikeString)
        }
    }

    func findAllSEBAlikes() -> ([NSAttributedString]) {
        let allSEBAlikeBundleIDs = NSMutableSet()
        let allSEBAlikeURLs = NSMutableSet()
        var allSEBAlikeLog = [NSAttributedString]()
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forFileExtension: "seb"))
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forURLScheme: "seb"))
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forURLScheme: "sebs"))
        for sebAlikeBundleID in allSEBAlikeBundleIDs {
            if let sebAlikeURLs = LSCopyApplicationURLsForBundleIdentifier(sebAlikeBundleID as! CFString, nil)?.takeRetainedValue() as? [URL] {
                allSEBAlikeURLs.addObjects(from: sebAlikeURLs)
                for sebAlikeURL in sebAlikeURLs {
                    let icon = NSWorkspace.shared.icon(forFile: sebAlikeURL.path)
                    let name = sebAlikeURL.deletingPathExtension().lastPathComponent
                    let version = Bundle(path: sebAlikeURL.path)?.fullVersion
                    let signature = verifySignature(path: sebAlikeURL.path) ? "OK" : "Invalid"
                    foundSEBApplications.append(SEBApplication.init(icon: icon, name: name, version: version ?? "", bundleID: sebAlikeBundleID as! String, path: sebAlikeURL.absoluteString, signature: signature))
                }
             }
        }
        applicationsArrayController.content = foundSEBApplications
        return allSEBAlikeLog
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func rescanForSEBAlikes(_ sender: Any) {
        let foundSEBAlikeStrings = findAllSEBAlikes()
        
        for sebAlikeString in foundSEBAlikeStrings {
            print(sebAlikeString)
        }
    }
    
    func verifySignature(path: String) -> Bool {
        verificationManager!.signedSEBExecutable(path)
    }
    
    func updateConsole(logEntries: [NSAttributedString]) {
        let signatureOK = true
        let outputString = "" //"\(sebPath) is \(signatureOK ? "" : "NOT ")an original SEB version!"
        let mutableAttributedOutputString = NSMutableAttributedString.init(string: outputString)
        let range = (outputString as NSString).range(of: outputString)
        mutableAttributedOutputString.addAttribute(NSAttributedString.Key.foregroundColor, value: (signatureOK ? NSColor.black : NSColor.red), range: range)

        consoleTextView.textContainer?.textView?.textStorage?.setAttributedString(mutableAttributedOutputString.copy() as! NSAttributedString)
    }
}

@objc class SEBApplication : NSObject {
    @objc var icon: NSImage?
    @objc var name: String
    @objc var version: String
    @objc let bundleID: String
    @objc var path: String
    @objc var signature: String
    
    init(icon: NSImage?, name: String, version: String, bundleID: String, path: String, signature: String) {
        self.icon = icon
        self.name = name
        self.version = version
        self.bundleID = bundleID
        self.path = path
        self.signature = signature
    }
}

extension Bundle {

    var shortVersion: String {
        if let result = infoDictionary?["CFBundleShortVersionString"] as? String {
            return result
        } else {
            assert(false)
            return ""
        }
    }

    var buildVersion: String {
        if let result = infoDictionary?["CFBundleVersion"] as? String {
            return result
        } else {
            assert(false)
            return ""
        }
    }

    var fullVersion: String {
        return "\(shortVersion)(\(buildVersion))"
    }
}
