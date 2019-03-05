//
//  MenuViewController+GameKit.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit

extension MenuViewController: GKGameCenterControllerDelegate {

    // MARK: - Game Center

    /// Attempts Game Center login
    func attemptGlobalAuthentication() {
        GlobalRaceHelper.shared.authenticate { controller, error, forceShowError in
            if let controller = controller, self.menuView.state != .noInterface {
                if self.presentedViewController == nil {
                    self.present(controller, animated: true, completion: nil)
                }
            } else if GKLocalPlayer.local.isAuthenticated {
                let metrics = PlayerDatabaseMetrics.shared
                metrics.log(value: GKLocalPlayer.local.alias, for: "GCAliases")
            } else if !GKLocalPlayer.local.isAuthenticated {
                if error != nil || forceShowError {
                    self.presentGameKitAuthAlert()
                }
            }
        }
    }

    // MARK: - GKGameCenterControllerDelegate

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        PlayerMetrics.log(event: .userAction(#function))
        dismiss(animated: true) {
            self.menuView.animateMenuIn()
        }
    }

    // MARK: - Other

    func presentGameKitAuthAlert() {
        let title = "Global Races Unavailable"
        let message = """
        Please try logging into Game Center in the Settings app to join a Global Race.
        """

        let controller = UIAlertController(title: title,
                                           message: message,
                                           preferredStyle: .alert)
        controller.addCancelAction(title: "Ok")

        if presentedViewController == nil {
            present(controller, animated: true, completion: nil)
        }
    }

}
