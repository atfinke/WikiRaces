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
            GlobalRaceHelper.shared.lastInvite = nil
        }
        if let controller = GKMatchmakerViewController(matchRequest: request) {
            controller.matchmakerDelegate = self
            present(controller, animated: true, completion: nil)
        } else {
            showError(title: "Unable To Find Match", message: "Please try again later.")
        }
    }

    func sendStartMessageToPlayers() {
        func fail() {
            showError(title: "Unable To Start Match",
                      message: "Please try again later.")
        }
        guard let match = match else {
            fail()
            return
        }

        let message = StartMessage(hostName: GKLocalPlayer.local.alias)
        do {
            let data = try JSONEncoder().encode(message)
            try match.sendData(toAllPlayers: data, with: .reliable)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.showMatch(for: .gameKit(match: match,
                                             isHost: true),
                               andHide: [])
            }
        } catch {
            fail()
        }
    }

    // MARK: - GKMatchDelegate

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if isPlayerHost, WKRSeenFinalArticlesStore.isRemoteTransferData(data) {
            WKRSeenFinalArticlesStore.addRemoteTransferData(data)
        } else if let object = try? JSONDecoder().decode(StartMessage.self, from: data) {
            guard let hostAlias = self.hostPlayerAlias, object.hostName == hostAlias else {
                self.showError(title: "Unable To Find Best Host",
                               message: "Please try again later.")
                return
            }
            if let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() {
                try? match.send(data, to: [player], dataMode: .reliable)
            }
            showMatch(for: .gameKit(match: match,
                                    isHost: isPlayerHost),
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            var players = match.players
            players.append(GKLocalPlayer.local)
            if let hostPlayer = players.sorted(by: { $0.playerID > $1.playerID }).first {
                self.hostPlayerAlias = hostPlayer.alias
                if hostPlayer.playerID == GKLocalPlayer.local.playerID {
                    self.isPlayerHost = true
                    self.sendStartMessageToPlayers()
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
