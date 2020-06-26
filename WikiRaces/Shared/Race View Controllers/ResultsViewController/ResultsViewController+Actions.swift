//
//  ResultsViewController+Actions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/29/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

extension ResultsViewController {

    // MARK: - Actions

    @objc func doneButtonPressed(_ sender: Any) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        guard let alertController = quitAlertController else {
            PlayerAnonymousMetrics.log(event: .backupQuit,
                              attributes: ["RawGameState": state.rawValue])
            listenerUpdate?(.quit)
            return
        }
        present(alertController, animated: true, completion: nil)
    }

    @objc func shareResultsBarButtonItemPressed(_ sender: UIBarButtonItem) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        guard let image = resultImage else { return }

        let hackTitle = "Hack"
        let controller = UIActivityViewController(activityItems: [
            image,
            "#WikiRaces3"
            ], applicationActivities: nil)
        controller.completionWithItemsHandler = { [weak self] activityType, completed, _, _ in
            if !(completed && activityType == UIActivity.ActivityType.saveToCameraRoll),
                let hack = self?.presentedViewController,
                hack.title == hackTitle {
                self?.dismiss(animated: false, completion: nil)
            }
        }
        controller.popoverPresentationController?.barButtonItem = sender

        // seriously, iOS 13 broke activity sheet save to photos??
        let hack = UIViewController()
        hack.title = hackTitle
        hack.view.alpha = 0.0
        hack.modalPresentationStyle = .overCurrentContext
        present(hack, animated: false, completion: {
            hack.present(controller, animated: true, completion: nil)
        })
        PlayerAnonymousMetrics.log(event: .openedShare)
    }
    
    func tapped(playerID: String) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        guard let resultsInfo = resultsInfo, let player = resultsInfo.player(for: playerID), state != .points else {
            return
        }

        let controller = HistoryViewController(style: .grouped)
        historyViewController = controller
        controller.player = player

        let navController = WKRUINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)

        PlayerAnonymousMetrics.log(event: .openedHistory,
                          attributes: ["GameState": state.rawValue.description as Any])
    }
}
