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

    func startMatchmaking(attempt: Int = 1) {
        os_log("%{public}s: %{public}ld", log: .gameKit, type: .info, #function, attempt)
        
        guard isMatchmakingEnabled else { return }
        
        if attempt > 3 {
            os_log("%{public}s: too many attempts", log: .gameKit, type: .error, #function)
            DispatchQueue.main.async {
                self.isMatchmakingEnabled = false
                self.showError(title: "Failed to Create Race", message: "Please try again later.")
                self.model.state = .soloRace
            }
            return
        }
        
        func matchmake(raceCode: String) {
            os_log("%{public}s-%{public}s", log: .gameKit, type: .info, #function, raceCode)
            
            var didFail = false
            let startDate = Date()
            let request = GKMatchRequest.hostRequest(raceCode: raceCode, isInital: true)
            GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
                guard let self = self, self.isMatchmakingEnabled else { return }
                
                if let error = error {
                    os_log("%{public}s-%{public}s: error: %{public}s (%{public}f)", log: .gameKit, type: .error, #function, raceCode, error.localizedDescription, -startDate.timeIntervalSinceNow)
                    
                    didFail = true
                    if -startDate.timeIntervalSinceNow < 1 {
                        os_log("%{public}s-%{public}s: error: (quick)", log: .gameKit, type: .error, #function, raceCode)
                        
                        PlayerFirebaseAnalytics.log(event: .matchmakingQuickFail)
                        DispatchQueue.global().asyncAfter(deadline: .now() + 4) {
                            self.startMatchmaking(attempt: attempt + 1)
                        }
                    } else {
                        os_log("%{public}s-%{public}s: error (long)", log: .gameKit, type: .error, #function, raceCode)
                        DispatchQueue.main.async {
                            self.isMatchmakingEnabled = false
                            self.showError(title: "Failed to Create Race", message: "Please try again later.")
                            self.model.state = .soloRace
                        }
                    }
                } else if let match = match {
                    os_log("%{public}s-%{public}s: found match", log: .gameKit, type: .info, #function, raceCode)
                    self.match = match
                    self.match?.delegate = self
                    self.addPlayers()
                } else {
                    os_log("%{public}s- gamekit did the impossible, no error, no match, nothing to see here", log: .gameKit, type: .error, #function)
                    DispatchQueue.main.async {
                        self.isMatchmakingEnabled = false
                        self.showError(title: "Failed to Create Race", message: "Please try again later.")
                        self.model.state = .soloRace
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                os_log("%{public}s-%{public}s: asyncAfter: %{public}ld (%{public}ld)", log: .gameKit, type: .info, #function, raceCode, didFail ? 1 : 0, self.isMatchmakingEnabled ? 1 : 0)
                if !didFail && self.isMatchmakingEnabled {
                    self.model.raceCode = raceCode
                    self.model.state = .showingRacers
                    self.startNearbyAdvertising()
                }
            })
        }
        
        raceCodeGenerator.new { [weak self] code in
            guard let self = self, self.isMatchmakingEnabled else { return }
            os_log("%{public}s: raceCodeGenerator callback", log: .gameKit, type: .info, #function)
            matchmake(raceCode: code)
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
