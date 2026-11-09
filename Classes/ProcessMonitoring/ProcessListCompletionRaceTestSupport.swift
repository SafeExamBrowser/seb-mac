//
//  ProcessListCompletionRaceTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge exposing the prohibited-process window completion to the Swift
//  unit test target, which links the app module but cannot see Objective-C classes
//  directly. Regression coverage for the duplicated force-quit completion bug: after
//  force quitting all prohibited processes, both the 0.25s process watch timer and
//  the 1s delayed block in -forceQuitAllProcessesProceed could complete SEB startup,
//  opening the exam session twice and triggering the red "Re-Opening Locked Exam"
//  screen. The fix routes the delayed success path through -closeWindow, which is
//  guarded by _windowOpen so only the first path completes.
//  Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Cocoa

@objc public final class ProcessListCompletionRaceTestSupport: NSObject {

    // Delegate stub that counts how often the window completion callback fires.
    private final class CompletionCountingDelegate: NSObject, ProcessListViewControllerDelegate {
        var quittingSession = false
        var closeWithCallbackCount = 0

        func checkProcessesRunning(_ runningProcesses: NSMutableArray) -> NSMutableArray { runningProcesses }
        func closeProcessListWindow() {}
        func closeProcessListWindow(withCallback callback: Any?, selector: Selector) { closeWithCallbackCount += 1 }
        func newAlert() -> NSAlert { NSAlert() }
        func removeAlertWindow(_ alertWindow: NSWindow) {}
        func runModalAlert(_ alert: NSAlert, conditionallyFor window: NSWindow, completionHandler handler: ((NSApplication.ModalResponse) -> Void)?) {}
        func quitSEBOrSession() {}
    }

    /// Simulates the two completion paths that race after force quitting all prohibited
    /// processes — the process watch timer detecting termination, and the delayed
    /// force-quit success block — by invoking -closeWindow twice on a controller with no
    /// remaining processes. Returns how many times the window completion callback fired;
    /// with the fix in place this must be 1. Must be called on the main thread.
    @objc public static func completionCallbackCountWhenBothPathsComplete() -> Int {
        let processListViewController = ProcessListViewController()
        let delegate = CompletionCountingDelegate()
        processListViewController.delegate = delegate
        processListViewController.windowOpen = true
        processListViewController.runningApplications = NSMutableArray()
        processListViewController.runningProcesses = NSMutableArray()
        processListViewController.callback = delegate
        processListViewController.selector = NSSelectorFromString("closeProcessListWindow")
        // Give the controller a modal alert so -closeModalAlert has a real window to
        // pass to the (nonnull) -removeAlertWindow: delegate method.
        processListViewController.modalAlert = NSAlert()

        // Path 1: the process watch timer detects all prohibited processes terminated.
        processListViewController.closeWindow()
        // Path 2: the 1s delayed force-quit success block arrives afterwards.
        processListViewController.closeWindow()

        // -closeWindow dispatches its work asynchronously on the main queue; drain it.
        let deadline = Date().addingTimeInterval(1.0)
        while Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
        return delegate.closeWithCallbackCount
    }
}
#endif
