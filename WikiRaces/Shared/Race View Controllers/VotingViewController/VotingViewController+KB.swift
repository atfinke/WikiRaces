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
            let command = UIKeyCommand(input: "q",
                                       modifierFlags: .command,
                                       action: #selector(keyboardAttemptQuit),
                                       discoverabilityTitle: "Return to Menu")
            commands.append(command)
        }
        if let info = voteInfo, tableView.isUserInteractionEnabled {
            let voteCommands = (0..<info.pageCount).map { index in
                return UIKeyCommand(input: (index + 1).description,
                                    modifierFlags: .command,
                                    action: #selector(keyboardAttemptSelectArticle(_:)),
                                    discoverabilityTitle: info.page(for: index)?.page.title ?? "Unknown")
            }
            commands.append(contentsOf: voteCommands)
        }
        return commands
    }

    @objc
    private func keyboardAttemptSelectArticle(_ keyCommand: UIKeyCommand) {
        guard let input = keyCommand.input,
            let index = Int(input),
            let info = voteInfo,
            index <= info.pageCount,
            tableView.isUserInteractionEnabled else {
                return
        }

        let indexPath = IndexPath(row: index - 1)
        if let selectedIndexPath = tableView.indexPathForSelectedRow, selectedIndexPath == indexPath {
            return
        }

        _ = tableView(tableView, willSelectRowAt: indexPath)
        tableView.selectRow(at: indexPath,
                            animated: true,
                            scrollPosition: UITableView.ScrollPosition.none)
        tableView(tableView, didSelectRowAt: indexPath)
    }

    @objc
    private func keyboardAttemptQuit(_ keyCommand: UIKeyCommand) {
        guard presentedViewController == nil,
            navigationItem.rightBarButtonItem?.isEnabled ?? false else { return }

        doneButtonPressed(keyCommand)
    }

}
