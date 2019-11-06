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

    // MARK: - View -

    override func loadView() {
        view = MenuView()
    }

    var menuView: MenuView {
        guard let view = view as? MenuView else { fatalError() }
        return view
    }

    private var isFirstAppearence = true
    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - View Life Cycle -

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

        menuView.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .presentDebug: self.presentDebugController()
            case .presentGlobalConnect: self.presentGlobalConnect()
            case .presentGlobalAuth: self.attemptGlobalAuthentication()
            case .presentMPCConnect(let isHost): self.presentMPCConnect(isHost: isHost)
            case .presentAlert(let alertController):
                self.present(alertController, animated: true, completion: nil)
            case .presentLeaderboard:
                let controller = GKGameCenterViewController()
                controller.gameCenterDelegate = self
                controller.viewState = .leaderboards
                controller.leaderboardTimeScope = .allTime
                self.present(controller, animated: true, completion: nil)
            }

        }

        GlobalRaceHelper.shared.didReceiveInvite = {
            DispatchQueue.main.async {
                guard self.presentedViewController == nil else { return }
                self.menuView.joinGlobalRace()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = false

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
        let nav = WKRUINavigationController(rootViewController: controller)
        let name = (view.window as? DebugWindow)?.playerName ?? ""
        controller.networkConfig = .multiwindow(windowName: name,
                                                isHost: view.window!.frame.origin == .zero)
        present(nav, animated: false, completion: nil)
        #else
        if isFirstAppearence {
            isFirstAppearence = false
            attemptGlobalAuthentication()
        }
        #endif

        let metrics = PlayerDatabaseMetrics.shared
        metrics.log(value: UIDevice.current.name, for: "DeviceNames")
        if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
            metrics.log(value: name, for: "CustomNames")
        }

        promptForInvalidName()
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            menuView.triggeredEasterEgg()
        }
    }

    // MARK: - Name Checking -

    func promptForInvalidName() {
        guard UserDefaults.standard.bool(forKey: "AttemptingMCPeerIDCreation") else {
            return
        }
        UserDefaults.standard.set(false, forKey: "AttemptingMCPeerIDCreation")

        //swiftlint:disable:next line_length
        let message = "There was an unexpected issue starting a race with your player name. This can often occur when your name has too many emojis or too many letters. Please set a new custom player name before racing."
        let alertController = UIAlertController(title: "Player Name Issue", message: message, preferredStyle: .alert)

        let laterAction = UIAlertAction(title: "Maybe Later", style: .cancel, handler: { _ in
            PlayerAnonymousMetrics.log(event: .userAction("promptForInvalidName:rejected"))
        })
        alertController.addAction(laterAction)

        let settingsAction = UIAlertAction(title: "Change Name", style: .default, handler: { _ in
            PlayerAnonymousMetrics.log(event: .userAction("promptForInvalidName:accepted"))
            UIApplication.shared.openSettings()
        })
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Other -

    func presentMPCConnect(isHost: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true

        let controller = MPCConnectViewController()
        controller.isPlayerHost = isHost
        navigationController?.pushViewController(controller, animated: false)
    }

    func presentGlobalConnect() {
        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            let controller = GameViewController()
            let nav = WKRUINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .overCurrentContext
            present(nav, animated: true, completion: nil)
        } else if GKLocalPlayer.local.isAuthenticated {
            UIApplication.shared.isIdleTimerDisabled = true
            let controller = GameKitConnectViewController()
            navigationController?.pushViewController(controller, animated: false)
        } else {
            presentGameKitAuthAlert()
        }
    }

}
