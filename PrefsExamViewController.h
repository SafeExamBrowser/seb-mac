//
//  PrefsExamViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface PrefsExamViewController : NSViewController <MBPreferencesModule> {
    NSTextField *examKey;
}

@property (strong) IBOutlet NSTextField *examKey;

- (IBAction) saveSEBPrefs:(id)sender;

@end
