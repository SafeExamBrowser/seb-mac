//
//  SEBPresetSettings.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
//

#import "SEBPresetSettings.h"

@implementation SEBPresetSettings

/// Provides default values for settings used by the extension
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
                          @"executable" : @"Universal Control",
                          @"identifier" : UniversalControlBundleID,
                          @"strongKill" : @YES,
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
                          @"executable" : @"Messages",
                          @"identifier" : @"com.apple.MobileSMS",
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
                          @"executable" : @"TeamViewer",
                          @"identifier" : @"com.teamviewer.TeamViewer",
                      },
                      @{
                          @"executable" : @"vncserver",
                          @"description" : @"The user will have to deactivate/uninstall RealVNC server to use SEB.",
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
                          @"executable" : @"AnyDesk",
                          @"identifier" : @"com.philandro.anydesk",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Alfred*",
                          @"identifier" : @"com.runningwithcrayons.Alfred*",
                      },
                      @{
                          @"executable" : @"AnyGPT",
                          @"identifier" : @"me.tanmay.AnyGPT",
                          @"strongKill" : @YES,
                          @"ignoreInAAC" : @NO,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Safari/WebKit Networking",
                          @"identifier" : WebKitNetworkingProcessBundleID,
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Chromium Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Brave Browser Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Opera Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Vivaldi Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Microsoft Edge Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Discord",
                          @"identifier" : @"com.hnc.Discord*",
                      },
                      @{
                          @"description" : @"Firefox: This stops video conferencing and screen sharing, without having to quit the browser. Users have to restore their open tabs afterwards though.",
                          @"executable" : @"plugin-container",
                          @"identifier" : @"org.mozilla.plugincontainer",
                          @"strongKill" : @YES,
                      },
                  ], // prohibitedProcesses end
              
          }, // rootSettings end
      
    }; // defaultSettings end
}


/// Provides default values for exam settings used by the extension
+ (NSDictionary *)defaultExamSettings
{
    return
    @{@"rootSettings" :
          @{
    
              @"allowPreferencesWindow" : @NO
              
          }, // rootSettings end
      
    }; // defaultExamSettings end
}


+ (NSArray *) serverTypes
{
    return @[
        NSLocalizedString(@"Moodle", nil),
        NSLocalizedString(@"Open edX", nil)
    ];
}

@end
