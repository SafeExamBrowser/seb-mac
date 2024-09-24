//
//  SEBTests.m
//  SEBTests
//
//  Created by Daniel R. Schneider on 10/09/15.
//
//

#import <XCTest/XCTest.h>
//#import "SEBViewController.h"

//@class SEBViewController;
//@class SPSControllerUIDelegate;

@interface SEBTests : XCTestCase

//@property (strong, nonatomic) SEBViewController*_Nullable sebViewController;

@end

@implementation SEBTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testShowTransmittingCachedScreenShotsWindowWithRemainingScreenShots {
//    if (!_sebViewController) {
//        _sebViewController = [SEBViewController new];
//    }
//    [_sebViewController showTransmittingCachedScreenShotsWindowWithRemainingScreenShots:20  message:nil operation:@"Transmitting Screen Shot 20 of 20"];
//    [_sebViewController allowQuit];
//}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
