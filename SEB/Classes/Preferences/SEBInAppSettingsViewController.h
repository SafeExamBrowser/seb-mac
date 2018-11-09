//
//  SEBInAppSettingsViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.10.18.
//

#import <UIKit/UIKit.h>

#import "IASKAppSettingsViewController.h"
#import "SEBViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SEBViewController;

@interface SEBInAppSettingsViewController : UIViewController <IASKSettingsDelegate, UITextViewDelegate> {
}

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic, retain) IBOutlet IASKAppSettingsViewController *tabAppSettingsViewController;

@property (nonatomic, weak) SEBViewController *sebViewController;

@property (strong, nonatomic) NSMutableArray *identitiesNames;
@property (nonatomic, strong) NSMutableArray *identitiesCounter;
@property (strong, nonatomic) NSArray *identities;

@property (nonatomic, strong) NSMutableDictionary *customCells;

@property (nonatomic, strong) NSMutableArray *combinedURLFilterRules;
@property (nonatomic, strong) NSMutableArray *combinedURLFilterRulesCounter;

@property (nonatomic, strong) NSMutableArray *embeddedCertificatesList;
@property (nonatomic, strong) NSMutableArray *embeddedCertificatesListCounter;

@end

NS_ASSUME_NONNULL_END
