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
    func showJoinOptions() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .joinOptions)
    }

    @objc
    func createRace() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        PlayerFirebaseAnalytics.log(event: .revampPressedHost)

        UISelectionFeedbackGenerator().selectionChanged()

        PlayerCloudKitLiveRaceManager.shared.isCloudEnabled { isEnabled in
            DispatchQueue.main.async {
                if isEnabled || Defaults.isFastlaneSnapshotInstance {
                    self.animateMenuOut {
                        self.listenerUpdate?(.presentCreateRace)
                    }
                } else {
                    let message = "You must have iCloud Drive enabled for WikiRaces to create a private race."
                    let alertController = UIAlertController(title: "iCloud Issue", message: message, preferredStyle: .alert)
                    alertController.addCancelAction(title: "Ok")

                    #if targetEnvironment(simulator)
                    let action = UIAlertAction(title: "SIM BYPASS", style: .default) { _ in
                        self.animateMenuOut {
                            self.listenerUpdate?(.presentCreateRace)
                        }
                    }
                    alertController.addAction(action)
                    #endif

                    self.listenerUpdate?(.presentAlert(alertController))
                    PlayerFirebaseAnalytics.log(event: .revampPressedHostiCloudIssue)
                }

            }
        }
    }

    @objc
    func joinPublicRace() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        PlayerFirebaseAnalytics.log(event: .revampPressedJoinPublic)
        PlayerUserDefaultsStat.gkPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        guard !promptGlobalRacesPopularity() else {
            return
        }

        animateMenuOut {
            self.listenerUpdate?(.presentJoinPublicRace)
        }
    }

    @objc
    func joinPrivateRace() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        PlayerFirebaseAnalytics.log(event: .revampPressedJoinPrivate)
        PlayerUserDefaultsStat.mpcPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        animateMenuOut {
            self.listenerUpdate?(.presentJoinPrivateRace)
        }
    }

    @objc
    func backButtonPressed() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .joinOrCreate)
    }

    @objc
    func plusButtonPressed() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .plusOptions)
    }

    @objc
    func statsButtonPressed() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        UISelectionFeedbackGenerator().selectionChanged()
        if PlusStore.shared.isPlus {
            animateMenuOut {
                self.listenerUpdate?(.presentStats)
            }
        } else {
            listenerUpdate?(.presentSubscription)
        }
    }

    /// Called when a tile is pressed
    ///
    /// - Parameter sender: The pressed tile
    @objc
    func menuTilePressed() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))

        animateMenuOut {
            self.listenerUpdate?(.presentLeaderboard)
        }
    }

    func triggeredEasterEgg() {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        medalView.showMedals()
    }

    // MARK: - Menu Animations -

    /// Animates the views on screen
    func animateMenuIn(completion: (() -> Void)? = nil) {
        isUserInteractionEnabled = false

        movingPuzzleView.start()

        state = .joinOrCreate
        setNeedsLayout()

        UIView.animate(
            withDuration: WKRAnimationDurationConstants.menuToggle,
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
        if state == .noInterface {
            completion?()
            return
        }

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

        UIView.animate(
            withDuration: WKRAnimationDurationConstants.menuToggle / 2,
            animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.state = state
                self.setNeedsLayout()

                UIView.animate(
                    withDuration: WKRAnimationDurationConstants.menuToggle / 2,
                    delay: WKRAnimationDurationConstants.menuToggle /  4,
                    animations: {
                        self.layoutIfNeeded()
                    })
            })
    }

}
