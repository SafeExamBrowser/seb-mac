//
//  SEBOverridableLockedViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 21.03.18.
//

#import "SEBLockedViewController.h"

@interface SEBOverridableLockedViewController : SEBLockedViewController <SEBLockedViewControllerDelegate>

@property (strong) IBOutlet NSButton *overrideSecurityCheck;

@end
