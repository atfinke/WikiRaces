//
//  NearbyServiceName.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

struct NearbyServiceName {
    
    private static let replacement = "<wikiraces.replacement.character>"
    private static let seperator: Character = "|"
    
    static func create(for hostName: String, raceCode: String) -> String {
        return hostName.replacingOccurrences(
            of: String(NearbyServiceName.seperator),
            with: NearbyServiceName.replacement)
    }
    
    static func metadata(from serviceName: String) -> (hostName: String, raceCode: String)? {
        let split = serviceName.split(separator: NearbyServiceName.seperator)
        guard split.count == 2 else {
            return nil
        }
        let hostName = split[0].replacingOccurrences(
            of: NearbyServiceName.replacement,
            with: String(NearbyServiceName.seperator))
        let raceCode = split[1].replacingOccurrences(
            of: NearbyServiceName.replacement,
            with: String(NearbyServiceName.seperator))
        return (hostName, raceCode)
    }
}
