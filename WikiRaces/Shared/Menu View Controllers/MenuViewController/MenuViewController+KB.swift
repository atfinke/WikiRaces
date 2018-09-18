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
                         action: #selector(createRace),
                         discoverabilityTitle: "Create Race"),
            UIKeyCommand(input: "j",
                         modifierFlags: .command,
                         action: #selector(joinRace),
                         discoverabilityTitle: "Join Race"),
            UIKeyCommand(input: "s",
                         modifierFlags: .command,
                         action: #selector(openSettings),
                         discoverabilityTitle: "Open Settings")
        ]
    }
}
