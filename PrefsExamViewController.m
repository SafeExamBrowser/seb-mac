//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import "PrefsExamViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "RNEncryptor.h"
#import "SEBCryptor.h"
#import "SEBKeychainManager.h"

@interface PrefsExamViewController ()

@end

@implementation PrefsExamViewController
@synthesize examKey;


- (NSString *)title
{
	return NSLocalizedString(@"Exam", @"Title of 'Exam' preference pane");
}


- (NSString *)identifier
{
	return @"ExamPane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"ExamIcon"];
}


// Delegate called before the Exam settings preferences pane will be displayed
- (void)willBeDisplayed {
}

- (void)willBeHidden {
    [examKey setStringValue:@""];
}


- (IBAction) generateBrowserExamKey:(id)sender {
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *browserExamKey = [preferences objectForKey:@"currentData"];
    [examKey setStringValue:browserExamKey];
}



@end
