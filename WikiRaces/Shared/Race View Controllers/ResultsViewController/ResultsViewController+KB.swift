//
//  ResultsViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension ResultsViewController {

    // MARK: - Keyboard Support

    override var keyCommands: [UIKeyCommand]? {
        var commands = [UIKeyCommand]()
        if !isOverlayButtonHidden {
            let command = UIKeyCommand(input: " ",
                                       modifierFlags: [],
                                       action: #selector(keyboardAttemptReadyUp),
                                       discoverabilityTitle: "Ready Up")
            commands.append(command)
        }
        if navigationItem.rightBarButtonItem?.isEnabled ?? false {
            let command = UIKeyCommand(input: "q",
                                       modifierFlags: .command,
                                       action: #selector(keyboardAttemptQuit),
                                       discoverabilityTitle: "Return to Menu")
            commands.append(command)
        }
        return commands
    }

    @objc
    private func keyboardAttemptReadyUp() {
        guard !isOverlayButtonHidden else { return }
        overlayButtonPressed()
    }

    @objc
    private func keyboardAttemptQuit(_ keyCommand: UIKeyCommand) {
        guard presentedViewController == nil, navigationItem.rightBarButtonItem?.isEnabled ?? false else { return }
        quitButtonPressed(keyCommand)
    }

}
