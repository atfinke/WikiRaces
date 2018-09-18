//
//  MPCConnectViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MPCConnectViewController {

    // MARK: - Keyboard Support

    override var keyCommands: [UIKeyCommand]? {
        var commands = [
            UIKeyCommand(input: UIKeyCommand.inputEscape,
                         modifierFlags: [],
                         action: #selector(keyboardQuit),
                         discoverabilityTitle: "Return to Menu")
        ]

        if isShowingInvite {
            let inviteCommands = [
                UIKeyCommand(input: "a",
                             modifierFlags: .command,
                             action: #selector(keyboardAttemptAcceptInvite),
                             discoverabilityTitle: "Accpet Invite"),
                UIKeyCommand(input: "d",
                             modifierFlags: .command,
                             action: #selector(keyboardAttemptDeclineInvite),
                             discoverabilityTitle: "Decline Invite")
            ]
            commands.append(contentsOf: inviteCommands)
        }
        return commands
    }

    @objc
    private func keyboardQuit() {
        pressedCancelButton()
    }

    @objc
    private func keyboardAttemptAcceptInvite() {
        guard isShowingInvite else { return }
        acceptInvite()
    }

    @objc
    private func keyboardAttemptDeclineInvite() {
        guard isShowingInvite else { return }
        declineInvite()
    }

}
