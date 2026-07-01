//
//  SEBWiFiController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.07.26.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
import CoreWLAN
import CocoaLumberjackSwift

@objc public class SEBWiFiController: NSObject {

    private var wifiTimer: Timer?
    private var lastRSSI: Int = 0
    private var lastSSID: String?
    private var lastConnectedState: Bool = false
    private var wifiClient: CWWiFiClient

    @objc public var delegates: [SEBWiFiControllerDelegate] = []

    override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
        wifiClient = CWWiFiClient.shared()
        super.init()
    }

    @objc public func addDelegate(_ delegate: SEBWiFiControllerDelegate) {
        delegates.append(delegate)
    }

    @objc public func startMonitoringWiFi() {
        DDLogInfo("Starting WiFi monitoring")

        // Initial update
        updateWiFiStatus()

        // Start periodic monitoring
        wifiTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateWiFiStatus()
        }
    }

    @objc public func stopMonitoringWiFi() {
        DDLogInfo("Stopping WiFi monitoring")
        wifiTimer?.invalidate()
        wifiTimer = nil
    }

    private func updateWiFiStatus() {
        let interface = currentInterface()
        var connected: Bool = false
        var rssi: Int = 0
        var ssid: String?

        if let interface = interface {
            // On macOS 14+, ssid may return nil without Location Services authorization.
            // Use interfaceMode as a fallback to detect connection state.
            ssid = interface.ssid()
            let stationMode = (interface.interfaceMode() == .station)

            if ssid != nil {
                connected = true
                rssi = interface.rssiValue()
            } else if stationMode && interface.powerOn() {
                // Connected but SSID not accessible (Location Services not authorized)
                connected = true
                rssi = interface.rssiValue()
                DDLogDebug("WiFi connected (station mode) but SSID not accessible - Location Services may not be authorized")
            } else if interface.powerOn() {
                // WiFi is on but not connected
                connected = false
                DDLogVerbose("WiFi powered on but not connected")
            } else {
                DDLogVerbose("WiFi interface powered off")
            }
        } else {
            DDLogVerbose("No WiFi interface available")
        }

        // Only notify delegates if something changed
        if rssi != lastRSSI || ssid != lastSSID || connected != lastConnectedState {
            DDLogDebug("WiFi status changed: SSID=\(ssid ?? "unknown"), RSSI=\(rssi), connected=\(connected)")
            lastRSSI = rssi
            lastSSID = ssid
            lastConnectedState = connected

            for delegate in delegates {
                delegate.updateWiFiSignalStrength(rssi, networkName: ssid, connected: connected)
            }
        }
    }

    // MARK: - Interface Access

    @objc public func currentInterface() -> CWInterface? {
        return wifiClient.interface()
    }

    @objc(scanForNetworksWithError:)
    public func scanForNetworks() throws -> Set<CWNetwork> {
        guard let interface = currentInterface() else {
            DDLogWarn("Cannot scan: no WiFi interface available")
            return []
        }
        return try interface.scanForNetworks(withName: nil)
    }

    @objc(connectToNetwork:password:error:)
    public func connect(to network: CWNetwork, password: String?) throws {
        guard let interface = currentInterface() else {
            DDLogError("Cannot connect: no WiFi interface available")
            return
        }
        try interface.associate(to: network, password: password)
    }

    // MARK: - Computed Properties

    @objc public var rssiValue: Int {
        guard let interface = currentInterface() else { return 0 }
        let hasSSID = interface.ssid() != nil
        let stationMode = (interface.interfaceMode() == .station) && interface.powerOn()
        guard hasSSID || stationMode else { return 0 }
        return interface.rssiValue()
    }

    @objc public var connected: Bool {
        guard let interface = currentInterface() else { return false }
        // Check both SSID and station mode for connection detection
        return interface.ssid() != nil ||
            (interface.interfaceMode() == .station && interface.powerOn())
    }

    @objc public var ssid: String? {
        return currentInterface()?.ssid()
    }

    // MARK: - Icon Mapping

    @objc(iconNameForRSSI:connected:)
    public static func iconName(forRSSI rssi: Int, connected: Bool) -> String {
        if !connected {
            return "SEBWiFiIcon_off"
        }
        if rssi >= -50 {
            return "SEBWiFiIcon_100"
        } else if rssi >= -60 {
            return "SEBWiFiIcon_66"
        } else if rssi >= -70 {
            return "SEBWiFiIcon_33"
        } else {
            return "SEBWiFiIcon_0"
        }
    }
}
