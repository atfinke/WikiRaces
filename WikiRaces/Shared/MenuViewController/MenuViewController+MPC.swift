//
//  MenuViewController+MPC.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity

extension MenuViewController: MCBrowserViewControllerDelegate {

    // MARK: - MCBrowserViewControllerDelegate

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true) {
            self.startSession(isHost: true)
        }
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true) {
        }
    }

}

extension MenuViewController: MCNearbyServiceAdvertiserDelegate {

    // MARK: - MCAdvertiserAssistantDelegate

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {

    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        invitationHandler(true, session)
        startSession(isHost: false)
        advertiser.stopAdvertisingPeer()
    }

}

