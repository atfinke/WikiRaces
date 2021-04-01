//
//  PreRaceMessenger.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import Foundation
import GameKit
import os.log

struct PreRaceMessenger {
    
    struct Message: Codable {
        enum Info: String, Codable {
            case customMatchStartHostDetermination, hostCancelled, voteForHost, playerIsHost, settings, articles, startMatch
        }
        
        let info: Info
        let data: Data?
    }
    
    let match: GKMatch
    
    func send(message: Message, toPlayer player: GKPlayer? = nil, completion: ((Bool) -> Void)? = nil) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, message.info.rawValue)
        do {
            let data = try JSONEncoder().encode(message)
            if let player = player {
                try match.send(data, to: [player], dataMode: .reliable)
            } else {
                try match.sendData(toAllPlayers: data, with: .reliable)
            }
            completion?(true)
        } catch {
            os_log("%{public}s: error %{public}s", log: .gameKit, type: .error, #function, error.localizedDescription)
            completion?(false)
        }
    }
}
