//
//  NearbyAdvertiser.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity

class NearbyRaceAdvertiser: NSObject, MCNearbyServiceBrowserDelegate {
    
    // MARK: - Properties -
    
    private var peerID: MCPeerID?
    private var session: MCSession?
    private var browser: MCNearbyServiceBrowser?
    
    private var raceCode: String = ""
    private var invitedPeers = [MCPeerID]()
    
    // MARK: - Helpers -
    
    func start(hostName: String, raceCode: String) {
        let peerID = MCPeerID(displayName: hostName)
        let session = MCSession(peer: peerID)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Nearby.serviceType)
        browser?.delegate = self
        
        self.raceCode = raceCode
        self.peerID = peerID
        self.session = session
        
        browser?.startBrowsingForPeers()
    }
    
    func stop() {
        browser?.stopBrowsingForPeers()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard !invitedPeers.contains(peerID),
              let hostPeerID = self.peerID,
              let session = session,
              let data = try? JSONEncoder().encode(Nearby.Invite(hostName: hostPeerID.displayName, raceCode: raceCode)) else {
            return
        }
        browser.invitePeer(peerID, to: session, withContext: data, timeout: 600)
        invitedPeers.append(peerID)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
