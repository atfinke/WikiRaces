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
            transitionToGame(for: .gameKitPublic(match: match, isHost: isPlayerHost), settings: object.gameSettings, dismiss: matchmaker)
        } else if let object = try? JSONDecoder().decode(PublicRaceHostVoteMessage.self, from: data) {
            os_log("%{public}s: host vote message", log: .gameKit, type: .info, #function)
            process(hostVoteMessage: object)
        }
    }

    private func publicRaceSendStartMessage() {
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
            DispatchQueue.main.async {
                self.matchmaker?.dismiss(animated: true, completion: nil)
                self.model.title = "PREPARING"
                self.model.activityOpacity = 1
            }
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
        

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            
            var ____TIMEOUT = 10.0
            var date = Date()
            
            DispatchQueue.global().async {
                var isNetworkSelectedHostResultRelevant = true
                os_log("%{public}s: choosing best hosting player", log: .gameKit, type: .info, #function)
                match.chooseBestHostingPlayer { player in
                    guard isNetworkSelectedHostResultRelevant, let name = player?.alias else {
                        os_log("%{public}s: failed to choose best hosting player", log: .gameKit, type: .error, #function)
                        return
                    }
                    
                    os_log("%{public}s: found best host: %{public}s, t:%{public}i", log: .gameKit, type: .error, #function, name, -Int(date.timeIntervalSinceNow))
                    do {
                        let message = PublicRaceHostVoteMessage(hostName: name)
                        let data = try JSONEncoder().encode(message)
                        try match.sendData(toAllPlayers: data, with: .reliable)
                        self.process(hostVoteMessage: message)
                    } catch {
                        os_log("%{public}s: failed to send host vote message", log: .gameKit, type: .error, #function)
                        let info = "publicRaceDetermineHost: " + error.localizedDescription
                        PlayerFirebaseAnalytics.log(event: .error(info))
                    }
                }
                Timer.scheduledTimer(withTimeInterval: ____TIMEOUT, repeats: false, block: { _ in
                    isNetworkSelectedHostResultRelevant = false
                    os_log("%{public}s: failed to select host before timeout", log: .gameKit, type: .error, #function)
                })
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + ____TIMEOUT + 5, execute: {
                self.processHostVoteMessages()
            })
        }
    }
    
    private func process(hostVoteMessage: PublicRaceHostVoteMessage) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, hostVoteMessage.hostName)
        publicRaceHostVoteMessages.append(hostVoteMessage)
        os_log("%{public}s: processed: %{public}i/%{public}i", log: .gameKit, type: .info, #function, publicRaceHostVoteMessages.count, match?.players.count ?? -1)
        if let playerCount = match?.players.count, publicRaceHostVoteMessages.count == playerCount + 1 {
            processHostVoteMessages()
        }
    }
        
    private func processHostVoteMessages() {
        guard isPublicRaceHostVoteMessageProcessingNeeded else {
            os_log("%{public}s: not needed", log: .gameKit, type: .error, #function)
            return
        }
        os_log("%{public}s: started\n%{public}s\n", log: .gameKit, type: .info, #function, publicRaceHostVoteMessages.description)
        isPublicRaceHostVoteMessageProcessingNeeded = false
        
        let host = publicRaceHostVoteMessages
            .map { $0.hostName }
            .reduce(into: [:]) { counts, number in
                counts[number, default: 0] += 1
            }
            .sorted { (lhs, rhs) -> Bool in
                if lhs.value > rhs.value {
                    return true
                } else if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                } else {
                    return false
                }
            }
            .first
        
        guard let hostAlias = host?.key else {
            os_log("%{public}s: failed to determine host", log: .gameKit, type: .error, #function)
            return
        }
        os_log("%{public}s: determined host: %{public}s, self = %{public}i", log: .gameKit, type: .info, #function, hostAlias, hostAlias == GKLocalPlayer.local.alias ? 1 : 0)

        self.publicRaceHostAlias = hostAlias
        if hostAlias == GKLocalPlayer.local.alias {
            self.isPlayerHost = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                self.publicRaceSendStartMessage()
            })
        }
    }

}
