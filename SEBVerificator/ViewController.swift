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

class ViewController: NSViewController, ProcessListViewControllerDelegate {
    
    @IBOutlet var applicationsArrayController: NSArrayController!
    @IBOutlet var configsArrayController: NSArrayController!
    @IBOutlet var consoleTextView: NSTextView!
    var foundSEBApplications: [SEBApplication] = []
    var sebConfigFiles: [SEBConfigFile]?
    
    var verificationManager: VerificationManager?

    lazy var processListViewController: ProcessListViewController? = {
        let viewController = ProcessListViewController.init(nibName: "ProcessListView", bundle: nil)
        viewController.delegate = self
        return viewController
    }()
    var runningProcessesListWindowController: NSWindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ValueTransformer.setValueTransformer(ValidSEBColorTransformer(), forName: .validSEBColorTransformer)

//        NSWorkspace.shared.addObserver(self, forKeyPath: "runningApplications", options: [.new, .old], context: nil)

        // Do any additional setup after loading the view.
        verificationManager = VerificationManager()
        
        let foundSEBAlikeStrings = findAllSEBAlikes()
        sebConfigFiles = findSEBConfigFiles()
        configsArrayController.content = sebConfigFiles
        
        for sebAlikeString in foundSEBAlikeStrings {
            print(sebAlikeString)
        }
    }
        
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "runningApplications" {
            guard let changedObjects = change else {
                return
            }
            guard let terminatedProcesses = changedObjects[.oldKey] as? Array<NSRunningApplication> else {
                return
            }
            if terminatedProcesses.count > 0 {
                print(terminatedProcesses)
            }
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
    
    func terminateDockAppsWithCallback(selector: Selector) {
        let runningApplications = NSWorkspace.shared.runningApplications
        var notTerminatedApplications: [NSRunningApplication]?
#if DEBUG
        let debug = true
        #else
        let debug = false
#endif
        for runningApplication in runningApplications {
            if runningApplication.bundleIdentifier != "org.safeexambrowser.SEBVerificator" &&
                (debug && runningApplication.bundleIdentifier != "com.apple.dt.Xcode") {
                if runningApplication.activationPolicy == .regular {
                    let success = runningApplication.terminate()
                    if !success || !runningApplication.isTerminated {
                        notTerminatedApplications = (notTerminatedApplications ?? []) + [runningApplication]
                    }
                }
            }
        }
        if notTerminatedApplications != nil && notTerminatedApplications!.count > 0 {
            terminateAppsWithCallback(notTerminatedApplications!, forceQuit: false, selector: selector)
        } else {
            perform(selector)
        }
    }
    
    func terminateSEBAlikesWithCallback(selector: Selector) {
        let allSEBAlikeBundleIDs = NSMutableSet()
        allSEBAlikeBundleIDs.addObjects(from: foundSEBApplications.map {$0.bundleID})
        let sebAppBundleIDs = allSEBAlikeBundleIDs.allObjects as! [String]
        var notTerminatedApplications: [NSRunningApplication]?
        for bundleID in sebAppBundleIDs {
            if bundleID != "org.safeexambrowser.SEBVerificator" {
                let runningApplications = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                if !runningApplications.isEmpty {
                    let newNotTerminatedApplications = kill(runningApplications: runningApplications)
                    if newNotTerminatedApplications != nil {
                        notTerminatedApplications = (notTerminatedApplications ?? []) + newNotTerminatedApplications!
                    }
                }
            }
        }
        if notTerminatedApplications != nil && notTerminatedApplications!.count > 0 {
            terminateAppsWithCallback(notTerminatedApplications!, forceQuit: true, selector: selector)
        } else {
            perform(selector)
        }
    }
    
    func terminateAppsWithCallback(_ apps: [NSRunningApplication], forceQuit: Bool, selector: Selector) {
        guard let processListController = processListViewController else {
            return
        }
        processListController.runningApplications = NSMutableArray(array: apps)
        processListController.callback = self
        processListController.selector = selector
        processListController.autoQuitApplications = forceQuit
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        
        let runningProcessesListWindow = NSWindow(contentViewController: processListController)
        runningProcessesListWindow.level = .modalPanel
        runningProcessesListWindow.title = NSLocalizedString("Applications Must Be Terminated", comment: "Title for window with list of running SEB-like applications to be terminated")
        let processListWindowController = NSWindowController(window: runningProcessesListWindow)
        runningProcessesListWindowController = processListWindowController
        // Check if the process wasn't closed in the meantime (race condition)
        if processListViewController != nil &&
            processListViewController!.runningApplications.count +
            processListViewController!.runningProcesses.count > 0 {
            runningProcessesListWindow.delegate = self.processListViewController
            runningProcessesListWindowController?.showWindow(self)
        }
    }
    
    func kill(runningApplications: [NSRunningApplication]) -> [NSRunningApplication]? {
        var notTerminatedApplications: [NSRunningApplication]?
        for runningApplication in runningApplications {
            NSLog("Terminating running application \(runningApplication)")
            let killSuccess = runningApplication.kill()
            NSLog("Success of terminating running application: \(killSuccess)")
            if killSuccess != ESRCH && (killSuccess != ERR_SUCCESS || !runningApplication.isTerminated) { // ESRCH: No such process
                notTerminatedApplications = (notTerminatedApplications ?? []) + [runningApplication]
            }
        }
        return notTerminatedApplications
    }
    
    @IBAction func startSEBTerminatingApps(_ sender: Any) {
        terminateDockAppsWithCallback(selector: #selector(startSEBTerminatingAlikes))
    }
    
    @objc func startSEBTerminatingAlikes() {
        startSEB(self)
    }
    
    @IBAction func startSEB(_ sender: Any) {
        terminateSEBAlikesWithCallback(selector: #selector(startSEBApp))
    }
    
    @objc func startSEBApp() {
        guard let selectedSEBApp = applicationsArrayController.selectedObjects[0] as? SEBApplication else {
            return
        }
        if selectedSEBApp.validSEB {
            if selectedSEBApp.defaultSEB == false ||
                selectedSEBApp.defaultSEB && (foundSEBApplications.map {$0.defaultSEB}).count > 1 {
                let alert = NSAlert.init()
                alert.messageText = NSLocalizedString("Warning About Selected SEB Version", comment: "")
                alert.informativeText = (!selectedSEBApp.defaultSEB ? NSLocalizedString("You are about to start an SEB version which isn't registered as the default application in the system to open .seb files and seb(s):// links", comment: "") : NSLocalizedString("You are about to start an SEB version which isn't registered as default app to open both .seb files and seb(s):// links. This is inconsistent and an issue for exams not started with SEB Verificator. ", comment: "")) + "\n\n" + NSLocalizedString("We recommend to delete/archive all other SEB versions to prevent that exams are started in the wrong SEB version.", comment: "")
                alert.alertStyle = .critical
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                alert.beginSheetModal(for: self.view.window!) { answer in
                    switch answer {
                    case .alertFirstButtonReturn:
                        self.startSEBApplication(selectedSEBApp)
                    case .alertSecondButtonReturn:
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    func startSEBApplication(_ selectedSEBApp: SEBApplication) {
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
            NSWorkspace.shared.openApplication(at: URL.init(fileURLWithPath: selectedSEBApp.path, isDirectory: true),
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
                try NSWorkspace.shared.launchApplication(at: URL.init(fileURLWithPath: selectedSEBApp.path, isDirectory: true), configuration: [NSWorkspace.LaunchConfigurationKey.arguments : configFileArguments])
            } catch {
                // Cannot open application
                return
            }
            NSApp.terminate(self)
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

    // ProcessListViewControllerDelegate methods
    
    var quittingSession = false

    func checkProcessesRunning(_ runningProcesses: NSMutableArray) -> NSMutableArray {
        return []
    }
    
    func closeProcessListWindow() {
        runningProcessesListWindowController?.window?.delegate = nil
        runningProcessesListWindowController?.close()
        processListViewController = nil
    }
    
    func closeProcessListWindow(withCallback callback: Any?, selector: Selector) {
        closeProcessListWindow()
        perform(selector)
    }
    
    func newAlert() -> NSAlert {
        return NSAlert()
    }
    
    func removeAlert(_ window: NSWindow) {
    }
    
    func runModalAlert(_ alert: NSAlert, conditionallyFor window: NSWindow, completionHandler handler: ((NSApplication.ModalResponse) -> Void)? = nil) {
        let answer = alert.runModal()
        if handler != nil {
            handler!(answer)
        }
    }
    
    func quitSEBOrSession() {
        startSEBTerminatingAlikes()
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
