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
    static let sebsURLScheme = "sebs"
    static let applicationDirectory = "/Applications/"
}

class ViewController: NSViewController {
    
    @IBOutlet var applicationsArrayController: NSArrayController!
    @IBOutlet var configsArrayController: NSArrayController!
    @IBOutlet var consoleTextView: NSTextView!
    var foundSEBApplications: [SEBApplication] = []
    var sebConfigFiles: [SEBConfigFile]?
    
    var verificationManager: VerificationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ValueTransformer.setValueTransformer(ValidSEBColorTransformer(), forName: .validSEBColorTransformer)

        // Do any additional setup after loading the view.
        verificationManager = VerificationManager()
        
        let foundSEBAlikeStrings = findAllSEBAlikes()
        sebConfigFiles = findSEBConfigFiles()
        configsArrayController.content = sebConfigFiles
        
        for sebAlikeString in foundSEBAlikeStrings {
            print(sebAlikeString)
        }
    }

    func findAllSEBAlikes() -> ([NSAttributedString]) {
        let allSEBAlikeBundleIDs = NSMutableSet()
        let allSEBAlikeURLs = NSMutableSet()
        var allSEBAlikeLog = [NSAttributedString]()
        foundSEBApplications.removeAll()
        
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forFileExtension: strings.sebFileExtension))
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forURLScheme: strings.sebURLScheme))
        allSEBAlikeBundleIDs.addObjects(from: verificationManager!.associatedApps(forURLScheme: strings.sebsURLScheme))
        let defaultAppForSEBFileExtension = verificationManager!.defaultApp(forFileExtension: strings.sebFileExtension)
        let defaultAppForSEBScheme = verificationManager!.defaultApp(forURLScheme: strings.sebURLScheme)
        let defaultAppForSEBSScheme = verificationManager!.defaultApp(forURLScheme: strings.sebsURLScheme)
        for sebAlikeBundleID in allSEBAlikeBundleIDs {
            if let sebAlikeURLs = LSCopyApplicationURLsForBundleIdentifier(sebAlikeBundleID as! CFString, nil)?.takeRetainedValue() as? [URL] {
                allSEBAlikeURLs.addObjects(from: sebAlikeURLs)
                for sebAlikeURL in sebAlikeURLs {
                    let icon = NSWorkspace.shared.icon(forFile: sebAlikeURL.path)
                    let name = sebAlikeURL.deletingPathExtension().lastPathComponent
                    let version = Bundle(path: sebAlikeURL.path)?.fullVersion
                    let validSEB = (sebAlikeBundleID as! String == strings.sebBundleID && verifySignature(path: sebAlikeURL.path))
                    let signature = validSEB ? NSLocalizedString("OK", comment: "Signature OK") : NSLocalizedString("Invalid", comment: "Invalid signature")
                    
                    var defaultFor = ""
                    if sebAlikeURL == defaultAppForSEBFileExtension {
                        defaultFor = defaultFor.setOrAppend("." + strings.sebFileExtension)
                    }
                    if sebAlikeURL == defaultAppForSEBScheme {
                        defaultFor = defaultFor.setOrAppend(strings.sebURLScheme + "://")
                    }
                    if sebAlikeURL == defaultAppForSEBSScheme {
                        defaultFor = defaultFor.setOrAppend(strings.sebsURLScheme + "://")
                    }
                    foundSEBApplications.append(SEBApplication.init(icon: icon, name: name, version: version ?? "", bundleID: sebAlikeBundleID as! String, path: sebAlikeURL.path, signature: signature, validSEB: validSEB, defaultFor: defaultFor, defaultSEB: defaultFor.count != 0))
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
            return sebApp1.path.hasPrefix(strings.applicationDirectory) && sebApp1.defaultSEB
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
    
    func findSEBConfigFiles() -> [SEBConfigFile]? {
        let appDirectoryURL = Bundle.main.bundleURL.deletingLastPathComponent()
        let files = FileManager.default.enumerator(atPath: appDirectoryURL.path)
        var foundSEBConfigFiles = [SEBConfigFile]()
        while let file = files?.nextObject() as? String {
            if file.hasSuffix("."+strings.sebFileExtension) {
                foundSEBConfigFiles.append(SEBConfigFile.init(path: file))
            }
        }
        foundSEBConfigFiles = foundSEBConfigFiles.sorted { $0.path.lowercased() < $1.path.lowercased() }
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
            if sebConfigFiles?.count ?? 0 > 0 && !configsArrayController.selectedObjects.isEmpty {
                if let selectedConfigFile = configsArrayController.selectedObjects[0] as? SEBConfigFile {
                    argumentURL = appDirectoryURL.appendingPathComponent(selectedConfigFile.path)
                }
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
                                                        DispatchQueue.main.async {
                                                            NSApp.terminate(self)
                                                        }
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
    @objc var defaultFor: String
    @objc var defaultSEB: Bool

    init(icon: NSImage?, name: String, version: String, bundleID: String, path: String, signature: String, validSEB: Bool, defaultFor: String, defaultSEB: Bool) {
        self.icon = icon
        self.name = name
        self.version = version
        self.bundleID = bundleID
        self.path = path
        self.signature = signature
        self.validSEB = validSEB
        self.defaultFor = defaultFor
        self.defaultSEB = defaultSEB
    }
}

@objc class SEBConfigFile : NSObject {
    @objc var path: String
    
    init(path: String) {
        self.path = path
    }
}

extension String {
    func setOrAppend(_ toString: String) -> String {
        var returnString: String
        if self.count == 0 {
            returnString = toString
        } else {
            returnString = self + ", " + toString
        }
        return returnString
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
