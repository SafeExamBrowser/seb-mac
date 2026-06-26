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
                          @"executable" : @"Adium",
                          @"identifier" : @"com.adiumX.adiumX",
                      },
                      @{
                          @"executable" : @"Alfred*",
                          @"identifier" : @"com.runningwithcrayons.Alfred*",
                      },
                      @{
                          @"executable" : @"AnyDesk",
                          @"identifier" : @"com.philandro.anydesk",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"AnyGPT",
                          @"identifier" : @"me.tanmay.AnyGPT",
                          @"strongKill" : @YES,
                          @"ignoreInAAC" : @NO,
                      },
                      @{
                          @"executable" : @"AutoFill",
                          @"identifier" : @"com.apple.AutoFillPanelService",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Brave Browser Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Camtasia*",
                          @"identifier" : @"com.techsmith.camtasia*",
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
                          @"executable" : @"Chrome",
                          @"identifier" : @"com.google.chrome",
                      },
                      @{
                          @"executable" : @"Chrome Remote Desktop Host",
                          @"identifier" : @"com.google.chrome.remote_desktop.native-messaging-host",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Chrome Remote Desktop Host",
                          @"identifier" : @"com.google.ChromeRemoteDesktop",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Chromium Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"ConnectWise Control Client",
                          @"identifier" : @"com.connectwise.control*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"DataDetectorsViewService",
                          @"identifier" : @"com.apple.DataDetectorsViewService",
                          @"ignoreInAAC" : @NO,
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Discord",
                          @"identifier" : @"com.hnc.Discord*",
                      },
                      @{
                          @"executable" : @"Discord Lite",
                          @"identifier" : @"com.dosdude1.Discord-Lite",
                      },
                      @{
                          @"description": @"DWService Agent",
                          @"executable" : @"DWAgent",
                          @"identifier" : @"com.dwservice.dwagent",
                          @"strongKill" : @YES,
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
                          @"description" : @"Firefox: This stops video conferencing and screen sharing, without having to quit the browser. Users have to restore their open tabs afterwards though.",
                          @"executable" : @"plugin-container",
                          @"identifier" : @"org.mozilla.plugincontainer",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Google Chrome Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"GoToMeeting",
                          @"identifier" : @"com.logmein.GoToMeeting",
                      },
                      @{
                          @"executable" : @"Guilded",
                          @"identifier" : @"com.electron.guilded",
                      },
                      @{
                          @"executable" : @"ISL Light",
                          @"identifier" : @"com.islonline.ISLLight*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"iTerm2",
                          @"identifier" : @"com.googlecode.iterm2",
                          @"ignoreInAAC" : @NO,
                      },
                      @{
                          @"executable" : @"Join.me",
                          @"identifier" : @"com.logmein.join.me",
                      },
                      @{
                          @"executable" : @"Jump Desktop",
                          @"identifier" : @"com.p5sys.jump.mac.viewer",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Jump Desktop Connect",
                          @"identifier" : @"com.p5sys.jump.mac.connect",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Keyboard Viewer (Assistive Control)",
                          @"identifier" : KeyboardViewerBundleID,
                          @"strongKill" : @YES,
                          @"ignoreInAAC" : @NO,
                      },
                      @{
                          @"executable" : @"LogMeIn",
                          @"identifier" : @"com.logmein.LogMeIn*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Loom",
                          @"identifier" : @"com.loom.desktop",
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
                          @"executable" : @"Microsoft Communicator",
                          @"identifier" : @"com.microsoft.Communicator",
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Microsoft Edge Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Microsoft Lync",
                          @"identifier" : @"com.microsoft.Lync",
                      },
                      @{
                          @"executable" : @"Microsoft Remote Desktop",
                          @"identifier" : @"com.microsoft.rdc.macos",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Moonlight",
                          @"identifier" : @"com.moonlight-stream.Moonlight",
                      },
                      @{
                          @"executable" : @"MSTeams",
                          @"identifier" : @"com.microsoft.teams2",
                      },
                      @{
                          @"executable" : @"NoMachine",
                          @"identifier" : @"com.nomachine.nxplayer",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"OBS",
                          @"identifier" : @"com.obsproject.obs-studio",
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Opera Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Parallels Access",
                          @"identifier" : @"com.parallels.access*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Parsec",
                          @"identifier" : @"com.parsec.Parsec",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Parsec",
                          @"identifier" : @"com.parsecgaming.parsec",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"RemotePC",
                          @"identifier" : @"com.remotepc.RemotePCDesktop",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Remote Utilities*",
                          @"identifier" : @"com.remoteutilities.*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"RustDesk",
                          @"identifier" : @"com.carriez.rustdesk",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Safari/WebKit Networking",
                          @"identifier" : WebKitNetworkingProcessBundleID,
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Screen Sharing",
                          @"identifier" : @"com.apple.ScreenSharing",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Screenconnect",
                          @"identifier" : @"com.elsitech.screenconnect.client",
                      },
                      @{
                          @"executable" : @"Screens*",
                          @"identifier" : @"com.edovia.screens*",
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
                          @"executable" : @"Slack",
                          @"identifier" : @"com.tinyspeck.slackmacgap",
                      },
                      @{
                          @"executable" : @"SolsticeClient",
                          @"identifier" : @"com.mersive.solstice.client",
                      },
                      @{
                          @"executable" : @"Splashtop*",
                          @"identifier" : @"com.splashtop.*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Supremo",
                          @"identifier" : @"com.nanosystems.Supremo*",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"sunshine",
                          @"description" : @"Sunshine game streaming server.",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"Swiftcord",
                          @"identifier" : @"io.cryptoalgo.swiftcord",
                      },
                      @{
                          @"executable" : @"Teams",
                          @"identifier" : @"com.microsoft.teams",
                      },
                      @{
                          @"executable" : @"TeamViewer",
                          @"identifier" : @"com.teamviewer.TeamViewer",
                      },
                      @{
                          @"executable" : @"TeamViewer",
                          @"identifier" : @"com.TeamViewer.TeamViewer",
                      },
                      @{
                          @"executable" : @"Telegram",
                          @"identifier" : @"ru.keepcoder.Telegram",
                      },
                      @{
                          @"executable" : @"Terminal",
                          @"identifier" : @"com.apple.Terminal",
                          @"ignoreInAAC" : @NO,
                      },
                      @{
                          @"executable" : @"Universal Control",
                          @"identifier" : UniversalControlBundleID,
                          @"strongKill" : @YES,
                      },
                      @{
                          @"description" : @"This stops video conferencing and screen sharing, without having to quit the browser.",
                          @"executable" : @"Vivaldi Helper",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"VLC",
                          @"identifier" : @"org.videolan.vlc",
                      },
                      @{
                          @"executable" : @"VNC Viewer",
                          @"identifier" : @"com.realvnc.vncviewer",
                          @"strongKill" : @YES,
                      },
                      @{
                          @"executable" : @"vncserver",
                          @"description" : @"The user will have to deactivate/uninstall RealVNC server to use SEB.",
                      },
                      @{
                          @"executable" : @"Voxa",
                          @"identifier" : @"lol.peril.voxa",
                      },
                      @{
                          @"executable" : @"webexmta",
                          @"identifier" : @"com.cisco.webex.webexmta",
                      },
                      @{
                          @"executable" : @"zoom.us",
                          @"identifier" : @"us.zoom.xos",
                      },

                      // SEB for Windows

                      @{
                          @"currentUser" : @YES,
                          @"description" : @"Ammyy Admin Remote Utility",
                          @"executable" : @"AA.exe",
                          @"originalName" : @"AA.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description" : @"Ammyy Admin Remote Utility",
                          @"executable" : @"AA_v3.exe",
                          @"originalName" : @"AA_v3.exe",
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
                          @"executable" : @"AnyDesk.exe",
                          @"originalName" : @"AnyDesk.exe",
                          @"os" : @1,
                      },
                      @{
                          @"description": @"Barrier Screen Share Client",
                          @"executable": @"barrier.exe",
                          @"originalName": @"barrier.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"beamyourscreen-host.exe",
                          @"originalName" : @"beamyourscreen-host.exe",
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
                          @"executable" : @"Camtasia.exe",
                          @"originalName" : @"Camtasia.exe",
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
                          @"executable" : @"Camtasia_Studio.exe",
                          @"originalName" : @"Camtasia_Studio.exe",
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
                          @"executable" : @"CamtasiaUtl.exe",
                          @"originalName" : @"CamtasiaUtl.exe",
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
                           @"executable" : @"CiscoCollabHost.exe",
                           @"originalName" : @"CiscoCollabHost.exe",
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
                          @"executable" : @"ConnectWiseControl.Client.exe",
                          @"originalName" : @"ConnectWiseControl.Client.exe",
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
                          @"executable" : @"DiscordPTB.exe",
                          @"originalName" : @"DiscordPTB.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"DiscordCanary.exe",
                          @"originalName" : @"DiscordCanary.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"DWService Agent",
                          @"executable" : @"dwagent.exe",
                          @"originalName" : @"dwagent.exe",
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
                          @"executable" : @"g2mcomm.exe",
                          @"originalName" : @"g2mcomm.exe",
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
                          @"executable" : @"g2mstart.exe",
                          @"originalName" : @"g2mstart.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"GoToAssist Client Engine",
                          @"executable": @"g2ax_user.exe",
                          @"originalName": @"g2ax_user.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"GotoMeetingWinStore.exe",
                          @"originalName" : @"GotoMeetingWinStore.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Guilded.exe",
                          @"originalName" : @"Guilded.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"ISLAlwaysOn.exe",
                          @"originalName" : @"ISLAlwaysOn.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"ISLLight.exe",
                          @"originalName" : @"ISLLight.exe",
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
                          @"executable" : @"join.me.sentinel.exe",
                          @"originalName" : @"join.me.sentinel.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"LogMeIn.exe",
                          @"originalName" : @"LogMeIn.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Loom.exe",
                          @"originalName" : @"Loom.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Microsoft.Media.player.exe",
                          @"originalName" : @"Microsoft.Media.player.exe",
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
                          @"executable" : @"Moonlight.exe",
                          @"originalName" : @"Moonlight.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"Windows Remote Desktop Client",
                          @"executable": @"mstsc.exe",
                          @"originalName": @"mstsc.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"MS-teams.exe",
                          @"originalName" : @"MS-teams.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"NinjaRMM Management Agent",
                          @"executable": @"NinjaRMMAgent.exe",
                          @"originalName": @"NinjaRMMAgent.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"nxclient.exe",
                          @"originalName" : @"nxclient.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"nxplayer.exe",
                          @"originalName" : @"nxplayer.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"obs32.exe",
                          @"originalName" : @"obs32.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"obs64.exe",
                          @"originalName" : @"obs64.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"parsecd.exe",
                          @"originalName" : @"parsecd.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"pcmontask.exe",
                          @"originalName" : @"pcmontask.exe",
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
                          @"description": @"Windows Quick Assist",
                          @"executable": @"quickassist.exe",
                          @"originalName": @"quickassist.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Radmin.exe",
                          @"originalName" : @"Radmin.exe",
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
                          @"executable" : @"remoting_host.exe",
                          @"originalName" : @"remoting_host.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"rfusclient.exe",
                          @"originalName" : @"rfusclient.exe",
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
                          @"executable" : @"RPCSuite.exe",
                          @"originalName" : @"RPCSuite.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"rserver3.exe",
                          @"originalName" : @"rserver3.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"rustdesk.exe",
                          @"originalName" : @"rustdesk.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"rutserv.exe",
                          @"originalName" : @"rutserv.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable": @"ScreenConnect.Client.exe",
                          @"originalName": @"ScreenConnect.Client.exe",
                          @"os": @1
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"ScreenConnect Windows Service",
                          @"executable": @"ScreenConnect.Service.exe",
                          @"originalName": @"ScreenConnect.Service.exe",
                          @"os": @1
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"sethc.exe",
                          @"originalName" : @"sethc.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Skype.exe",
                          @"originalName" : @"Skype.exe",
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
                          @"executable" : @"SkypeHost.exe",
                          @"originalName" : @"SkypeHost.exe",
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
                          @"executable" : @"SplashtopStreamer.exe",
                          @"originalName" : @"SplashtopStreamer.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"spotify.exe",
                          @"originalName" : @"spotify.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"Splashtop Streamer",
                          @"executable" : @"SRServer.exe",
                          @"originalName" : @"SRServer.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"strwinclt.exe",
                          @"originalName" : @"strwinclt.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"Supremo Remote Desktop",
                          @"executable" : @"Supremo.exe",
                          @"originalName" : @"Supremo.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"Supremo Remote Desktop Helper Service",
                          @"executable" : @"SupremoHelper.exe",
                          @"originalName" : @"SupremoHelper.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"Supremo Remote Desktop Service",
                          @"executable" : @"SupremoService.exe",
                          @"originalName" : @"SupremoService.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"Synergy Client",
                          @"executable": @"synergyc.exe",
                          @"originalName": @"synergyc.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Teams.exe",
                          @"originalName" : @"Teams.exe",
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
                          @"executable" : @"Telegram.exe",
                          @"originalName" : @"Telegram.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"TightVNC Server",
                          @"executable" : @"tvnserver.exe",
                          @"originalName" : @"tvnserver.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"TightVNC Viewer",
                          @"executable" : @"tvnviewer.exe",
                          @"originalName" : @"tvnviewer.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"description": @"UltraVNC Server",
                          @"executable": @"winvnc.exe",
                          @"originalName": @"winvnc.exe",
                          @"os": @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"VLC.exe",
                          @"originalName" : @"VLC.exe",
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
                          @"executable" : @"vncviewer.exe",
                          @"originalName" : @"vncviewer.exe",
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
                          @"executable" : @"webexmta.exe",
                          @"originalName" : @"webexmta.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"winvnc.exe",
                          @"originalName" : @"winvnc.exe",
                          @"os" : @1,
                      },
                      @{
                          @"currentUser" : @YES,
                          @"executable" : @"Zoom.exe",
                          @"originalName" : @"Zoom.exe",
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
