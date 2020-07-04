//
//  HostContentViewModel.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRKit
import WKRUIKit

class HostContentViewModel: ObservableObject {
    
    enum State {
        case generatingRaceCode
        case soloRace
        case showingRacers
        case raceStarting
        
    }
    
    @Published var state: State = .generatingRaceCode
    
    @Published var raceCode: String?
    @Published var connectedPlayers = [WKRPlayerProfile]()
    
    @Published var settings = WKRGameSettings()
    @Published var customPages = [WKRPage]()
    
    var status: String {
        switch state {
            
        case .generatingRaceCode:
            return "GENERATING RACE CODE"
        case .soloRace:
            return "SOLO RACE"
        case .showingRacers:
            if connectedPlayers.isEmpty {
                return "NO CONNECTED RACERS"
            } else {
                return "\(connectedPlayers.count) CONNECTED RACER" + (connectedPlayers.count == 1 ? "" : "S")
            }
        case .raceStarting:
            return "RACE STARTING"
        }
    }
    
}
