//
//  SEBIASKSecureSettingsStore.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26/04/16.
//
//

#import "IASKSettingsStore.h"

/** implementation of IASKSettingsStore that uses SEB secure NSUserDefaults
 */

@interface SEBIASKSecureSettingsStore : IASKAbstractSettingsStore

///designated initializer
- (id) initWithUserDefaults:(NSUserDefaults*) defaults;

///calls initWithUserDefaults: with [NSUserDefaults standardUserDefaults]
- (id) init;

@property (nonatomic, retain, readonly) NSUserDefaults* defaults;

@end
