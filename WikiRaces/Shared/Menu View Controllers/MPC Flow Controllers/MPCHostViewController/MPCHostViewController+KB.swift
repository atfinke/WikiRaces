//
//  MPCHostViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MPCHostViewController {

    // MARK: - Keyboard Support

    override var keyCommands: [UIKeyCommand]? {
        //swiftlint:disable line_length
        var commands = [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(keyboardQuit(_:)), discoverabilityTitle: "Return to Menu"),
            UIKeyCommand(input: "s", modifierFlags: [.command, .shift], action: #selector(keyboardAttemptStartSolo), discoverabilityTitle: "Start Solo Race")
        ]
        if navigationItem.rightBarButtonItem?.isEnabled ?? false {
            commands.append(UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(keyboardAttemptStartMPC(_:)), discoverabilityTitle: "Start Multiplayer Race"))
        }

        for (index, peer) in sortedPeers.enumerated() {
            guard peers[peer] == .found || peers[peer] == .declined else { continue }
            let command = UIKeyCommand(input: (index + 1).description,
                                       modifierFlags: .command,
                                       action: #selector(keyboardAttemptInvitePlayer(_:)),
                                       discoverabilityTitle: "Invite " + peer.displayName)
            commands.append(command)
        }
        return commands
    }

    @objc
    private func keyboardQuit(_ keyCommand: UIKeyCommand) {
        cancelMatch(keyCommand)
    }

    @objc
    private func keyboardAttemptStartMPC(_ keyCommand: UIKeyCommand) {
        guard navigationItem.rightBarButtonItem?.isEnabled ?? false else { return }
        startMatch(keyCommand)
    }

    @objc
    private func keyboardAttemptStartSolo() {
        guard tableView.isUserInteractionEnabled else { return }
        tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
    }

    @objc
    private func keyboardAttemptInvitePlayer(_ keyCommand: UIKeyCommand) {
        guard let input = keyCommand.input,
            let index = Int(input),
            index <= sortedPeers.count else {
                return
        }
        let indexPath = IndexPath(row: index - 1)
        let peer = sortedPeers[indexPath.row]
        guard peers[peer] == .found  || peers[peer] == .declined else { return }

        tableView(tableView, didSelectRowAt: indexPath)
    }

}
