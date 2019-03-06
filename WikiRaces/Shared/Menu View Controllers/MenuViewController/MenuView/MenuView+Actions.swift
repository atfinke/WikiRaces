//
//  MenuView+Actions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/23/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit.GKLocalPlayer

extension MenuView {

    // MARK: - Actions

    /// Join button pressed
    @objc
    func showLocalRaceOptions() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedLocalOptions)

        UISelectionFeedbackGenerator().selectionChanged()

        animateOptionsOutAndTransition(to: .localOptions)
    }

    @objc
    func joinGlobalRace() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedGlobalJoin)
        PlayerStat.gkPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard GKLocalPlayer.local.isAuthenticated else {
            self.presentGlobalAuthController?()
            return
        }

        animateMenuOut {
            self.presentGlobalConnectController?()
        }
    }

    /// Join button pressed
    @objc
    func joinLocalRace() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedJoin)
        PlayerStat.mpcPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: false) else {
            return
        }

        animateMenuOut {
            self.presentMPCConnectController?(false)
        }
    }

    /// Create button pressed
    @objc
    func createLocalRace() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedHost)
        PlayerStat.mpcPressedHost.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: true) else {
            return
        }

        animateMenuOut {
            self.presentMPCConnectController?(true)
        }
    }

    @objc
    func localOptionsBackButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        animateOptionsOutAndTransition(to: .raceTypeOptions)
    }

    /// Called when a tile is pressed
    ///
    /// - Parameter sender: The pressed tile
    @objc
    func menuTilePressed(sender: MenuTile) {
        PlayerMetrics.log(event: .userAction(#function))

        guard GKLocalPlayer.local.isAuthenticated else {
            self.presentGlobalAuthController?()
            return
        }

        animateMenuOut {
            self.presentLeaderboardController?()
        }
    }

    // MARK: - Menu Animations

    /// Animates the views on screen
    func animateMenuIn(completion: (() -> Void)? = nil) {
        isUserInteractionEnabled = false

        movingPuzzleView.start()

        state = .raceTypeOptions
        setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle,
                       animations: {
                        self.layoutIfNeeded()
        }, completion: { _ in
            self.isUserInteractionEnabled = true
            completion?()
        })
    }

    /// Animates the views off screen
    ///
    /// - Parameter completion: The completion handler
    func animateMenuOut(completion: (() -> Void)?) {
        isUserInteractionEnabled = false

        state = .noInterface
        setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle, animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            self.movingPuzzleView.stop()
            completion?()
        })
    }

    func animateOptionsOutAndTransition(to state: InterfaceState) {
        self.state = .noOptions
        setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle / 2,
                       animations: {
                        self.layoutIfNeeded()
        }, completion: { _ in
            self.state = state
            self.setNeedsLayout()

            UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle / 2,
                           delay: WKRAnimationDurationConstants.menuToggle /  4,
                           animations: {
                            self.layoutIfNeeded()
            })
        })
    }

}
