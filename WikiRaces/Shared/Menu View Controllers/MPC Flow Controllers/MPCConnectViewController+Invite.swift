//
//  MPCConnectViewController+Invite.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity
import UIKit

extension MPCConnectViewController: MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {

    // MARK: - MCSessionDelegate

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        session.delegate = nil
        showMatch(isPlayerHost: false)
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            if state == .connected && peerID == self.hostPeerID {
                self.updateDescriptionLabel(to: "WAITING FOR HOST")
            } else if state == .notConnected && peerID == self.hostPeerID {
                self.showError(title: "Connection Issue", message: "The connection to the host was lost.")
            }
        }
    }

    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}

    func startAdvertising() {
        session.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        updateDescriptionLabel(to: "WAITING FOR INVITE")
    }

    // MARK: - MCAdvertiserAssistantDelegate

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {

    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        invites.append((invitationHandler, peerID))
        showNextInvite()
    }

    /// Shows the next invite
    func showNextInvite() {
        guard !invites.isEmpty && !isShowingInvite else {
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        isShowingInvite = true

        let invite = invites.removeFirst()
        activeInvite = invite.handler
        hostPeerID = invite.host

        senderLabel.text = "FROM " + invite.host.displayName.uppercased()
        UIView.animate(withDuration: 0.25, animations: {
            self.inviteView.alpha = 1.0
        })
        updateDescriptionLabel(to: "INVITE RECEIVED")
    }

    // MARK: - User Actions

    /// Accepts the displayed invite
    @IBAction func acceptedInvite() {
        PlayerAnalytics.log(event: .userAction(#function))

        activeInvite?(true, session)
        advertiser?.stopAdvertisingPeer()
        updateDescriptionLabel(to: "CONNECTING TO HOST")

        UIView.animate(withDuration: 0.5) {
            self.inviteView.alpha = 0.0
        }
    }

    /// Declines the displayed invite
    @IBAction func declinedInvite() {
        PlayerAnalytics.log(event: .userAction(#function))

        activeInvite?(false, session)
        updateDescriptionLabel(to: "WAITING FOR INVITE")

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
