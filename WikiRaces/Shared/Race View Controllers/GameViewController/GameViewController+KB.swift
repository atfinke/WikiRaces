//
//  GameViewController+KB.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension GameViewController {

    // MARK: - Keyboard Support

    override var keyCommands: [UIKeyCommand]? {
        // swiftlint:disable line_length
        var commands = [
            UIKeyCommand(input: "?", modifierFlags: .command, action: #selector(keyboardHelp), discoverabilityTitle: "Help"),
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(keyboardReload), discoverabilityTitle: "Reload Page"),
            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(keyboardAttemptForfeit), discoverabilityTitle: "Forfiet Race"),
            UIKeyCommand(input: "q", modifierFlags: .command, action: #selector(keyboardAttemptQuit), discoverabilityTitle: "Return to Menu"),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .alternate, action: #selector(discoverabilityEmptyFunction), discoverabilityTitle: "Page Up"),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .alternate, action: #selector(discoverabilityEmptyFunction), discoverabilityTitle: "Page Down"),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .command, action: #selector(discoverabilityEmptyFunction), discoverabilityTitle: "Top of Page"),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(discoverabilityEmptyFunction), discoverabilityTitle: "Bottom of Page"),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(discoverabilityEmptyFunction), discoverabilityTitle: "Move Up Page"),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(discoverabilityEmptyFunction), discoverabilityTitle: "Move Down Page")
        ]

        if navigationItem.rightBarButtonItem?.isEnabled ?? false {
            let command = UIKeyCommand(input: "q",
                                       modifierFlags: .command,
                                       action: #selector(keyboardAttemptQuit),
                                       discoverabilityTitle: "Return to Menu")
            commands.append(command)
        }

        let headerCommands = (1..<10).map { index in
            return UIKeyCommand(input: index.description,
                                modifierFlags: .command,
                                action: #selector(keyboardAttemptToggleSection(_:)),
                                discoverabilityTitle: "Toggle Section \(index)")
        }
        commands.append(contentsOf: headerCommands)

        return commands
    }

    @objc func discoverabilityEmptyFunction() {}

    @objc
    private func keyboardHelp() {
        guard activeViewController == nil else { return }
        showHelp()
    }

    @objc
    private func keyboardReload() {
        reloadPage()
    }

    @objc
    private func keyboardAttemptForfeit() {
        guard presentedViewController == nil else { return }
        helpButtonPressed()
    }

    @objc
    private func keyboardAttemptQuit() {
        guard presentedViewController == nil else { return }
        quitButtonPressed()
    }

    @objc
    private func keyboardAttemptToggleSection(_ keyCommand: UIKeyCommand) {
        guard let input = keyCommand.input,
            let index = Int(input),
            gameState == .race else {
                return
        }

        let script = "document.getElementsByClassName('section-heading')[\(index - 1)].click()"
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }

}
