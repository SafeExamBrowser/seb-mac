//
//  SEBPresetSettings.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
//

#import "SEBPresetSettings.h"

@implementation SEBPresetSettings

+ (NSDictionary *)defaultSettings
{
    return
    @{@"rootSettings" :
          @{
              @"prohibitedProcesses" :
                  @[
                      @{
                          @"executable" : @"zoom.us",
                          @"identifier" : @"us.zoom.xos",
                      },
                      @{
                          @"executable" : @"Element (Riot)",
                          @"identifier" : @"im.riot.app",
                      },
                  ], // prohibitedProcesses end
              
          }, // rootSettings end
      
    }; // defaultSettings end
}


+ (NSArray *) serverTypes
{
    return @[
        NSLocalizedString(@"Moodle", nil),
        NSLocalizedString(@"Open edX", nil)
    ];
}

@end
