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

    /// Custom button pressed
    @objc
    func showCustomOptions() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .customOptions)
    }

    @objc
    func joinStandardRace() {
        PlayerFirebaseAnalytics.log(event: .revampPressedJoinPublic)
        PlayerUserDefaultsStat.gkPressedJoin.increment()
        
        UISelectionFeedbackGenerator().selectionChanged()
        
        animateMenuOut {
            self.listenerUpdate?(.presentStandardRace)
        }
    }

    @objc
    func joinCustomRace() {
        PlayerFirebaseAnalytics.log(event: .revampPressedJoinPrivate)
        PlayerUserDefaultsStat.mpcPressedJoin.increment()

        UISelectionFeedbackGenerator().selectionChanged()

        animateMenuOut {
            self.listenerUpdate?(.presentJoinCustomRace)
        }
    }

    @objc
    func createCustomRace() {
        PlayerFirebaseAnalytics.log(event: .revampPressedJoinPrivate)
        PlayerUserDefaultsStat.mpcPressedHost.increment()

        UISelectionFeedbackGenerator().selectionChanged()
        
        PlayerCloudKitLiveRaceManager.shared.isCloudEnabled { isEnabled in
            DispatchQueue.main.async {
                if isEnabled || Defaults.isFastlaneSnapshotInstance {
                    self.animateMenuOut {
                        self.listenerUpdate?(.presentCreateCustomRace)
                    }
                } else {
                    let message = "You must have iCloud Drive enabled for WikiRaces to create a custom race. You can still join any race."
                    let alertController = UIAlertController(title: "iCloud Issue", message: message, preferredStyle: .alert)
                    alertController.addCancelAction(title: "Ok")

                    #if targetEnvironment(simulator)
                    let action = UIAlertAction(title: "SIM BYPASS", style: .default) { _ in
                        self.animateMenuOut {
                            self.listenerUpdate?(.presentCreateCustomRace)
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
    func backButtonPressed() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .standardOrCustom)
    }

    @objc
    func plusButtonPressed() {
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .plusOptions)
    }

    @objc
    func statsButtonPressed() {
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

        animateMenuOut {
            self.listenerUpdate?(.presentLeaderboard)
        }
    }

    func triggeredEasterEgg() {
        medalView.showMedals()
    }

    // MARK: - Menu Animations -

    /// Animates the views on screen
    func animateMenuIn(completion: (() -> Void)? = nil) {
        isUserInteractionEnabled = false

        movingPuzzleView.start()

        state = .standardOrCustom
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
