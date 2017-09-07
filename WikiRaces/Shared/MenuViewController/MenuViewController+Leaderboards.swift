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

    @objc
    func menuTilePressed(sender: MenuTile) {
        guard let stat = sender.stat, GKLocalPlayer.localPlayer().isAuthenticated else {
            attemptGCAuthentication()
            return
        }
        animateMenuOut {
            let controller = GKGameCenterViewController()
            controller.gameCenterDelegate = self
            controller.viewState = .leaderboards
            controller.leaderboardTimeScope = .allTime
            controller.leaderboardIdentifier = stat.leaderboard
            self.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: - Game Center

    func attemptGCAuthentication() {
        GKLocalPlayer.localPlayer().authenticateHandler = { viewController, error in
            DispatchQueue.main.async {
                if let viewController = viewController {
                    self.present(viewController, animated:true, completion: nil)
                } else if !GKLocalPlayer.localPlayer().isAuthenticated {
                    // "error._code" ?!?!
                    if let error = error, error._code == 2 {
                        return
                    }
                    //swiftlint:disable:next line_length
                    let controller = UIAlertController(title: "Leaderboards Unavailable", message: "You must be logged into Game Center to access leaderboards", preferredStyle: .alert)
                    controller.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                        if let url = URL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }))
                    controller.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(controller, animated: true, completion: nil)
                }
            }
        }
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        dismiss(animated: true) {
            self.animateMenuIn()
        }
    }

}
