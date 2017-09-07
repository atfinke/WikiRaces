//
//  MPCConnectViewController+Invite.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import MultipeerConnectivity

extension MPCConnectViewController: MCNearbyServiceAdvertiserDelegate {

    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        descriptionLabel.attributedText = NSAttributedString(string: "WAITING FOR INVITE", spacing: 2.0)
    }

    // MARK: - MCAdvertiserAssistantDelegate

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {

    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        invites.append((invitationHandler, peerID.displayName))
        showNextInvite()
    }

    func showNextInvite() {
        guard !invites.isEmpty && !isShowingInvite else {
            return
        }

        isShowingInvite = true

        let invite = invites.removeFirst()
        activeInvite = invite.handler

        senderLabel.text = "FROM " + invite.host.uppercased()
        UIView.animate(withDuration: 0.25, animations: {
            self.inviteView.alpha = 1.0
        })
        descriptionLabel.attributedText = NSAttributedString(string: "INVITE RECEIVED", spacing: 2.0)
    }

    // MARK: - User Actions

    @IBAction func acceptedInvite() {
        activeInvite?(true, session)
        showMatch(isPlayerHost: false)
    }

    @IBAction func declinedInvite() {
        activeInvite?(false, session)
        descriptionLabel.attributedText = NSAttributedString(string: "WAITING FOR INVITE", spacing: 2.0)
        UIView.animate(withDuration: 0.25, animations: {
            self.descriptionLabel.alpha = 1.0
            self.activityIndicatorView.alpha = 1.0
            self.cancelButton.alpha = 1.0
            self.inviteView.alpha = 0.0
        }, completion: { _ in
            self.isShowingInvite = false
            self.showNextInvite()
        })
    }

}
