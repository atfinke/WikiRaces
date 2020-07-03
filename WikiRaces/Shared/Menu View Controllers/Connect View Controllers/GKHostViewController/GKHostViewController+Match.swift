//
//  HostViewController+Match.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import WKRUIKit
import os.log

extension GKHostViewController: GKMatchDelegate {

    func startMatchmaking() {
        let startDate = Date()
        guard let code = model.raceCode, isMatchmakingEnabled else { return }
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.hostRequest(raceCode: code, isInital: false)) { [weak self] match, error in
            if let error = error {
                os_log("%{public}s: error: %{public}s (%{public}f)", log: .gameKit, type: .error, #function, error.localizedDescription, -startDate.timeIntervalSinceNow < 1)
                if -startDate.timeIntervalSinceNow < 1 {
                    self?.isMatchmakingEnabled = false
                    PlayerFirebaseAnalytics.log(event: .matchmakingQuickFail)
                    DispatchQueue.main.async {
                        self?.showError(title: "Failed to Create Race", message: "Please try again later.")
                    }
                } else {
                    self?.startMatchmaking()
                }
            } else if let match = match {
                os_log("%{public}s: found match", log: .gameKit, type: .info, #function)
                self?.match = match
                self?.match?.delegate = self
                self?.addPlayers()
            } else {
                fatalError()
            }
        }
    }

    private func addPlayers() {
        guard let match = self.match, let code = model.raceCode, isMatchmakingEnabled else { return }
        GKMatchmaker.shared().addPlayers(to: match, matchRequest: GKMatchRequest.hostRequest(raceCode: code, isInital: false)) { [weak self] error in
            if let error = error {
                os_log("%{public}s: error: %{public}s", log: .gameKit, type: .info, #function, error.localizedDescription)
            } else {
                os_log("%{public}s: success", log: .gameKit, type: .info, #function)
                self?.addPlayers()
            }
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        os_log("%{public}s: player: %{public}s, state: %{public}ld", log: .gameKit, type: .info, #function, player.alias, state.rawValue)
        if state == .connected {
            WKRUIPlayerImageManager.shared.connected(to: player, completion: { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    let player = WKRPlayerProfile(player: player)
                    if !self.model.connectedPlayers.contains(player) {
                        self.model.connectedPlayers.append(player)
                    }
                }
                self?.sendMiniMessage(info: .connected)
            })
        } else if state == .disconnected {
            DispatchQueue.main.async {
                let player = WKRPlayerProfile(player: player)
                if let index = self.model.connectedPlayers.firstIndex(of: player) {
                    self.model.connectedPlayers.remove(at: index)
                }
            }
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        os_log("%{public}s", log: .gameKit, type: .error, #function, error?.localizedDescription ?? "-")
        cancelMatch()
    }

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        guard WKRSeenFinalArticlesStore.isRemoteTransferData(data) else {
            os_log("%{public}s: failed", log: .gameKit, type: .error, #function)
            return
        }

        os_log("%{public}s: success", log: .gameKit, type: .info, #function)
        WKRSeenFinalArticlesStore.addRemoteTransferData(data)
    }

}
