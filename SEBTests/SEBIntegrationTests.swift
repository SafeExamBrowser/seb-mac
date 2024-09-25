//
//  SEBIntegrationTests.swift
//  SEBTests
//
//  Created by Daniel Schneider on 22.09.2024.
//


import XCTest
import SEB

@objc final class IntegrationTests: XCTestCase {

    private lazy var sebViewController = SEBViewController()
    
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
    
    func testShowTransmittingCachedScreenShotsWindowWithRemainingScreenShots() {
        
        sebViewController.showTransmittingCachedScreenShotsWindow(remainingScreenShots: 20, message: nil, operation: "Transmitting Screen Shot 20 of 20")
        sebViewController.allowQuit(true)
        
        XCTAssert(true)
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
