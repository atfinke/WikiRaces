//
//  ResultsViewController+Actions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/29/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

extension ResultsViewController {

    // MARK: - Actions

    @IBAction func quitButtonPressed(_ sender: Any) {
        PlayerMetrics.log(event: .userAction(#function))
        guard let alertController = quitAlertController else {
            PlayerMetrics.log(event: .backupQuit, attributes: ["GameState": state.rawValue.description as Any])
            self.backupQuit?()
            return
        }
        present(alertController, animated: true, completion: nil)
        PlayerMetrics.log(presentingOf: alertController, on: self)
    }

    @objc func addPlayersBarButtonItemPressed() {
        PlayerMetrics.log(event: .userAction(#function))
        guard let controller = addPlayersViewController else { return }
        present(controller, animated: true, completion: nil)
        PlayerMetrics.log(event: .hostStartMidMatchInviting)
        PlayerMetrics.log(presentingOf: controller, on: self)
    }

    @objc func shareResultsBarButtonItemPressed(_ sender: UIBarButtonItem) {
        PlayerMetrics.log(event: .userAction(#function))
        guard let image = resultImage else { return }

        let controller = UIActivityViewController(activityItems: [
            image,
            "#WikiRaces3"
            ], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = sender
        present(controller, animated: true, completion: nil)
        PlayerMetrics.log(event: .openedShare)
        PlayerMetrics.log(presentingOf: controller, on: self)
    }
}
