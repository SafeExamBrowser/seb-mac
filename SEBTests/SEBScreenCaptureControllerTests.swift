//
//  SEBScreenCaptureControllerTests.swift
//  SafeExamBrowserTests
//
//  Created by Daniel Schneider on 11.08.2024.
//

import XCTest
import Safe_Exam_Browser

final class SEBScreenCaptureControllerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testTakeScreenShots() {
        let screenCaptureController = ScreenCaptureController()
        let screenShotColor24Bpp = screenCaptureController.takeScreenShot(scale: 0.5, quantization: .color24Bpp)
        let screenShotColor24BppSize = screenShotColor24Bpp?.count ?? 0
        let screenShotGrayscale8Bpp = screenCaptureController.takeScreenShot(scale: 0.5, quantization: .grayscale8Bpp)
        let screenShotGrayscale8BppSize = screenShotGrayscale8Bpp?.count ?? 0
        let grayscaleSmaller = screenShotColor24BppSize > screenShotGrayscale8BppSize
        print("Grayscale picture is \(grayscaleSmaller ? "" : "not ")smaller")
        XCTAssertGreaterThan(screenShotColor24BppSize, screenShotGrayscale8BppSize)
    }

//    func testShowTransmittingCachedScreenShotsWindowWithRemainingScreenShots() {
//        let sebViewController = SEBViewController()
//    }
    
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        //self.measure {
            // Put the code you want to measure the time of here.
        }
    }
