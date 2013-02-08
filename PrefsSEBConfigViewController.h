//
//  PrefsExamViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "MBPreferencesController.h"

@interface PrefsSEBConfigViewController : NSViewController <MBPreferencesModule> {
    IBOutlet NSPopUpButton *chooseIdentity;

	NSMutableString *settingsPassword;
	NSMutableString *confirmSettingsPassword;
	IBOutlet NSMatrix *sebPurpose;
	//IBOutlet NSButtonCell *sebStartsExam;
	//IBOutlet NSButtonCell *sebConfiguresClient;
	IBOutlet NSButton *saveSEBPrefsButton;
    IBOutlet NSObjectController *controller;
}

@property (strong, nonatomic) NSMutableArray *identitiesName;
@property (strong, nonatomic) NSArray *identities;

- (IBAction) saveSEBPrefs:(id)sender;
- (NSData*) encryptDataUsingSelectedIdentity:(NSData*)data;
- (NSData*) encryptData:(NSData*)data usingPassword:password;

@end
