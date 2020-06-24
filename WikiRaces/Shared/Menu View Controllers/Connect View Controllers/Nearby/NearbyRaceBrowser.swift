//
//  NearbyBrowser.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Network

class NearbyRaceBrowser {
    
    // MARK: - Properties -
    
    private var browser: NWBrowser?
    
    // MARK: - Helpers -

    func start(nearbyRaces: @escaping ((_ hostName: String, _ raceCode: String) -> Void)) {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        browser = NWBrowser(for: .bonjour(type: Nearby.serviceType, domain: nil), using: parameters)
        
        browser?.browseResultsChangedHandler = { results, changes in
            for change in changes {
                guard case let NWBrowser.Result.Change.added(result) = change,
                      case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = result.endpoint,
                      let metadata = NearbyServiceName.metadata(from: name) else {
                    continue
                }
                nearbyRaces(metadata.hostName, metadata.raceCode)
            }
        }
        browser?.start(queue: .main)
    }
    
    func stop() {
        browser?.cancel()
    }
}
