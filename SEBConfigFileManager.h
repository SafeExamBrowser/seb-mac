//
//  SEBConfigFileManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.05.13.
//
//

#import <Foundation/Foundation.h>
#import "SEBController.h"

@interface SEBConfigFileManager : NSObject

@property (nonatomic, strong) SEBController *sebController;


-(BOOL) readSEBConfig:(NSData *)sebData;


@end
