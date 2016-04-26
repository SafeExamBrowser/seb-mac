//
//  SEBIASKSecureSettingsStore.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26/04/16.
//
//

#import "SEBIASKSecureSettingsStore.h"

@implementation SEBIASKSecureSettingsStore

- (id)initWithUserDefaults:(NSUserDefaults *)defaults {
    self = [super init];
    if( self ) {
        _defaults = defaults;
    }
    return self;
}

- (id)init {
    return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
}

- (void)setObject:(id)value forKey:(NSString*)key {
    [self.defaults setSecureObject:value forKey:key];
}

- (id)objectForKey:(NSString*)key {
    return [self.defaults secureObjectForKey:key];
}

@end
