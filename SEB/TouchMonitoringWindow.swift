//
//  TouchMonitoringWindow.swift
//  SEB
//
//  Created by Daniel Schneider on 06.09.2025.
//

import Foundation

class TouchMonitoringWindow: UIWindow {

    @objc weak public var touchMonitoringDelegate: SEBSPMetadataCollectorDelegate?

    override func sendEvent(_ event: UIEvent) {
        touchMonitoringDelegate?.receivedUIEvent(event)
        super.sendEvent(event) // pass events along!
    }
}
