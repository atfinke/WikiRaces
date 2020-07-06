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
        var commands = [
            UIKeyCommand(title: "Help", action: #selector(keyboardHelp), input: "?", modifierFlags: .command),
            UIKeyCommand(title: "Reload Page", action: #selector(keyboardReload), input: "r", modifierFlags: .command),
            UIKeyCommand(title: "Forfiet Race", action: #selector(keyboardAttemptForfeit), input: "f", modifierFlags: .command),
            UIKeyCommand(title: "Return to Menu", action: #selector(keyboardAttemptQuit), input: "q", modifierFlags: .command),
            UIKeyCommand(title: "Page Up", action: #selector(discoverabilityEmptyFunction), input: UIKeyCommand.inputUpArrow, modifierFlags: .alternate),
            UIKeyCommand(title: "Page Down", action: #selector(discoverabilityEmptyFunction), input: UIKeyCommand.inputDownArrow, modifierFlags: .alternate),
            UIKeyCommand(title: "Top of Page", action: #selector(discoverabilityEmptyFunction), input: UIKeyCommand.inputUpArrow, modifierFlags: .command),
            UIKeyCommand(title: "Bottom of Page", action: #selector(discoverabilityEmptyFunction), input: UIKeyCommand.inputDownArrow, modifierFlags: .command),
            UIKeyCommand(title: "Move Up Page", action: #selector(discoverabilityEmptyFunction), input: UIKeyCommand.inputUpArrow, modifierFlags: []),
            UIKeyCommand(title: "Move Down Page", action: #selector(discoverabilityEmptyFunction), input: UIKeyCommand.inputDownArrow, modifierFlags: [])
        ]

        if navigationItem.rightBarButtonItem?.isEnabled ?? false {
            let command = UIKeyCommand(title: "Return to Menu",
                                       action: #selector(keyboardAttemptQuit),
                                       input: "q",
                                       modifierFlags: .command)
            commands.append(command)
        }

        let headerCommands = (1..<10).map { index in
            return UIKeyCommand(title: "Toggle Section \(index)",
                                action: #selector(keyboardAttemptToggleSection(_:)),
                                input: index.description,
                                modifierFlags: .command)
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
        guard let webView = webView,
              let input = keyCommand.input,
              let index = Int(input),
              gameState == .race else {
            return
        }

        let script = "document.getElementsByClassName('section-heading')[\(index - 1)].click()"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

}
