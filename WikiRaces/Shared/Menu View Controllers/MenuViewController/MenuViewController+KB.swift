//
//  MenuViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MenuViewController {

    // MARK: - Keyboard Support -

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(title: "Create Local Race",
                         action: #selector(keyboardCreateLocalRace),
                         input: "n",
                         modifierFlags: .command),
            UIKeyCommand(title: "Join Local Race",
                         action: #selector(keyboardJoinLocalRace),
                         input: "j",
                         modifierFlags: .command),
            UIKeyCommand(title: "Join Global Race",
                         action: #selector(keyboardJoinGlobalRace),
                         input: "g",
                         modifierFlags: .command)
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
