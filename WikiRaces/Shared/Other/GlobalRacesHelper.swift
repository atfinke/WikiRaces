//
//  GlobalRacesHelper.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/23/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import GameKit

class GlobalRaceHelper: NSObject, GKLocalPlayerListener {

    // MARK: - Properties

    static let shared = GlobalRaceHelper()
    var lastInvite: GKInvite?

    // MARK: - Helpers

    func authenticate(completion: ((UIViewController?, Error?) -> Void)?) {
        guard !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") else {
            return
        }

        GKLocalPlayer.local.authenticateHandler = { controller, error in
            DispatchQueue.main.async {
                completion?(controller, error)
                if GKLocalPlayer.local.isAuthenticated {
                    GKLocalPlayer.local.register(self)
                }
            }
        }
    }

    // MARK: - GKLocalPlayerListener

    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        lastInvite = invite
    }
}
