//
//  SEBProcessListCompletionTests.swift
//  SafeExamBrowserTests
//
//  Regression test for the "Re-Opening Locked Exam" bug: completing the
//  prohibited-process window via Force Quit All Processes could start an exam
//  session twice.
//
//  After force quitting all prohibited processes, two independent paths could
//  complete SEB startup:
//    1. the 0.25s process watch timer detecting all processes terminated, and
//    2. the 1s delayed block in -[ProcessListViewController forceQuitAllProcessesProceed].
//  The delayed block used to invoke the delegate completion directly, bypassing the
//  _windowOpen guard, so the completion fired twice — SEB opened the main browser a
//  second time and the second opening detected the secure-session record written by
//  the first, showing the red "Re-Opening Locked Exam" screen. The fix routes the
//  delayed success path through -closeWindow, which consumes _windowOpen so only the
//  first path completes.
//
//  This drives both completion paths (via the DEBUG-only test-support shim) and
//  asserts the window completion callback fires exactly once.
//
//  Uses XCTest to match the other unit tests in this target.
//

import XCTest
import Safe_Exam_Browser

final class SEBProcessListCompletionTests: XCTestCase {

    @MainActor
    func testBothCompletionPathsCompleteWindowOnlyOnce() {
        let completionCallbackCount =
            ProcessListCompletionRaceTestSupport.completionCallbackCountWhenBothPathsComplete()
        XCTAssertEqual(completionCallbackCount, 1,
                       "The prohibited-process window completion must fire exactly once even when both the process watch timer and the delayed force-quit path complete, otherwise SEB opens the exam session twice and shows 'Re-Opening Locked Exam'.")
    }
}
