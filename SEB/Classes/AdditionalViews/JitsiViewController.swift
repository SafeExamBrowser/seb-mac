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
    
//    override func loadView() {
//        view = TouchDelegatingView(frame: view.frame)
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
//        self.view = TouchDelegatingView(frame: view.frame)
//
//        if let delegatingView = view as? TouchDelegatingView {
//            delegatingView.touchDelegate = parent?.view
//        }
        view.isUserInteractionEnabled = false
//        view.backgroundColor = .clear
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
//            builder.featureFlags
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

class TouchDelegatingView: JitsiMeetView {
    weak var touchDelegate: UIView? = nil


    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }

        guard view === self, let point = touchDelegate?.convert(point, from: self) else {
            return view
        }

        return touchDelegate?.hitTest(point, with: event)
    }
}
