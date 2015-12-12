//
//  SEBOSXConfigFileController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/11/15.
//
//

#import "SEBConfigFileManager.h"
#import "SEBController.h"

@class SEBController;

@interface SEBOSXConfigFileController : SEBConfigFileManager <SEBConfigUIDelegate>

@property (nonatomic, strong) SEBController *sebController;
@property (strong) SEBLockedViewController *lockedViewController;

@end
