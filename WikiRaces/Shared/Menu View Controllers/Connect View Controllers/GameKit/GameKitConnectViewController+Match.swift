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

    // MARK: - Helpers -

    func findMatch() {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.defaultNumberOfPlayers = 2
        let maxPlayerCount = min(WKRKitConstants.current.maxGlobalRacePlayers,
                                 GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer))
        request.maxPlayers = maxPlayerCount
        if let invite = GlobalRaceHelper.shared.lastInvite,
            let controller = GKMatchmakerViewController(invite: invite) {

                    PlayerAnonymousMetrics.log(event: .userAction("issue#119: invite"))

            controller.matchmakerDelegate = self
            present(controller, animated: true, completion: nil)
            self.controller = controller
            GlobalRaceHelper.shared.lastInvite = nil
        } else if let controller = GKMatchmakerViewController(matchRequest: request) {
                    PlayerAnonymousMetrics.log(event: .userAction("issue#119: matchRequest"))

            controller.matchmakerDelegate = self
            present(controller, animated: true, completion: nil)
            self.controller = controller
            #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
            findTrace = Performance.startTrace(name: "Global Race Find Trace")
            #endif
        } else {
            showError(title: "Unable To Find Match", message: "Please try again later.")
            let info = "findMatch: No valid controller"
            PlayerAnonymousMetrics.log(event: .error(info))
        }
    }

    func sendStartMessageToPlayers() {
                PlayerAnonymousMetrics.log(event: .userAction("issue#119: sendStartMessageToPlayers"))

        func fail() {
            showError(title: "Unable To Start Match",
                      message: "Please try again later.")
        }
        guard let match = match else {
            fail()
            let info = "findMatch: No valid match"
            PlayerAnonymousMetrics.log(event: .error(info))
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
            let info = "sendStartMessageToPlayers: " + error.localizedDescription
            PlayerAnonymousMetrics.log(event: .error(info))
        }
    }

    // MARK: - GKMatchDelegate -

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
                PlayerAnonymousMetrics.log(event: .userAction("issue#119: didReceive"))

        if isPlayerHost, WKRSeenFinalArticlesStore.isRemoteTransferData(data) {
            WKRSeenFinalArticlesStore.addRemoteTransferData(data)
        } else if let object = try? JSONDecoder().decode(StartMessage.self, from: data) {
            guard let hostAlias = self.hostPlayerAlias, object.hostName == hostAlias else {
                PlayerAnonymousMetrics.log(event: .globalFailedToFindHost)
                let message = "Please try again later."
                showError(title: "Unable To Find Best Host", message: message)
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

    // MARK: - GKMatchmakerViewControllerDelegate -

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
                PlayerAnonymousMetrics.log(event: .userAction("issue#119: wasCancelled"))

        dismiss(animated: true) {
            self.pressedCancelButton()
        }
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
                PlayerAnonymousMetrics.log(event: .userAction("issue#119: didFailWithError"))

        let info = "matchmaker...didFailWithError: " + error.localizedDescription
        PlayerAnonymousMetrics.log(event: .error(info))

        dismiss(animated: true) {
            self.showError(title: "Unable To Find Match",
                           message: "Please try again later.")
        }
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
                PlayerAnonymousMetrics.log(event: .userAction("issue#119: didFind"))

        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        findTrace?.stop()
        #endif
        updateDescriptionLabel(to: "Finding best host")

        dismiss(animated: true) {
            self.toggleCoreInterface(isHidden: false, duration: 0.25)
        }

        match.delegate = self
        self.match = match

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            var players = match.players
            players.append(GKLocalPlayer.local)
            if let hostPlayer = players.sorted(by: { $0.playerID > $1.playerID }).first {
                self.hostPlayerAlias = hostPlayer.alias
                if hostPlayer.playerID == GKLocalPlayer.local.playerID {
                    self.isPlayerHost = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        self.sendStartMessageToPlayers()
                    })
                }
            } else {
                let info = "matchmaker...didFind: No host player"
                PlayerAnonymousMetrics.log(event: .error(info))
                PlayerAnonymousMetrics.log(event: .globalFailedToFindHost)
                self.showError(title: "Unable To Find Best Host",
                               message: "Please try again later.")
            }
        }

        GlobalRaceHelper.shared.lastInvite = nil
    }
}
