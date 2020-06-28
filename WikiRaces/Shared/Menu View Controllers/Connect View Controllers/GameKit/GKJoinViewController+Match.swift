//
//  GKJoinViewController+Match.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

extension GKJoinViewController: GKMatchDelegate {

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if isPublicRace {
            publicRaceProcess(data: data, from: player)
        } else {
            if let object = try? JSONDecoder().decode(StartMessage.self, from: data) {
                self.transitionToGame(for: .gameKitPrivate(match: match, isHost: false), settings: object.gameSettings)
            } else if let message = try? JSONDecoder().decode(MiniMessage.self, from: data) {
                DispatchQueue.main.async {
                    switch message.info {
                    case .connected:
                        self.model.title = "Waiting for host"
                    case .cancelled:
                        self.showError(title: "Host cancelled race", message: "")
                        self.model.title = "Race Cancelled"
                        self.model.activityOpacity = 0
                    }
                }
            }
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        guard !isPublicRace else { return }

        guard state == .connected, let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() else { return }
        if state == .connected {
            PlayerImageDatabase.shared.connected(to: player, completion: nil)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            try? match.send(data, to: [player], dataMode: .reliable)
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        showError(title: "Unable To Connect", message: "Please try again later.")
        self.model.title = "Race Error"
        self.model.activityOpacity = 0
    }

}
