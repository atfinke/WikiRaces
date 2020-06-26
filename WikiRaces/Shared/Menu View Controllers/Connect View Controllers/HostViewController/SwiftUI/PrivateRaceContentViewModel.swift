//
//  PrivateRaceContentViewModel.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRKit

struct SwiftUIPlayer: Identifiable, Equatable {
    let id: String
    var image: Image { PlayerImageDatabase.shared.image(for: id) }
}

class PrivateRaceContentViewModel: ObservableObject {
    
    @Published var connectedPlayers = [SwiftUIPlayer]()
    var status: String {
        if raceCode == nil {
            return "GENERATING RACE CODE"
        } else if connectedPlayers.isEmpty {
            return "NO CONNECTED RACERS"
        } else {
            return "\(connectedPlayers.count) CONNECTED RACER" + (connectedPlayers.count == 1 ? "" : "S")
        }
    }
    
    @Published var raceCode: String?
    
    @Published var settings = WKRGameSettings()
    @Published var customPages = [WKRPage]()
    
    init(settings: WKRGameSettings) {
        self.settings = settings
    }
}
