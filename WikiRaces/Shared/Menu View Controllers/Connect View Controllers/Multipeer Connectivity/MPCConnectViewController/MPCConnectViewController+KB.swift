//
//  MPCConnectViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MPCConnectViewController {

    // MARK: - Keyboard Support -

    override var keyCommands: [UIKeyCommand]? {
        var commands = [
            UIKeyCommand(title: "Return to Menu",
                         action: #selector(keyboardQuit),
                         input: UIKeyCommand.inputEscape,
                         modifierFlags: [])
        ]

        if isShowingInvite {
            let inviteCommands = [
                UIKeyCommand(title: "Accept Invite",
                             action: #selector(keyboardAttemptAcceptInvite),
                             input: "a",
                             modifierFlags: .command),
                UIKeyCommand(title: "Decline Invite",
                             action: #selector(keyboardAttemptDeclineInvite),
                             input: "d",
                             modifierFlags: .command)
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
