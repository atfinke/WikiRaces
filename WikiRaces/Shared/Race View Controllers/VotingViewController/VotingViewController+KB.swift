//
//  VotingViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension VotingViewController {

    // MARK: - Keyboard Support -

    override var keyCommands: [UIKeyCommand]? {
        var commands = [UIKeyCommand]()
        if navigationItem.rightBarButtonItem?.isEnabled ?? false {
            let command = UIKeyCommand(title: "Return to Menu",
                                       action: #selector(keyboardAttemptQuit),
                                       input: "q",
                                       modifierFlags: .command)
            commands.append(command)
        }
        if let info = votingState, model.isVotingEnabled {
            let voteCommands = info.current.enumerated().map { index, item in
                return UIKeyCommand(title: item.page.title ?? "Unknown",
                                    action: #selector(keyboardAttemptSelectArticle(_:)),
                                    input: (index + 1).description,
                                    modifierFlags: .command)
            }
            commands.append(contentsOf: voteCommands)
        }
        return commands
    }

    @objc
    private func keyboardAttemptSelectArticle(_ keyCommand: UIKeyCommand) {
        guard let input = keyCommand.input,
            let index = Int(input),
            let items = votingState?.current,
            index <= items.count,
            model.isVotingEnabled else {
                return
        }
        listenerUpdate?(.voted(items[index + 1].page))
    }

    @objc
    private func keyboardAttemptQuit(_ keyCommand: UIKeyCommand) {
        guard presentedViewController == nil,
            navigationItem.rightBarButtonItem?.isEnabled ?? false else { return }

        doneButtonPressed(keyCommand)
    }

}
