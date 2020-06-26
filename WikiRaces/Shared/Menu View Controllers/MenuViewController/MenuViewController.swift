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
final internal class MenuViewController: UIViewController {

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
    
    private let nearbyRaceListener = NearbyRaceListener()

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.localPlayerQuit,
            object: nil,
            queue: nil) { _ in
                UIView.animate(withDuration: 0.5, animations: {
                    self.presentedViewController?.view.alpha = 0
                    self.presentedViewController?.presentedViewController?.view.alpha = 0
                }, completion: { [weak self] _ in
                    self?.dismiss(animated: false) {
                        self?.navigationController?.popToRootViewController(animated: false)
                    }
                })
        }
        
        menuView.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .presentDebug:
                self.presentDebugController()
            case .presentLeaderboard:
                let controller = GKGameCenterViewController()
                controller.gameCenterDelegate = self
                controller.viewState = .leaderboards
                controller.leaderboardTimeScope = .allTime
                self.present(controller, animated: true, completion: nil)
            case .presentGKAuth:
                break
            case .presentJoinPublicRace:
                self.joinRace(raceCode: nil)
            case .presentJoinPrivateRace:
                let controller = UIAlertController(
                    title: "Join Private Race",
                    message: "Enter the race code from the host",
                    preferredStyle: .alert)
                controller.addTextField { textField in
                    textField.placeholder = "Race Code"
                }
                let action = UIAlertAction(title: "Join", style: .default) { [weak controller, weak self] _ in
                    guard let controller = controller, let code = controller.textFields?.first?.text else { return }
                    self?.joinRace(raceCode: code)
                }
                controller.addAction(action)
                controller.addCancelAction(title: "Cancel")
                self.present(controller, animated: true, completion: nil)
            case .presentCreateRace:
                self.createRace()
            case .presentAlert(let alert):
                self.present(alert, animated: true, completion: nil)
            case .presentStats:
                let nav = WKRUINavigationController(rootViewController: StatsViewController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            case .presentSubscription:
                PlayerAnonymousMetrics.log(event: .forcedIntoStoreFromStats)
                let controller = PlusViewController()
                controller.modalPresentationStyle = .overCurrentContext
                self.present(controller, animated: false, completion: nil)
            }

        }

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PlayerAnonymousMetrics.log(event: .userAction("issue#119: menu viewDidAppear"))

        UIApplication.shared.isIdleTimerDisabled = false

        // adjusts views before animation if rotation occured
        menuView.setNeedsLayout()
        menuView.layoutIfNeeded()

        menuView.animateMenuIn(completion: {
            if Defaults.shouldPromptForRating {
                #if !DEBUG
                SKStoreReviewController.requestReview()
                #endif
            }
        })

        #if MULTIWINDOWDEBUG
        let name = (view.window as? DebugWindow)?.playerName ?? ""
        let controller = GameViewController(
            network: .multiwindow(windowName: name, isHost: view.window!.frame.origin == .zero),
            settings: WKRGameSettings())
        let nav = WKRUINavigationController(rootViewController: controller)
        present(nav, animated: false, completion: nil)
        #else
        if isFirstAppearence {
            isFirstAppearence = false
            setupGKAuthHandler()
            setupInviteHandler()
        }
        #endif

        let metrics = PlayerDatabaseMetrics.shared
        metrics.log(value: UIDevice.current.name, for: "DeviceNames")
        metrics.log(value: PlusStore.shared.isPlus ? 1 : 0, for: "isPlus")
        
        nearbyRaceListener.start { host, raceCode in
            let controller = UIAlertController(
                title: "Nearby Race",
                message: "\(host) is starting a race nearby. Would you like to join?",
                preferredStyle: .alert)
            let action = UIAlertAction(title: "Join", style: .default) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.joinRace(raceCode: raceCode)
                }
            }
            controller.addAction(action)
            controller.addCancelAction(title: "No")
            DispatchQueue.main.async {
                self.present(controller, animated: true, completion: nil)
            }
        }
        becomeFirstResponder()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let mode = WKRUIStyle.isDark(traitCollection) ? 1 : 0
        PlayerAnonymousMetrics.log(event: .interfaceMode, attributes: ["Dark": mode])
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            menuView.triggeredEasterEgg()
        }
    }

    // MARK: - Other -
    
    func prepareForRace() {
        UIApplication.shared.isIdleTimerDisabled = true
        nearbyRaceListener.stop()
        resignFirstResponder()
        
        if presentedViewController != nil {
            navigationController?.popToRootViewController(animated: false)
        }
    }
    
    func joinRace(raceCode: String?) {
        prepareForRace()
        menuView.animateMenuOut {
            let controller = GKJoinViewController(raceCode: raceCode)
            self.navigationController?.pushViewController(controller, animated: false)
        }
    }
    
    func createRace() {
        if Defaults.isFastlaneSnapshotInstance {
            let controller = GameViewController(network: .solo(name: "_"), settings: WKRGameSettings())
            let nav = WKRUINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .overCurrentContext
            present(nav, animated: true, completion: nil)
        } else if GKLocalPlayer.local.isAuthenticated {
            prepareForRace()
            let controller = GKHostViewController()
            navigationController?.pushViewController(controller, animated: false)
        } else {
            let controller = GKHostViewController()
            navigationController?.pushViewController(controller, animated: false)
//            fatalError()
        }
    }

}
