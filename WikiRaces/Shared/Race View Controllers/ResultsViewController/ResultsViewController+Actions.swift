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

    @objc func doneButtonPressed(_ sender: Any) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        guard let alertController = quitAlertController else {
            PlayerAnonymousMetrics.log(event: .backupQuit,
                              attributes: ["RawGameState": state.rawValue])
            self.backupQuit?()
            return
        }
        present(alertController, animated: true, completion: nil)
    }

    @objc func addPlayersBarButtonItemPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        guard let controller = addPlayersViewController else { return }
        present(controller, animated: true, completion: nil)
        PlayerAnonymousMetrics.log(event: .hostStartMidMatchInviting)
    }

    @objc func shareResultsBarButtonItemPressed(_ sender: UIBarButtonItem) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        guard let image = resultImage else { return }

        let controller = UIActivityViewController(activityItems: [
            image,
            "#WikiRaces3"
            ], applicationActivities: nil)
        controller.popoverPresentationController?.barButtonItem = sender
        present(controller, animated: true, completion: nil)
        PlayerAnonymousMetrics.log(event: .openedShare)
    }
}
