//
//  ViewController.swift
//  SEBVerificator
//
//  Created by Daniel Schneider on 11.07.22.
//

import Foundation
import Cocoa
import CoreServices

public struct strings {
    static let sebBundleID = "org.safeexambrowser.SafeExamBrowser"
    static let sebFileExtension = "seb"
    static let sebURLScheme = "seb"
    static let sebsURLScheme = "seb"
    static let applicationDirectory = "/Applications/"
}

class ViewController: NSViewController {
    
    @IBOutlet var applicationsArrayController: NSArrayController!
    var foundSEBApplications: [SEBApplication] = []
    @IBOutlet var consoleTextView: NSTextView!
    var sebConfigFiles: [String]?
    
    var verificationManager: VerificationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ValueTransformer.setValueTransformer(ValidSEBColorTransformer(), forName: .validSEBColorTransformer)

        // Do any additional setup after loading the view.
        verificationManager = VerificationManager()
        
        let foundSEBAlikeStrings = findAllSEBAlikes()
        sebConfigFiles = findSEBConfigFiles()
        
        for sebAlikeString in foundSEBAlikeStrings {
            print(sebAlikeString)
        }
    }

    func findAllSEBAlikes() -> ([NSAttributedString]) {
        let allSEBAlikeBundleIDs = NSMutableSet()
        let allSEBAlikeURLs = NSMutableSet()
        var allSEBAlikeLog = [NSAttributedString]()
        
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forFileExtension: strings.sebFileExtension))
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forURLScheme: strings.sebURLScheme))
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forURLScheme: strings.sebsURLScheme))
        for sebAlikeBundleID in allSEBAlikeBundleIDs {
            if let sebAlikeURLs = LSCopyApplicationURLsForBundleIdentifier(sebAlikeBundleID as! CFString, nil)?.takeRetainedValue() as? [URL] {
                allSEBAlikeURLs.addObjects(from: sebAlikeURLs)
                for sebAlikeURL in sebAlikeURLs {
                    let icon = NSWorkspace.shared.icon(forFile: sebAlikeURL.path)
                    let name = sebAlikeURL.deletingPathExtension().lastPathComponent
                    let version = Bundle(path: sebAlikeURL.path)?.fullVersion
                    let validSEB = (sebAlikeBundleID as! String == strings.sebBundleID && verifySignature(path: sebAlikeURL.path))
                    let signature = validSEB ? NSLocalizedString("OK", comment: "Signature OK") : NSLocalizedString("Invalid", comment: "Invalid signature")
                    foundSEBApplications.append(SEBApplication.init(icon: icon, name: name, version: version ?? "", bundleID: sebAlikeBundleID as! String, path: sebAlikeURL.path, signature: signature, validSEB: validSEB))
                }
             }
        }
        // Sort found SEB-alike apps so that the correct BundleID and Application folder location is first
        foundSEBApplications = foundSEBApplications.sorted(by: { sebApp1, sebApp2 in
            guard sebApp1.validSEB else {
                return sebApp2.validSEB
            }
            guard sebApp2.validSEB else {
                return sebApp1.validSEB
            }
            return sebApp1.path.hasPrefix(strings.applicationDirectory)
        })
        foundSEBApplications = foundSEBApplications.sorted(by: { sebApp1, sebApp2 in
            guard sebApp1.bundleID != strings.sebBundleID && sebApp1.validSEB else {
                return sebApp2.bundleID != strings.sebBundleID
            }
            guard sebApp2.bundleID != strings.sebBundleID && sebApp2.validSEB else {
                return sebApp1.bundleID != strings.sebBundleID
            }
            return true
        })
        applicationsArrayController.content = foundSEBApplications
        return allSEBAlikeLog
    }
    
    func findSEBConfigFiles() -> [String]? {
        let appDirectoryURL = Bundle.main.bundleURL.deletingLastPathComponent()
        let files = FileManager.default.enumerator(atPath: appDirectoryURL.path)
        var foundSEBConfigFiles = [String]()
        while let file = files?.nextObject() as? String {
            if file.hasSuffix("."+strings.sebFileExtension) {
                foundSEBConfigFiles.append(file)
            }
        }
        return foundSEBConfigFiles
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
    
    @IBAction func startSEB(_ sender: Any) {
        guard let selectedSEBApp = applicationsArrayController.selectedObjects[0] as? SEBApplication else {
            return
        }
        if selectedSEBApp.validSEB {
            let appDirectoryURL = Bundle.main.bundleURL.deletingLastPathComponent()
            var argumentURL: URL?
            if sebConfigFiles?.count ?? 0 > 0 {
                argumentURL = appDirectoryURL.appendingPathComponent("/\(sebConfigFiles?[0] ?? "")")
            }
            let configFileArguments = argumentURL != nil ? [argumentURL!.absoluteString] : []
            if #available(macOS 10.15, *) {
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.arguments = configFileArguments
                NSWorkspace.shared.openApplication(at: URL.init(fileURLWithPath: selectedSEBApp.path),
                                                   configuration: configuration,
                                                   completionHandler: { (app, error) in
                                                    if app == nil {
                                                        print("starting \(selectedSEBApp) failed with error: \(String(describing: error))")
                                                    } else {
                                                        NSApp.terminate(self)
                                                    }
                                                   })
            } else {
                do {
                    try NSWorkspace.shared.launchApplication(at: URL.init(fileURLWithPath: selectedSEBApp.path), configuration: [NSWorkspace.LaunchConfigurationKey.arguments : configFileArguments])
                } catch {
                    // Cannot open application
                    return
                }
                NSApp.terminate(self)
            }
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
    @objc var validSEB: Bool
    
    init(icon: NSImage?, name: String, version: String, bundleID: String, path: String, signature: String, validSEB: Bool) {
        self.icon = icon
        self.name = name
        self.version = version
        self.bundleID = bundleID
        self.path = path
        self.signature = signature
        self.validSEB = validSEB
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

class ValidSEBColorTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSColor.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        return (value as! Bool) ? NSColor.black : NSColor.systemRed
    }
}

extension NSValueTransformerName {
    static let validSEBColorTransformer = NSValueTransformerName(rawValue: "ValidSEBColorTransformer")
}
