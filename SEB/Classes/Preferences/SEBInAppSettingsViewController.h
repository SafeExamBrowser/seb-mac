//
//  SEBInAppSettingsViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.10.18.
//

#import <UIKit/UIKit.h>

#import "IASKAppSettingsViewController.h"
#import "SEBViewController.h"
#import "SEBKeychainManager.h"

NS_ASSUME_NONNULL_BEGIN

@class SEBViewController;

@interface SEBInAppSettingsViewController : UIViewController <IASKSettingsDelegate, UITextViewDelegate> {
}

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic, retain) IBOutlet IASKAppSettingsViewController *tabAppSettingsViewController;
@property (nonatomic, strong) SEBKeychainManager *keychainManager;

@property (nonatomic, weak) SEBViewController *sebViewController;

@property (nonatomic, strong) NSMutableArray *identitiesNames;
@property (nonatomic, strong) NSMutableArray *identitiesCounter;
@property (nonatomic, strong) NSArray *identities;

@property (nonatomic, strong) NSMutableArray *certificatesNames;
@property (nonatomic, strong) NSMutableArray *certificatesCounter;
@property (nonatomic, strong) NSArray *certificates;

@property (nonatomic, strong) NSMutableDictionary *customCells;

@property (nonatomic, strong) NSMutableArray *combinedURLFilterRules;
@property (nonatomic, strong) NSMutableArray *combinedURLFilterRulesCounter;

@property (nonatomic, strong) NSMutableArray *embeddedCertificatesList;
@property (nonatomic, strong) NSMutableArray *embeddedCertificatesListCounter;

- (id)initWithSEBViewController:(SEBViewController *)sebViewController;
- (SecIdentityRef) getSelectedIdentity;

@end

NS_ASSUME_NONNULL_END
