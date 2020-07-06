//
//  a.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import os.log

extension GKJoinViewController {

    // MARK: - Public Races -

    func publicRaceProcess(data: Data, from player: GKPlayer) {
        guard let match = match else { fatalError() }

        if isPlayerHost, WKRSeenFinalArticlesStore.isRemoteTransferData(data) {
            os_log("%{public}s: remote articles", log: .gameKit, type: .info, #function)
            WKRSeenFinalArticlesStore.addRemoteTransferData(data)
        } else if let object = try? JSONDecoder().decode(StartMessage.self, from: data) {
            os_log("%{public}s: start message", log: .gameKit, type: .info, #function)

            guard let hostAlias = self.publicRaceHostAlias, object.hostName == hostAlias else {
                PlayerFirebaseAnalytics.log(event: .globalFailedToFindHost)
                let message = "Please try again later."
                showError(title: "Unable To Find Best Host", message: message)
                model.title = "Race Error"
                os_log("%{public}s: wrong host started match: %{public}s, expected: %{public}s", log: .gameKit, type: .info, #function, object.hostName, self.publicRaceHostAlias ?? "-")
                return
            }
            if let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() {
                os_log("%{public}s: encoded seen articles", log: .gameKit, type: .info, #function)
                try? match.send(data, to: [player], dataMode: .reliable)
            }
            transitionToGame(for: .gameKitPublic(match: match, isHost: isPlayerHost), settings: object.gameSettings)
        }
    }

    func publicRaceSendStartMessage() {
        os_log("%{public}s", log: .gameKit, type: .info, #function)

        func fail() {
            showError(title: "Unable To Start Race", message: "Please try again later.")
            model.title = "Race Error"
        }
        guard let match = match else {
            fail()
            let info = "findMatch: No valid match"
            PlayerFirebaseAnalytics.log(event: .error(info))
            return
        }

        let settings = WKRGameSettings()
        let message = StartMessage(hostName: GKLocalPlayer.local.alias, gameSettings: settings)
        do {
            let data = try JSONEncoder().encode(message)
            try match.sendData(toAllPlayers: data, with: .reliable)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.transitionToGame(for: .gameKitPublic(match: match, isHost: true), settings: settings)
            }
        } catch {
            os_log("%{public}s: failed to send start message", log: .gameKit, type: .error, #function)
            fail()
            let info = "sendStartMessageToPlayers: " + error.localizedDescription
            PlayerFirebaseAnalytics.log(event: .error(info))
        }
    }

    func publicRaceDetermineHost(match: GKMatch) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.model.title = "Finding best host"
            var players = match.players
            players.append(GKLocalPlayer.local)
            if let hostPlayer = players.sorted(by: { $0.alias > $1.alias }).first {
                self.publicRaceHostAlias = hostPlayer.alias
                os_log("%{public}s: determined host: %{public}s", log: .gameKit, type: .info, #function, hostPlayer.alias)

                if hostPlayer.alias == GKLocalPlayer.local.alias {
                    self.isPlayerHost = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                        self.publicRaceSendStartMessage()
                    })
                }
            } else {
                os_log("%{public}s: no host", log: .gameKit, type: .error, #function)

                let info = "matchmaker...didFind: No host player"
                PlayerFirebaseAnalytics.log(event: .error(info))
                PlayerFirebaseAnalytics.log(event: .globalFailedToFindHost)
                self.showError(title: "Unable To Find Best Host", message: "Please try again later.")
                self.model.title = "Race Error"
            }
        }
    }

}
