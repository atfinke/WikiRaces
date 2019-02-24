//
//  MenuViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit
import StoreKit
import UIKit

import WKRKit
import WKRUIKit

/// The main menu view controller
internal class MenuViewController: UIViewController {

    // MARK: - View

    override func loadView() {
        view = MenuView()
    }

    var menuView: MenuView {
        guard let view = view as? MenuView else { fatalError() }
        return view
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        //swiftlint:disable:next discarded_notification_center_observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name.localPlayerQuit,
                                               object: nil,
                                               queue: nil) { _ in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    self.navigationController?.popToRootViewController(animated: false)
                })
            }
        }

        menuView.presentDebugController = showDebugController
        menuView.presentMPCConnectController = { isHost in
            self.performSegue(.showMPCConnecting, isHost: isHost)
        }
        menuView.presentGlobalConnectController = {
            self.pressedGlobalRace()
        }
        menuView.presentLeaderboardController = {
            let controller = GKGameCenterViewController()
            controller.gameCenterDelegate = self
            controller.viewState = .leaderboards
            controller.leaderboardTimeScope = .allTime
            self.present(controller, animated: true, completion: nil)
        }
        menuView.presentGlobalAuthController = {
            self.attemptGlobalAuthentication()
        }
        menuView.presentAlertController = { alertController in
            self.present(alertController, animated: true, completion: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // adjusts views before animation if rotation occured
        menuView.setNeedsLayout()
        menuView.layoutIfNeeded()

        menuView.animateMenuIn(completion: {
            if SKStoreReviewController.shouldPromptForRating {
                #if !DEBUG
                SKStoreReviewController.requestReview()
                #endif
            }
        })

        #if MULTIWINDOWDEBUG
        let controller = GameViewController()
        let nav = UINavigationController(rootViewController: controller)
        let name = (view.window as? DebugWindow)?.playerName ?? ""
        controller.networkConfig = .multiwindow(windowName: name,
                                                isHost: view.window!.frame.origin == .zero)
        present(nav, animated: false, completion: nil)
        #else
            attemptGlobalAuthentication()
        #endif

        if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
            PlayerDatabaseMetrics.shared.log(event: .customName(name))
        }
        PlayerDatabaseMetrics.shared.log(event: .deviceName(UIDevice.current.name))

        promptForInvalidName()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.wkrStatusBarStyle
    }

    // MARK: - Name Checking

    func promptForInvalidName() {
        guard UserDefaults.standard.bool(forKey: "AttemptingMCPeerIDCreation") else {
            return
        }
        UserDefaults.standard.set(false, forKey: "AttemptingMCPeerIDCreation")

        //swiftlint:disable:next line_length
        let message = "There was an unexpected issue starting a race with your player name. This can often occur when your name has too many emojis or too many letters. Please set a new custom player name before racing."
        let alertController = UIAlertController(title: "Player Name Issue", message: message, preferredStyle: .alert)

        let laterAction = UIAlertAction(title: "Maybe Later", style: .cancel, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForInvalidName:rejected"))
        })
        alertController.addAction(laterAction)

        let settingsAction = UIAlertAction(title: "Change Name", style: .default, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForInvalidName:accepted"))
            UIApplication.shared.openSettings()
        })
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Other

    func pressedGlobalRace() {
        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            let controller = GameViewController()
            let nav = UINavigationController(rootViewController: controller)
            let url = URL(string: "https://en.m.wikipedia.org/wiki/Walt_Disney_World")!
            controller.prepareForScreenshots(for: url)
            present(nav, animated: true, completion: nil)
        } else {
            let message = """
            Welcome to the Global Races Beta. Global Races require a Game Center account to play.
            """
            let controller = UIAlertController(title: "Global Races Beta",
                                               message: message,
                                               preferredStyle: .alert)

            let action = UIAlertAction(title: "Start Racing",
                                       style: .default,
                                       handler: { _ in
                                        self.performSegue(.showGameKitConnecting, isHost: false)
            })
            controller.addAction(action)
            controller.addCancelAction(title: "Cancel")
            //            self.present(controller, animated: true, completion: nil)
            self.performSegue(.showGameKitConnecting, isHost: false)
        }
    }

}
