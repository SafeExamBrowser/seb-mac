//
//  JitsiViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 11.05.20.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import UIKit
import JitsiMeetSDK

@objc protocol ProctoringUIDelegate {
    func setProctoringViewButtonState(_ remoteProctoringButtonState: remoteProctoringButtonStates)
}

class JitsiViewController: UIViewController {
    
    @objc public var safeAreaLayoutGuideInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            pipViewCoordinator?.dragBoundInsets = safeAreaLayoutGuideInsets
            pipViewCoordinator?.enterPictureInPicture()
        }
    }
    @objc public weak var proctoringUIDelegate: ProctoringUIDelegate?
    @objc public var viewIsVisible = false
    
    private var serverURL: URL?
    private var room: String?
    private var subject: String?
    private var token: String?

    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    fileprivate var jitsiMeetActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.isUserInteractionEnabled = false
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if parent != nil {
            parent?.view.addSubview(view)
            view.frame = parent?.view.frame ?? CGRect.zero
        } else {
            view.removeFromSuperview()
        }
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let rect = CGRect(origin: CGPoint.zero, size: size)
        pipViewCoordinator?.resetBounds(bounds: rect)
        self.pipViewCoordinator?.enterPictureInPicture()
        pipViewCoordinator?.dragBoundInsets = safeAreaLayoutGuideInsets
    }
    
    // MARK: - Actions
    
    @IBAction func openJitsiMeet(sender: Any?) {
        cleanUp()
        
        guard let serverURL = URL(string: UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetServerURL")) else {
            return
        }
        let room = UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetRoom")
        let subject = UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetSubject")
        let token = UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetToken")
        openJitsiMeet(serverURL: serverURL, room: room, subject: subject, token: token)
    }
    
    @objc public func openJitsiMeet(serverURL: URL, room: String?, subject: String?, token: String?) {
        self.serverURL = serverURL
        self.room = room
        self.subject = subject
        self.token = token
        openJitsiMeet(receiveAudioOverride: false, receiveVideoOverride: false, useChatOverride: false)
    }
    
    @objc public func openJitsiMeet(receiveAudioOverride: Bool,
                                    receiveVideoOverride: Bool,
                                    useChatOverride: Bool) {
        if jitsiMeetActive == true {
            closeJitsiMeet(sender: self)
        }
        jitsiMeetActive = true
        // create and configure jitsimeet view
        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        jitsiMeetView.isUserInteractionEnabled = true
        let userInfo = JitsiMeetUserInfo()
        userInfo.displayName = UIDevice().name
        let remoteProctoringViewShowPolicy = UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_remoteProctoringViewShow")

        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.serverURL = self.serverURL
            builder.room = self.room
            builder.token = self.token
            builder.setSubject(self.subject ?? "")
            builder.setAudioMuted(!receiveAudioOverride &&
                                  remoteProctoringViewShowPolicy != remoteProctoringViewShowNever &&
                                  UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetAudioMuted"))
            builder.setVideoMuted(!receiveVideoOverride &&
                remoteProctoringViewShowPolicy != remoteProctoringViewShowNever &&
                UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetVideoMuted"))
            builder.setAudioOnly(!receiveVideoOverride && UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetAudioOnly"))
            builder.userInfo = userInfo
            
            builder.setFeatureFlag("add-people.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("calendar.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("call-integration.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("close-captions.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagCloseCaptions"))
            builder.setFeatureFlag("chat.enabled",
                                   withBoolean: useChatOverride || UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagChat"))
            builder.setFeatureFlag("invite.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("ios.recording.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("live-streaming.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("video-share.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("meeting-name.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagDisplayMeetingName"))
            builder.setFeatureFlag("meeting-password.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("pip.enabled",
                                   withBoolean: true)
            builder.setFeatureFlag("raise-hand.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagRaiseHand"))
            builder.setFeatureFlag("recording.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagRecording"))
            builder.setFeatureFlag("tile-view.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagTileView"))
            builder.setFeatureFlag("welcomepage.enabled",
                                   withBoolean: false)
        }
        jitsiMeetView.join(options)
        
        // Enable jitsimeet view to be a view that can be displayed
        // on top of all the things, and let the coordinator to manage
        // the view state and interactions
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: parent?.view)
        
        // animate in
        jitsiMeetView.alpha = 1
        pipViewCoordinator?.dragBoundInsets = safeAreaLayoutGuideInsets
        if !useChatOverride {
            pipViewCoordinator?.enterPictureInPicture()
        }
        
        if remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToHide ||
            remoteProctoringViewShowPolicy == remoteProctoringViewShowAlways ||
            receiveVideoOverride == true ||
            useChatOverride == true {
            viewIsVisible = true
            pipViewCoordinator?.show()
        } else {
            viewIsVisible = false
            pipViewCoordinator?.hide()
        }
        updateProctoringViewButtonState()
    }
    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
        jitsiMeetActive = false
    }
    
    @IBAction func toggleJitsiViewVisibility(sender: Any?) {
        if viewIsVisible {
            viewIsVisible = false
            pipViewCoordinator?.hide()
        } else {
            viewIsVisible = true
            pipViewCoordinator?.show()
        }
    }
    
    @objc public func updateProctoringViewButtonState() {
        // Set the proctoring button to green (proctoring active)
        proctoringUIDelegate?.setProctoringViewButtonState(remoteProctoringButtonStateAIInactive)
    }

    @IBAction func closeJitsiMeet(sender: Any?) {
        self.jitsiMeetView?.leave()
        cleanUp()
    }
}

extension JitsiViewController: JitsiMeetViewDelegate {
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        #if DEBUG
        print(data as Any)
        #endif
        DispatchQueue.main.async {
            self.openJitsiMeet(sender: self)
//            self.pipViewCoordinator?.hide() { _ in
//                self.cleanUp()
//            }
        }
    }
    
//    func conferenceJoined(_ data: [AnyHashable : Any]!) {
//        print(data as Any)
//    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }
}
