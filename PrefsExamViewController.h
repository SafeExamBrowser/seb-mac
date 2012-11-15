//
//  PrefsExamViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface PrefsExamViewController : NSViewController <MBPreferencesModule>

- (IBAction) saveSEBPrefs;

@end
