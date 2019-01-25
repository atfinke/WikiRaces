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
internal class MenuViewController: StateLogViewController {

    // MARK: - Properties

    /// Used to track if the menu should be animating
    var isMenuVisable = false

    var isLeaderboardPresented = false

    // MARK: - Interface Elements

    /// The top of the menu (everything on white). Animates out of the left side.
    let topView = UIView()
    /// The bottom of the menu (everything not white). Animates out of the bottom.
    let bottomView = UIView()

    /// The "WikiRaces" label
    let titleLabel = UILabel()
    /// The "Conquer..." label
    let subtitleLabel = UILabel()

    let joinButton = WKRUIButton()
    let createButton = WKRUIButton()

    /// The Wiki Points tile
    var leftMenuTile: MenuTile?
    /// The average points tile
    var middleMenuTile: MenuTile?
    /// The races tile
    var rightMenuTile: MenuTile?

    /// Timer for moving the puzzle pieces
    var puzzleTimer: Timer?
    /// The puzzle piece view
    let puzzleView = UIScrollView()

    // MARK: - Constraints

    /// Used to animate the top view in and out
    var topViewLeftConstraint: NSLayoutConstraint!
    /// Used to animate the bottom view in and out
    var bottomViewAnchorConstraint: NSLayoutConstraint!

    /// Used for safe area layout adjustments
    var bottomViewHeightConstraint: NSLayoutConstraint!
    var puzzleViewHeightConstraint: NSLayoutConstraint!

    /// Used for adjusting y coord of title label based on screen height
    var titleLabelConstraint: NSLayoutConstraint!

    /// Used for adjusting button widths and heights based on screen width
    var joinButtonWidthConstraint: NSLayoutConstraint!
    var joinButtonHeightConstraint: NSLayoutConstraint!
    var createButtonWidthConstraint: NSLayoutConstraint!
    var createButtonHeightConstraint: NSLayoutConstraint!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()

        let panelGesture = UITapGestureRecognizer(target: self, action: #selector(showDebugPanel))
        panelGesture.numberOfTapsRequired = 2
        panelGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(panelGesture)

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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateMenuIn()

        #if MULTIWINDOWDEBUG
            performSegue(.debugBypass, isHost: view.window!.frame.origin == .zero)
        #else
            attemptGCAuthentication()

        // seeing a lot of duplicate entries, disabling for now
//            if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
//                PlayerMetrics.log(event: .hasCustomName(name))
//            }
//            if GKLocalPlayer.local.isAuthenticated {
//                PlayerMetrics.log(event: .hasGCAlias(GKLocalPlayer.local.alias))
//            }
            PlayerMetrics.log(event: .hasDeviceName(UIDevice.current.name))
        #endif
    }

    // MARK: - Actions

    /// Join button pressed
    @objc
    func joinRace() {
        guard isMenuVisable else { return }
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedJoin)

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: false) else {
            return
        }

        animateMenuOut {
            self.performSegue(.showConnecting, isHost: false)
        }
    }

    /// Create button pressed
    @objc
    func createRace() {
        guard isMenuVisable else { return }
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedHost)

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: true) else {
            return
        }

        animateMenuOut {
            self.performSegue(.showConnecting, isHost: true)
        }
    }

    func promptForCustomName(isHost: Bool) -> Bool {
        guard !UserDefaults.standard.bool(forKey: "PromptedCustomName") else {
            return false
        }
        UserDefaults.standard.set(true, forKey: "PromptedCustomName")

        let message = "Would you like to set a custom player name before racing?"
        let alertController = UIAlertController(title: "Set Name?", message: message, preferredStyle: .alert)

        let laterAction = UIAlertAction(title: "Maybe Later", style: .cancel, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForCustomNamePrompt:rejected"))
            PlayerMetrics.log(event: .namePromptResult, attributes: ["Result": "Cancelled"])
            if isHost {
                self.createRace()
            } else {
                self.joinRace()
            }
        })
        alertController.addAction(laterAction)

        let settingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForCustomNamePrompt:accepted"))
            PlayerMetrics.log(event: .namePromptResult, attributes: ["Result": "Accepted"])

            self.openSettings()
        })
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
        PlayerMetrics.log(presentingOf: alertController, on: self)
        return true
    }

    /// Changes title label to build info
    @objc
    func showDebugPanel() {
        PlayerMetrics.log(event: .versionInfo)

        let message = "If your name isn't Andrew, you probably shouldn’t be here."
        let alertController = UIAlertController(title: "Debug Panel",
                                                message: message,
                                                preferredStyle: .alert)

        let darkAction = UIAlertAction(title: "Toggle Dark UI", style: .default, handler: { _ in
            WKRUIStyle.isDark = !WKRUIStyle.isDark
            exit(1998)
        })
        alertController.addAction(darkAction)

        let buildAction = UIAlertAction(title: "Show Build Info", style: .default, handler: { _ in
            self.showDebugBuildInfo()
        })
        alertController.addAction(buildAction)

        let defaultsAction = UIAlertAction(title: "Show Defaults", style: .default, handler: { _ in
            self.showDebugDefaultsInfo()
        })
        alertController.addAction(defaultsAction)

        alertController.addCancelAction(title: "Dismiss")

        present(alertController, animated: true, completion: nil)

        PlayerMetrics.log(presentingOf: alertController, on: self)
    }

    private func showDebugBuildInfo() {
        let versionKey = "CFBundleVersion"
        let shortVersionKey = "CFBundleShortVersionString"

        let appBundleInfo = Bundle.main.infoDictionary
        let kitBundleInfo = Bundle(for: WKRGameManager.self).infoDictionary
        let interfaceBundleInfo = Bundle(for: WKRUIStyle.self).infoDictionary

        guard let appBundleVersion = appBundleInfo?[versionKey] as? String,
            let appBundleShortVersion = appBundleInfo?[shortVersionKey] as? String,
            let kitBundleVersion = kitBundleInfo?[versionKey] as? String,
            let kitBundleShortVersion = kitBundleInfo?[shortVersionKey] as? String,
            let interfaceBundleVersion = interfaceBundleInfo?[versionKey] as? String,
            let interfaceBundleShortVersion = interfaceBundleInfo?[shortVersionKey] as? String else {
                fatalError("No bundle info dictionary")
        }

        let debugInfoController = DebugInfoTableViewController()
        debugInfoController.title = "Build Info"
        debugInfoController.info = [
            ("WikiRaces Version", "\(appBundleShortVersion) (\(appBundleVersion))"),
            ("WKRKit Version", "\(kitBundleShortVersion) (\(kitBundleVersion))"),
            ("WKRUIKit Version", "\(interfaceBundleShortVersion) (\(interfaceBundleVersion))"),

            ("WKRKit Constants Version", "\(WKRKitConstants.current.version)"),
            ("WKRUIKit Constants Version", "\(WKRUIKitConstants.current.version)")
        ]

        let navController = UINavigationController(rootViewController: debugInfoController)
        present(navController, animated: true, completion: nil)

        PlayerMetrics.log(presentingOf: navController, on: self)
    }

    private func showDebugDefaultsInfo() {
        let debugInfoController = DebugInfoTableViewController()
        debugInfoController.title = "User Defaults"
        debugInfoController.info = UserDefaults
            .standard
            .dictionaryRepresentation()
            .sorted { (lhs, rhs) -> Bool in
                return lhs.key.lowercased() < rhs.key.lowercased()
        }

        let navController = UINavigationController(rootViewController: debugInfoController)
        present(navController, animated: true, completion: nil)

        PlayerMetrics.log(presentingOf: navController, on: self)
    }

    // MARK: - Menu Animations

    /// Animates the views off screen
    ///
    /// - Parameter completion: The completion handler
    func animateMenuOut(completion: (() -> Void)?) {
        view.isUserInteractionEnabled = false
        bottomViewAnchorConstraint.constant = bottomView.frame.height

        isMenuVisable = false
        view.setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.puzzleTimer?.invalidate()
            completion?()
        })
    }

    /// Animates the views on screen
    func animateMenuIn() {
        view.isUserInteractionEnabled = false
        UIApplication.shared.isIdleTimerDisabled = false

        let duration = TimeInterval(5)
        let offset = CGFloat(40 * duration)

        func animateScroll() {
            let xOffset = self.puzzleView.contentOffset.x + offset
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveLinear,
                           animations: {
                            self.puzzleView.contentOffset = CGPoint(x: xOffset,
                                                                    y: 0)
            }, completion: nil)
        }

        puzzleTimer?.invalidate()
        puzzleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            animateScroll()
        }
        puzzleTimer?.fire()

        isMenuVisable = true
        view.setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle,
                       animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.view.isUserInteractionEnabled = true
            if UserDefaults.standard.bool(forKey: "ShouldPromptForRating") {
                #if !DEBUG
                SKStoreReviewController.requestReview()
                #endif
            }
        })
    }

}
