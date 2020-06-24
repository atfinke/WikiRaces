//
//  HostViewController+Match.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit

extension HostViewController: GKMatchDelegate {
    
    func startMatchmaking() {
        guard let code = raceCode else { fatalError() }
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.initalRequest(raceCode: code)) { [weak self] match, error in
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
        guard let match = self.match, let code = raceCode else { fatalError() }
        GKMatchmaker.shared().addPlayers(to: match, matchRequest: GKMatchRequest.standardRequest(raceCode: code)) { [weak self] error in
            if let error = error {
                print(error)
            } else {
                self?.addPlayers()
            }
        }
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        print(#function)
        players = match.players
        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet([Section.players.rawValue]), with: .automatic)
        }
    }
    
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        print(#function)
        cancelMatch()
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard WKRSeenFinalArticlesStore.isRemoteTransferData(data) else { return }
        WKRSeenFinalArticlesStore.addRemoteTransferData(data)
    }
    
}
