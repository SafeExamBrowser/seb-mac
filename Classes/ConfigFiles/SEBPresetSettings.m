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
                          @"executable" : @"Skype",
                          @"identifier" : @"com.skype.skype",
                      },
                      @{
                          @"executable" : @"Skype for Business",
                          @"identifier" : @"com.microsoft.SkypeForBusiness",
                      },
                      @{
                          @"executable" : @"Microsoft Communicator",
                          @"identifier" : @"com.microsoft.Communicator",
                      },
                      @{
                          @"executable" : @"Microsoft Lync",
                          @"identifier" : @"com.microsoft.Lync",
                      },
                      @{
                          @"executable" : @"Element (Riot)",
                          @"identifier" : @"im.riot.app",
                      },
                      @{
                          @"executable" : @"FaceTime",
                          @"identifier" : @"com.apple.FaceTime",
                      },
                      @{
                          @"executable" : @"Messages",
                          @"identifier" : @"com.apple.iChat",
                      },
                      @{
                          @"executable" : @"Telegram",
                          @"identifier" : @"ru.keepcoder.Telegram",
                      },
                      @{
                          @"executable" : @"GoToMeeting",
                          @"identifier" : @"com.logmein.GoToMeeting",
                      },
                      @{
                          @"executable" : @"Join.me",
                          @"identifier" : @"com.logmein.join.me",
                      },
                      @{
                          @"executable" : @"Slack",
                          @"identifier" : @"com.tinyspeck.slackmacgap",
                      },
                      @{
                          @"executable" : @"Teams",
                          @"identifier" : @"com.microsoft.teams",
                      },
                      @{
                          @"executable" : @"webexmta",
                          @"identifier" : @"com.cisco.webex.webexmta",
                      },
                      @{
                          @"executable" : @"Adium",
                          @"identifier" : @"com.adiumX.adiumX",
                      },
                      @{
                          @"executable" : @"TeamViewer",
                          @"identifier" : @"com.TeamViewer.TeamViewer",
                      },
                      @{
                          @"executable" : @"Chicken",
                          @"identifier" : @"com.geekspiff.chickenofthevnc",
                      },
                      @{
                          @"executable" : @"Chicken",
                          @"identifier" : @"net.sourceforge.chicken",
                      },
                      @{
                          @"executable" : @"Screenconnect",
                          @"identifier" : @"com.elsitech.screenconnect.client",
                      },
                      @{
                          @"executable" : @"Camtasia*",
                          @"identifier" : @"com.techsmith.camtasia*",
                      },
                      @{
                          @"executable" : @"Alfred*",
                          @"identifier" : @"com.runningwithcrayons.Alfred*",
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Safari Networking",
                          @"identifier" : @"com.apple.WebKit.Networking",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Chromium Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Opera Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser. Users have to restore their open tabs afterwards though.",
                          @"executable" : @"plugin-container",
                          @"identifier" : @"org.mozilla.plugincontainer",
                          @"strongKill" : @YES,
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
