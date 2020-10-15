//
//  NearbyAdvertiser.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import MultipeerConnectivity
import os.log

class NearbyRaceAdvertiser: NSObject, MCNearbyServiceBrowserDelegate {

    // MARK: - Properties -

    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?

    private var raceCode: String = ""
    private var invitedPeers = [MCPeerID]()

    // MARK: - Helpers -

    func start(hostName: String, raceCode: String) {
        os_log("Advertiser: %{public}s: host name: %{public}s, race code: %{public}s", log: .nearby, type: .info, #function, hostName, raceCode)

        let session = MCSession(peer: Nearby.peerID)
        browser = MCNearbyServiceBrowser(peer: Nearby.peerID, serviceType: Nearby.serviceType)
        browser?.delegate = self

        self.raceCode = raceCode
        self.session = session

        browser?.startBrowsingForPeers()
    }

    func stop() {
        os_log("Advertiser: %{public}s", log: .nearby, type: .info, #function)
        browser?.stopBrowsingForPeers()
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard !invitedPeers.contains(peerID),
              let session = session,
              let data = try? JSONEncoder().encode(Nearby.Invite(hostName: GKLocalPlayer.local.alias, raceCode: raceCode)) else {
            return
        }
        os_log("Advertiser: %{public}s: peer: %{public}s", log: .nearby, type: .info, #function, peerID.displayName)
        if peerID.displayName == Nearby.peerID.displayName {
            os_log("Advertiser: same name, skipping", log: .nearby, type: .info, #function)
            return
        }
        
        browser.invitePeer(peerID, to: session, withContext: data, timeout: 600)
        invitedPeers.append(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        os_log("Advertiser: %{public}s: %{public}s", log: .nearby, type: .info, #function, error.localizedDescription)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
