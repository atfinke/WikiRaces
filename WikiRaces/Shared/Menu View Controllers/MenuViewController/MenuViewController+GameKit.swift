//
//  MenuViewController+GameKit.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit

extension MenuViewController: GKGameCenterControllerDelegate {

    // MARK: - Game Center -
    
    func setupGKAuthHandler() {
        func auth(result: GKHelper.AuthResult) {
            switch result {
            case .error(let error):
                let info = "attemptGlobalAuthentication: " + error.localizedDescription
                PlayerAnonymousMetrics.log(event: .error(info))
            case .controller(let controller):
                if self.presentedViewController == nil, self.menuView.state != .noInterface {
                    self.present(controller, animated: true, completion: nil)
                }
            case .isAuthenticated:
                let metrics = PlayerDatabaseMetrics.shared
                metrics.log(value: GKLocalPlayer.local.alias, for: "GCAliases")
            }
        }
        
        GKHelper.shared.authHandler = auth
    }
    
    func setupInviteHandler() {
        GKHelper.shared.inviteHandler = { code in
            self.joinRace(raceCode: code)
            self.menuView.animateOptionsOutAndTransition(to: .noInterface)
        }
    }

    // MARK: - GKGameCenterControllerDelegate -

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        dismiss(animated: true) {
            self.menuView.animateMenuIn()
        }
    }

    // MARK: - Other -

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
