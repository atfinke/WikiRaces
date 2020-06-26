//
//  GameKitConnectViewController+Match.swift
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

extension GKConnectViewController: GKMatchDelegate {

    func findMatch() {
        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        // TODO: fix
//        let type = raceCode == nil ? "Public" : "Private"
//        findTrace = Performance.startTrace(name: "Global Race Find Trace - " + type)
        #endif
        
        DispatchQueue.main.async {
            if self.raceCode == nil {
                self.updateDescriptionLabel(to: "searching for race")
            } else {
                self.updateDescriptionLabel(to: "joining race")
            }
        }
        
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.joinRequest(raceCode: raceCode)) { [weak self] match, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print(error)
                    let title = self.raceCode == nil ? "Unable To Find Race" : "Unable To Join Race"
                    self.showError(title: title, message: "Please try again later.")
                } else if let match = match {
                    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                    self.findTrace?.stop()
                    #endif
                    self.match = match
                    match.delegate = self
                    
                    if self.isPublicRace {
                        self.publicRaceDetermineHost(match: match)
                    }
                } else {
                    fatalError()
                }
            }
        }
    }
    
    // MARK: - GKMatchDelegate -

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if isPublicRace {
            publicRaceProcess(data: data, from: player)
        } else {
            if let object = try? JSONDecoder().decode(StartMessage.self, from: data) {
                showMatch(for: .gameKit(match: match, isHost: false), settings: object.gameSettings, andHide: [])
            } else if let message = try? JSONDecoder().decode(MiniMessage.self, from: data) {
                DispatchQueue.main.async {
                    switch message.info {
                    case .connected:
                        self.updateDescriptionLabel(to: "Waiting for host")
                    case .cancelled:
                        self.showError(title: "Host cancelled race", message: "")
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
    }
    
}
