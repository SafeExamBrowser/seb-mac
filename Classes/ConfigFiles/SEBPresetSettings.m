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
                          @"executable" : @"Keyboard Viewer (Assistive Control)",
                          @"identifier" : KeyboardViewerBundleID,
                          @"strongKill" : @YES,
                          @"ignoreInAAC" : @NO,
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
                          @"executable" : @"MSTeams",
                          @"identifier" : @"com.microsoft.teams2",
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
                          @"executable" : @"Google Chrome Helper (Renderer)",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Chromium Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Chrome Remote Desktop Host",
                          @"identifier" : @"com.google.chrome.remote_desktop.native-messaging-host",
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
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"remoting_host.exe",
                          @"originalName" : @"remoting_host.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"CiscoWebExStart.exe",
                          @"originalName" : @"CiscoWebExStart.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"CiscoCollabHost.exe",
                          @"originalName" : @"CiscoCollabHost.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"AA_v3.exe",
                          @"originalName" : @"AA_v3.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"ptoneclk.exe",
                          @"originalName" : @"ptoneclk.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"webexmta.exe",
                          @"originalName" : @"webexmta.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Teams.exe",
                          @"originalName" : @"Teams.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"join.me.sentinel.exe",
                          @"originalName" : @"join.me.sentinel.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"join.me.exe",
                          @"originalName" : @"join.me.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"g2mstart.exe",
                          @"originalName" : @"g2mstart.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"g2mlauncher.exe",
                          @"originalName" : @"g2mlauncher.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Telegram.exe",
                          @"originalName" : @"Telegram.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Zoom.exe",
                          @"originalName" : @"Zoom.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Element.exe",
                          @"originalName" : @"Element.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"slack.exe",
                          @"originalName" : @"slack.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"CamtasiaUtl.exe",
                          @"originalName" : @"CamtasiaUtl.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"CamRecorder.exe",
                          @"originalName" : @"CamRecorder.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"CamPlay.exe",
                          @"originalName" : @"CamPlay.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Camtasia_Studio.exe",
                          @"originalName" : @"Camtasia_Studio.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"CamtasiaStudio.exe",
                          @"originalName" : @"CamtasiaStudio.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Camtasia.exe",
                          @"originalName" : @"Camtasia.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Discord.exe",
                          @"originalName" : @"Discord.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"RPCSuite.exe",
                          @"originalName" : @"RPCSuite.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"RPCService.exe",
                          @"originalName" : @"RPCService.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"RemotePCDesktop.exe",
                          @"originalName" : @"RemotePCDesktop.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"beamyourscreen-host.exe",
                          @"originalName" : @"beamyourscreen-host.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"AeroAdmin.exe",
                          @"originalName" : @"AeroAdmin.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Mikogo-host.exe",
                          @"originalName" : @"Mikogo-host.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"chromoting.exe",
                          @"originalName" : @"chromoting.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"vncserverui.exe",
                          @"originalName" : @"vncserverui.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"vncviewer.exe",
                          @"originalName" : @"vncviewer.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"vncserver.exe",
                          @"originalName" : @"vncserver.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"TeamViewer.exe",
                          @"originalName" : @"TeamViewer.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"GotoMeetingWinStore.exe",
                          @"originalName" : @"GotoMeetingWinStore.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"g2mcomm.exe",
                          @"originalName" : @"g2mcomm.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"SkypeHost.exe",
                          @"originalName" : @"SkypeHost.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"SkypeApp.exe",
                          @"originalName" : @"SkypeApp.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Skype.exe",
                          @"originalName" : @"Skype.exe",
                          @"os" : @1,
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
        NSLocalizedString(@"Moodle", @""),
        NSLocalizedString(@"Open edX", @"")
    ];
}

@end
