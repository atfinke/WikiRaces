//
//  GameKitConnectViewController+Match.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit

extension GameKitConnectViewController: GKMatchDelegate, GKMatchmakerViewControllerDelegate {

    // MARK: - Helpers

    func findMatch() {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer)
        if let invite = GlobalRaceHelper.shared.lastInvite,
            let controller = GKMatchmakerViewController(invite: invite) {
            controller.matchmakerDelegate = self
            present(controller, animated: true, completion: nil)
        }
        if let controller = GKMatchmakerViewController(matchRequest: request) {
            controller.matchmakerDelegate = self
            present(controller, animated: true, completion: nil)
        } else {
            showError(title: "Unable To Find Match", message: "Please try again later.")
        }
    }

    func sendStartMessageToPlayers() {
        guard let match = match else { return }
        let data = Data([1])
        do {
            try match.sendData(toAllPlayers: data, with: .unreliable)
            try match.sendData(toAllPlayers: data, with: .reliable)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.showMatch(for: .gameKit(match: match, isHost: true),
                               generateFeedback: true,
                               andHide: [])
            }
        } catch {
            showError(title: "Unable To Start Match",
                      message: "Please try again later.")
        }
    }

    // MARK: - GKMatchDelegate

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if isPlayerHost {
            WKRSeenFinalArticlesStore.addRemoteTransferData(data)
        } else {
            showMatch(for: .gameKit(match: match, isHost: isPlayerHost),
                      generateFeedback: true,
                      andHide: [])
        }
    }

    // MARK: - GKMatchmakerViewControllerDelegate

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        dismiss(animated: true) {
            self.pressedCancelButton()
        }
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        dismiss(animated: true) {
            self.showError(title: "Unable To Find Match",
                           message: "Please try again later.")
        }
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        updateDescriptionLabel(to: "Finding best host")

        dismiss(animated: true) {
            self.toggleCoreInterface(isHidden: false, duration: 0.25)
        }

        match.delegate = self
        self.match = match

        #if !MULTIWINDOWDEBUG
        let trace = Performance.startTrace(name: "Choosing Best Host Trace")
        #endif
        match.chooseBestHostingPlayer { player in
            if let hostPlayer = player {
                #if !MULTIWINDOWDEBUG
                trace?.stop()
                #endif
                if hostPlayer.playerID == GKLocalPlayer.local.playerID {
                    self.isPlayerHost = true
                    self.sendStartMessageToPlayers()
                } else if let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: {
                        try? match.send(data, to: [hostPlayer], dataMode: .reliable)
                    })
                }
                StatsHelper.shared.increment(stat: .gkConnectedToMatch)
            } else {
                self.showError(title: "Unable To Find Best Host",
                               message: "Please try again later.")
            }
        }

        GlobalRaceHelper.shared.lastInvite = nil
    }
}
