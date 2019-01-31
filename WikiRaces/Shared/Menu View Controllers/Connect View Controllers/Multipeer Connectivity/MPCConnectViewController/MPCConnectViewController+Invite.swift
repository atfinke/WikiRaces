//
//  MPCConnectViewController+Invite.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity
import UIKit

import WKRKit

#if !MULTIWINDOWDEBUG
import FirebasePerformance
#endif

extension MPCConnectViewController: MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {

    // MARK: - MCSessionDelegate

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        session.delegate = nil
        showMatch(isPlayerHost: false,
                  generateFeedback: false,
                  andHide: [self.inviteView])
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            if state == .connected && peerID == self.hostPeerID {
                self.updateDescriptionLabel(to: "WAITING FOR HOST")

                DispatchQueue.global().asyncAfter(deadline: .now() + 0.25, execute: {
                    if let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() {
                        try? session.send(data, toPeers: [peerID], with: .reliable)
                    }
                })

                #if !MULTIWINDOWDEBUG
                self.connectingTrace?.stop()
                self.connectingTrace = nil
                #endif
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

        var hostContext: MPCHostContext?
        if let data = context,
            let object = try? JSONDecoder().decode(MPCHostContext.self, from: data) {
            hostContext = object
        }
        invites.append((invitationHandler, peerID, hostContext))
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

        hostNameLabel.text = "FROM " + invite.host.displayName.uppercased()
        UIView.animate(withDuration: 0.25, animations: {
            self.inviteView.alpha = 1.0
        })
        updateDescriptionLabel(to: "INVITE RECEIVED")

        guard let context = invite.context else { return }
        if context.minPeerAppBuild > Bundle.main.appInfo.build {
            //swiftlint:disable:next line_length
            let message = "You received an invite to a race that requires the latest version of WikiRaces. Please download the update on the App Store."
            showError(title: "Update Required", message: message)
        }
    }

    // MARK: - User Actions

    /// Accepts the displayed invite
    @objc
    func acceptInvite() {
        PlayerMetrics.log(event: .userAction(#function))

        activeInvite?(true, session)
        advertiser?.stopAdvertisingPeer()
        updateDescriptionLabel(to: "CONNECTING TO HOST")

        isShowingInvite = false

        UIView.animate(withDuration: 0.5) {
            self.inviteView.alpha = 0.0
        }

        #if !MULTIWINDOWDEBUG
        connectingTrace = Performance.startTrace(name: "Player Connecting Trace")
        #endif
    }

    /// Declines the displayed invite
    @objc
    func declineInvite() {
        PlayerMetrics.log(event: .userAction(#function))

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
