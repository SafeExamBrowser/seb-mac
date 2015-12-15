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


// Load a SebClientSettings.seb file saved in the preferences directory
// and if it existed and was loaded, use it to re-configure SEB
- (BOOL) reconfigureClientWithSebClientSettings;

@end
