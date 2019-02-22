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
        #endif

        if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
            PlayerDatabaseMetrics.shared.log(event: .customName(name))
        }
        PlayerDatabaseMetrics.shared.log(event: .deviceName(UIDevice.current.name))

        promptForInvalidName()
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
            let isNetworkTypeGameKit = UserDefaults.standard.bool(forKey: "NetworkTypeGameKit")
            let segue = isNetworkTypeGameKit ? Segue.showGameKitConnecting : Segue.showMPCConnecting
            self.performSegue(segue, isHost: false)

            if isNetworkTypeGameKit {
                StatsHelper.shared.increment(stat: .gkPressedJoin)
            } else {
                StatsHelper.shared.increment(stat: .mpcPressedJoin)
            }
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
            let isNetworkTypeGameKit = UserDefaults.standard.bool(forKey: "NetworkTypeGameKit")
            let segue = isNetworkTypeGameKit ? Segue.showGameKitConnecting : Segue.showMPCConnecting
            self.performSegue(segue, isHost: true)

            if isNetworkTypeGameKit {
                StatsHelper.shared.increment(stat: .gkPressedJoin)
            } else {
                StatsHelper.shared.increment(stat: .mpcPressedHost)
            }
        }
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
            if SKStoreReviewController.shouldPromptForRating {
                #if !DEBUG
                SKStoreReviewController.requestReview()
                #endif
            }
        })
    }

}
