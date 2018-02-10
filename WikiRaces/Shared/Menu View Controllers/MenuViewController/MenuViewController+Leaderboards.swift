//
//  MenuViewController+Leaderboards.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit

extension MenuViewController: GKGameCenterControllerDelegate {

    // MARK: - Interface

    /// Called when a tile is pressed
    ///
    /// - Parameter sender: The pressed tile
    @objc
    func menuTilePressed(sender: MenuTile) {
        PlayerAnalytics.log(event: .userAction(#function))

        guard GKLocalPlayer.localPlayer().isAuthenticated else {
            attemptGCAuthentication()
            return
        }
        guard !isLeaderboardPresented else {
            return
        }

        isLeaderboardPresented = true
        animateMenuOut {
            let controller = GKGameCenterViewController()
            controller.gameCenterDelegate = self
            controller.viewState = .leaderboards
            controller.leaderboardTimeScope = .allTime
            self.present(controller, animated: true, completion: nil)
            PlayerAnalytics.log(presentingOf: controller, on: self)
        }

        if let leaderboard = sender.stat?.leaderboard {
            PlayerAnalytics.log(event: .leaderboard, attributes: ["Leaderboard": leaderboard as Any])
        }
    }

    // MARK: - Game Center

    /// Attempts Game Center login
    func attemptGCAuthentication() {
        guard !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") else {
            return
        }

        GKLocalPlayer.localPlayer().authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if let viewController = viewController, self.isMenuVisable {
                    self.present(viewController, animated: true, completion: nil)
                    PlayerAnalytics.log(presentingOf: viewController, on: self)
                } else if !GKLocalPlayer.localPlayer().isAuthenticated {
                    // "error._code" ?!?!
                    if let error = error, error._code == 2 {
                        return
                    }
                    //swiftlint:disable:next line_length
                    let controller = UIAlertController(title: "Leaderboards Unavailable", message: "You must be logged into Game Center to access leaderboards", preferredStyle: .alert)

                    let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
                        PlayerAnalytics.log(event: .userAction("attemptGCAuthentication:settings"))
                        guard let settingsURL = URL(string: UIApplicationOpenSettingsURLString) else {
                            fatalError("Settings URL nil")
                        }
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    })
                    controller.addAction(settingsAction)

                    let cancelAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                    controller.addAction(cancelAction)

                    self.present(controller, animated: true, completion: nil)
                    PlayerAnalytics.log(presentingOf: controller, on: self)
                }
            }
        }
    }

    // MARK: - GKGameCenterControllerDelegate

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        PlayerAnalytics.log(event: .userAction(#function))
        dismiss(animated: true) {
            self.animateMenuIn()
            self.isLeaderboardPresented = false
        }
    }

}
