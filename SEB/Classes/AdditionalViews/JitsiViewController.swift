//
//  JitsiViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 11.05.20.
//

import UIKit
import JitsiMeet

class JitsiViewController: UIViewController {
    
    @objc public var safeAreaLayoutGuideInsets: UIEdgeInsets = UIEdgeInsets.zero {
        didSet {
            pipViewCoordinator?.dragBoundInsets = safeAreaLayoutGuideInsets
            pipViewCoordinator?.enterPictureInPicture()
        }
    }
    
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    
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
        
        // create and configure jitsimeet view
        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        jitsiMeetView.isUserInteractionEnabled = true
        
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.welcomePageEnabled = false
            builder.serverURL = URL(string: UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetServerURL"))
            builder.room = UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetRoom")
            builder.subject = UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetRoom")
            builder.token = UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_jitsiMeetSubject")
            builder.audioMuted = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetAudioMuted")
            builder.videoMuted = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetVideoMuted")
            builder.audioOnly = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetAudioOnly")
            
            builder.setFeatureFlag("add-people.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("calendar.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("call-integration.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("close-captions.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagCloseCaptions"))
            builder.setFeatureFlag("chat.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagChat"))
            builder.setFeatureFlag("invite.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("ios.recording.enabled",
                                   withBoolean: false)
            builder.setFeatureFlag("live-streaming.enabled",
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
            builder.setFeatureFlag("tile_view.enabled",
                                   withBoolean: UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_jitsiMeetFeatureFlagTileView"))
            //            builder.userInfo
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
        pipViewCoordinator?.enterPictureInPicture()
        pipViewCoordinator?.show()
    }
    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
    }
    
    @IBAction func closeJitsiMeet(sender: Any?) {
        self.jitsiMeetView?.leave()
        cleanUp()
    }
}

extension JitsiViewController: JitsiMeetViewDelegate {
    func conferenceTerminated(_ data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.openJitsiMeet(sender: self)
//            self.pipViewCoordinator?.hide() { _ in
//                self.cleanUp()
//            }
        }
    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }
}
