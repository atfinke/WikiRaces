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
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .joinOptions)
    }
    
    @objc
    func createRace() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .revampPressedHost)
        
        UISelectionFeedbackGenerator().selectionChanged()
        
        //        guard GKLocalPlayer.local.isAuthenticated || Defaults.isFastlaneSnapshotInstance else {
        //            self.listenerUpdate?(.presentGKAuth)
        //            return
        //        }
        //
        animateMenuOut {
            self.listenerUpdate?(.presentCreateRace)
        }
    }
    
    @objc
    func joinPublicRace() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .revampPressedJoinPublic)
        PlayerDatabaseStat.gkPressedJoin.increment()
        
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
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .revampPressedJoinPrivate)
        PlayerDatabaseStat.mpcPressedJoin.increment()
        
        UISelectionFeedbackGenerator().selectionChanged()
        
        animateMenuOut {
            self.listenerUpdate?(.presentJoinPrivateRace)
        }
    }
    
    @objc
    func backButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        UISelectionFeedbackGenerator().selectionChanged()
        animateOptionsOutAndTransition(to: .joinOrCreate)
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
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        
        guard GKLocalPlayer.local.isAuthenticated else {
            self.listenerUpdate?(.presentGKAuth)
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
