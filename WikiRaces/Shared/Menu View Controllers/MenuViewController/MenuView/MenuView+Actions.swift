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

        state = .noOptions
        setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle / 2, animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            self.state = .localOptions
            self.setNeedsLayout()
            UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle / 2, animations: {
                self.layoutIfNeeded()
            })
        })
    }

    @objc
    func joinGlobalRace() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedGlobalJoin)

        UISelectionFeedbackGenerator().selectionChanged()

        animateMenuOut {
            self.presentGlobalConnectController?()
            StatsHelper.shared.increment(stat: .gkPressedJoin)
        }
    }

    /// Join button pressed
    @objc
    func joinLocalRace() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedJoin)

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: false) else {
            return
        }

        animateMenuOut {
            self.presentMPCConnectController?(false)
            StatsHelper.shared.increment(stat: .mpcPressedJoin)
        }
    }

    /// Create button pressed
    @objc
    func createLocalRace() {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .pressedHost)

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: true) else {
            return
        }

        animateMenuOut {
            self.presentMPCConnectController?(true)
            StatsHelper.shared.increment(stat: .mpcPressedHost)
        }
    }

    @objc
    func localOptionsBackButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        state = .noOptions
        setNeedsLayout()

        UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle / 2, animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            self.state = .raceTypeOptions
            self.setNeedsLayout()
            UIView.animate(withDuration: WKRAnimationDurationConstants.menuToggle / 2, animations: {
                self.layoutIfNeeded()
            })
        })
    }

    // MARK: - Menu Animations

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
            self.puzzleTimer?.invalidate()
            completion?()
        })
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

}
