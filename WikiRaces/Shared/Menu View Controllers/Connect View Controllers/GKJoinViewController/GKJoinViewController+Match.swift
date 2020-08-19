//
//  GKJoinViewController+Match.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import WKRUIKit

import os.log

extension GKJoinViewController: GKMatchDelegate {

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)

        if isPublicRace {
            publicRaceProcess(data: data, from: player)
        } else {
            if let object = try? JSONDecoder().decode(StartMessage.self, from: data) {
                self.transitionToGame(for: .gameKitPrivate(match: match, isHost: false), settings: object.gameSettings)
            } else if let message = try? JSONDecoder().decode(MiniMessage.self, from: data) {
                DispatchQueue.main.async {
                    switch message.info {
                    case .connected:
                        os_log("%{public}s: connected", log: .gameKit, type: .info, #function)
                        self.model.title = "Waiting for host"
                    case .cancelled:
                        os_log("%{public}s: cancelled", log: .gameKit, type: .info, #function)
                        self.showError(title: "Host cancelled race", message: "")
                        self.model.title = "Race Cancelled"
                        self.model.activityOpacity = 0
                    }
                }
            }
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        os_log("%{public}s: player: %{public}s, state: %{public}ld", log: .gameKit, type: .info, #function, player.alias, state.rawValue)

        guard state == .connected else { return }
        WKRUIPlayerImageManager.shared.connected(to: player, completion: nil)

        guard let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            try? match.send(data, to: [player], dataMode: .reliable)
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        os_log("%{public}s", log: .gameKit, type: .error, #function, error?.localizedDescription ?? "-")

        showError(title: "Unable To Connect", message: "Please try again later.")
        self.model.title = "Race Error"
        self.model.activityOpacity = 0
    }

}
