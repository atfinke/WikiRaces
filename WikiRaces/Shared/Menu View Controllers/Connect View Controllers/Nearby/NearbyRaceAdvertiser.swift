//
//  NearbyAdvertiser.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Network

struct NearbyRaceAdvertiser {
    
    // MARK: - Properties -
    
    private let advertiser = try? NWListener(using: NWParameters())
    
    // MARK: - Helpers -
    
    func start(hostName: String, raceCode: String) {
        let name = NearbyServiceName.create(for: hostName, raceCode: raceCode)
        advertiser?.service = NWListener.Service(name: name, type: Nearby.serviceType)
        advertiser?.start(queue: .main)
    }
    
    func stop() {
        advertiser?.cancel()
    }
}
