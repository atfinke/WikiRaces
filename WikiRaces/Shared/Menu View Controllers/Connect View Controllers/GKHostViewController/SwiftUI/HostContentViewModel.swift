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

    @Published var connectedPlayers = [WKRUIPlayer]()
    var status: String {
        if matchStarting {
            return "RACE STARTING"
        } else if raceCode == nil {
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

    @Published var matchStarting = false
}
