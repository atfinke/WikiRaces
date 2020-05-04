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

    // MARK: - Actions -

    /// Join button pressed
    @objc
    func showLocalRaceOptions() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .pressedLocalOptions)

        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .localOptions)
    }

    @objc
    func joinGlobalRace() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .pressedGlobalJoin)
        PlayerDatabaseStat.gkPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard GKLocalPlayer.local.isAuthenticated || UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") else {
            self.listenerUpdate?(.presentGlobalAuth)
            return
        }

        guard !promptGlobalRacesPopularity() else {
            return
        }

        animateMenuOut {
            self.listenerUpdate?(.presentGlobalConnect)
        }
    }

    /// Join button pressed
    @objc
    func joinLocalRace() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .pressedJoin)
        PlayerDatabaseStat.mpcPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: false) else {
            return
        }

        animateMenuOut {
            self.listenerUpdate?(.presentMPCConnect(isHost: false))
        }
    }

    /// Create button pressed
    @objc
    func createLocalRace() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .pressedHost)
        PlayerDatabaseStat.mpcPressedHost.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptForCustomName(isHost: true) else {
            return
        }

        animateMenuOut {
            self.listenerUpdate?(.presentMPCConnect(isHost: true))
        }
    }

    @objc
    func backButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        animateOptionsOutAndTransition(to: .raceTypeOptions)
    }

    @objc
    func plusButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        animateOptionsOutAndTransition(to: .plusOptions)
    }

    @objc
    func statsButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        animateMenuOut {
            self.listenerUpdate?(.presentStats)
        }
    }

    /// Called when a tile is pressed
    ///
    /// - Parameter sender: The pressed tile
    @objc
    func menuTilePressed(sender: MenuTile) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        guard GKLocalPlayer.local.isAuthenticated else {
            self.listenerUpdate?(.presentGlobalAuth)
            return
        }

        animateMenuOut {
            self.listenerUpdate?(.presentLeaderboard)
        }
    }

    func triggeredEasterEgg() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        medalView.showMedals()
    }

    // MARK: - Menu Animations -

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
