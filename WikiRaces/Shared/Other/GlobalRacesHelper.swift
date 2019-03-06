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
    var isHandlerSetup = false
    var didReceiveInvite: (() -> Void)?

    // MARK: - Helpers

    func authenticate(completion: ((UIViewController?, Error?, _ forceShowErrorMessage: Bool) -> Void)?) {
        guard !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") else {
            return
        }

        guard !isHandlerSetup else {
            completion?(nil, nil, true)
            return
        }
        isHandlerSetup = true

        GKLocalPlayer.local.authenticateHandler = { controller, error in
            DispatchQueue.main.async {
                completion?(controller, error, false)
                if GKLocalPlayer.local.isAuthenticated {
                    GKLocalPlayer.local.register(self)
                }
            }
        }
    }

    // MARK: - GKLocalPlayerListener

    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        PlayerStat.gkInvitedToMatch.increment()
        lastInvite = invite
        didReceiveInvite?()
    }
}
