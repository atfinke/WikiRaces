//
//  MenuViewController+Leaderboards.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit

extension MenuViewController: GKGameCenterControllerDelegate {

    // MARK: - Game Center

    /// Attempts Game Center login
    func attemptGCAuthentication() {
        guard !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") else {
            return
        }

        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if let viewController = viewController, self.menuView.state != .noInterface {
                    if self.presentedViewController == nil {
                        self.present(viewController, animated: true, completion: nil)
                    }
                } else if GKLocalPlayer.local.isAuthenticated {
                    PlayerDatabaseMetrics.shared.log(event: .gcAlias(GKLocalPlayer.local.alias))
                } else if !GKLocalPlayer.local.isAuthenticated {
                    // "error._code" ?!?!
                    if let error = error, error._code == 2 {
                        return
                    }
                    //swiftlint:disable:next line_length
                    let controller = UIAlertController(title: "Leaderboards Unavailable", message: "You must be logged into Game Center to access leaderboards", preferredStyle: .alert)

                    let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
                        PlayerMetrics.log(event: .userAction("attemptGCAuthentication:settings"))
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                            fatalError("Settings URL nil")
                        }
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    })
                    controller.addAction(settingsAction)
                    controller.addCancelAction(title: "Ok")

                    self.present(controller, animated: true, completion: nil)
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

}
