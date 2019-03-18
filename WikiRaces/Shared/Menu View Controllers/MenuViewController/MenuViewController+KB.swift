//
//  MenuViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MenuViewController {

    // MARK: - Keyboard Support

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "n",
                         modifierFlags: .command,
                         action: #selector(keyboardCreateLocalRace),
                         discoverabilityTitle: "Create Local Race"),
            UIKeyCommand(input: "j",
                         modifierFlags: .command,
                         action: #selector(keyboardJoinLocalRace),
                         discoverabilityTitle: "Join Local Race"),
            UIKeyCommand(input: "g",
                         modifierFlags: .command,
                         action: #selector(keyboardJoinGlobalRace),
                         discoverabilityTitle: "Join Global Race")
        ]
    }

    @objc private func keyboardJoinLocalRace() {
        PlayerAnonymousMetrics.log(event: .pressedJoin)
        PlayerDatabaseStat.mpcPressedJoin.increment()
        presentMPCConnect(isHost: false)
    }

    @objc private func keyboardCreateLocalRace() {
        PlayerAnonymousMetrics.log(event: .pressedHost)
        PlayerDatabaseStat.mpcPressedHost.increment()
        presentMPCConnect(isHost: true)
    }

    @objc private func keyboardJoinGlobalRace() {
        PlayerAnonymousMetrics.log(event: .pressedGlobalJoin)
        PlayerDatabaseStat.gkPressedJoin.increment()
        presentGlobalConnect()
    }
}
