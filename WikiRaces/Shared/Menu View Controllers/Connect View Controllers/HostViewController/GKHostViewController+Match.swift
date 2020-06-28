//
//  HostViewController+Match.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit

extension GKHostViewController: GKMatchDelegate {

    func startMatchmaking() {
        guard let code = model.raceCode, isMatchmakingEnabled else { return }
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.hostRequest(raceCode: code, isInital: false)) { [weak self] match, error in
            if let error = error {
                print(error)
                self?.startMatchmaking()
            } else if let match = match {
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
                print(error)
            } else {
                self?.addPlayers()
            }
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if state == .connected {
            PlayerImageDatabase.shared.connected(to: player, completion: { [weak self] in
                DispatchQueue.main.async {
                    self?.model.connectedPlayers.append(SwiftUIPlayer(id: player.alias ))
                }
                self?.sendMiniMessage(info: .connected)
            })
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        cancelMatch()
    }

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard WKRSeenFinalArticlesStore.isRemoteTransferData(data) else { return }
        WKRSeenFinalArticlesStore.addRemoteTransferData(data)
    }

}
