//
//  MenuView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/23/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import StoreKit
import WKRUIKit

final class MenuView: UIView {

    // MARK: Types

    enum InterfaceState {
        case raceTypeOptions, noOptions, localOptions, plusOptions, noInterface
    }

    enum ListenerUpdate {
        case presentDebug, presentGlobalConnect, presentLeaderboard, presentGlobalAuth
        case presentMPCConnect(isHost: Bool)
        case presentAlert(UIAlertController)
        case presentStats
    }

    // MARK: - Closures

    var listenerUpdate: ((ListenerUpdate) -> Void)?

    // MARK: - Properties

    /// Used to track if the menu should be animating
    var state = InterfaceState.noInterface

    // MARK: - Interface Elements

    /// The top of the menu (everything on white). Animates out of the left side.
    let topView = UIView()
    /// The bottom of the menu (everything not white). Animates out of the bottom.
    let bottomView = UIView()

    /// The "WikiRaces" label
    let titleLabel = UILabel()
    /// The "Conquer..." label
    let subtitleLabel = UILabel()

    let localRaceTypeButton = WKRUIButton()
    let globalRaceTypeButton = WKRUIButton()
    let joinLocalRaceButton = WKRUIButton()
    let createLocalRaceButton = WKRUIButton()
    let localOptionsBackButton = UIButton()

    let plusButton = UIButton()

    let statsButton = WKRUIButton()
    let plusOptionsBackButton = UIButton()

    /// The Wiki Points tile
    var leftMenuTile: MenuTile?
    /// The average points tile
    var middleMenuTile: MenuTile?
    /// The races tile
    var rightMenuTile: MenuTile?

    /// The puzzle piece view
    let movingPuzzleView = MovingPuzzleView()

    /// The easter egg medal view
    let medalView = MedalView()

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

    var localRaceTypeButtonLeftConstraint: NSLayoutConstraint!
    var localRaceTypeButtonWidthConstraint: NSLayoutConstraint!
    var localRaceTypeButtonHeightConstraint: NSLayoutConstraint!
    var globalRaceTypeButtonWidthConstraint: NSLayoutConstraint!

    var joinLocalRaceButtonLeftConstraint: NSLayoutConstraint!
    var joinLocalRaceButtonWidthConstraint: NSLayoutConstraint!
    var createLocalRaceButtonWidthConstraint: NSLayoutConstraint!
    var localOptionsBackButtonWidth: NSLayoutConstraint!

    var statsButtonLeftConstraint: NSLayoutConstraint!
    var statsButtonWidthConstraint: NSLayoutConstraint!

    // MARK: - View Life Cycle

    init() {
        super.init(frame: .zero)

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerFired))
        recognizer.numberOfTapsRequired = 2
        recognizer.numberOfTouchesRequired = 2
        titleLabel.addGestureRecognizer(recognizer)
        titleLabel.isUserInteractionEnabled = true

        topView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topView)

        bottomView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomView)

        topViewLeftConstraint = topView.leftAnchor.constraint(equalTo: leftAnchor)
        bottomViewAnchorConstraint = bottomView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 250)
        bottomViewHeightConstraint = bottomView.heightAnchor.constraint(equalToConstant: 250)

        setupTopView()
        setupBottomView()

        let constraints = [
            topView.topAnchor.constraint(equalTo: topAnchor),
            topView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            topView.widthAnchor.constraint(equalTo: widthAnchor),

            bottomView.leftAnchor.constraint(equalTo: leftAnchor),
            bottomView.widthAnchor.constraint(equalTo: widthAnchor),
            bottomViewHeightConstraint!,

            topViewLeftConstraint!,
            bottomViewAnchorConstraint!
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc func tapGestureRecognizerFired() {
        listenerUpdate?(.presentDebug)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        puzzleViewHeightConstraint.constant = 75 + safeAreaInsets.bottom / 2
        bottomViewHeightConstraint.constant = 250 + safeAreaInsets.bottom / 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.text = "WikiRaces" + (PlusStore.shared.isPlus ? "+" : "")
        bottomView.backgroundColor = .wkrMenuBottomViewColor(for: traitCollection)

        let textColor: UIColor = .wkrTextColor(for: traitCollection)
        titleLabel.textColor = textColor
        subtitleLabel.textColor = textColor
        localOptionsBackButton.tintColor = textColor
        localOptionsBackButton.layer.borderColor = textColor.cgColor
        localOptionsBackButton.layer.borderWidth = 1.7

        plusOptionsBackButton.tintColor = localOptionsBackButton.tintColor
        plusOptionsBackButton.layer.borderColor = localOptionsBackButton.layer.borderColor
        plusOptionsBackButton.layer.borderWidth = localOptionsBackButton.layer.borderWidth

        plusButton.tintColor = localOptionsBackButton.tintColor
        plusButton.layer.borderColor = localOptionsBackButton.layer.borderColor
        plusButton.layer.borderWidth = localOptionsBackButton.layer.borderWidth

        // Button Styles
        let buttonStyle: WKRUIButtonStyle
        let buttonWidth: CGFloat
        let buttonHeight: CGFloat
        if frame.size.width > 420 {
            buttonStyle = .large
            buttonWidth = 210
            buttonHeight = 50
        } else {
            buttonStyle = .normal
            buttonWidth = 175
            buttonHeight = 40
        }

        if frame.size.width < UIScreen.main.bounds.width / 1.8 {
            leftMenuTile?.title = "WIKI\nPOINTS"
            middleMenuTile?.title = "AVG PER\nRACE"
            rightMenuTile?.title = "RACES\nPLAYED"
        } else {
            leftMenuTile?.title = "WIKI POINTS"
            middleMenuTile?.title = "AVG PER RACE"
            rightMenuTile?.title = "RACES PLAYED"
        }

        localRaceTypeButton.style = buttonStyle
        globalRaceTypeButton.style = buttonStyle
        joinLocalRaceButton.style = buttonStyle
        createLocalRaceButton.style = buttonStyle
        statsButton.style = buttonStyle

        // Label Fonts
        titleLabel.font = UIFont.systemFont(ofSize: min(frame.size.width / 10.0, 55), weight: .semibold)
        subtitleLabel.font = UIFont.systemFont(ofSize: min(frame.size.width / 18.0, 30), weight: .medium)

        // Constraints
        if UIDevice.current.userInterfaceIdiom == .pad {
            titleLabelConstraint.constant = frame.size.height / 8
        } else {
            titleLabelConstraint.constant = frame.size.height / 11
        }

        switch state {
        case .raceTypeOptions:
            localRaceTypeButtonLeftConstraint.constant = 30
            joinLocalRaceButtonLeftConstraint.constant = -createLocalRaceButton.frame.width
            statsButtonLeftConstraint.constant = -statsButton.frame.width

            topViewLeftConstraint.constant = 0
            bottomViewAnchorConstraint.constant = 0

            if frame.size.height < 650 {
                bottomViewAnchorConstraint.constant = 75
            }
        case .noOptions:
            localRaceTypeButtonLeftConstraint.constant = -globalRaceTypeButton.frame.width
            joinLocalRaceButtonLeftConstraint.constant = -createLocalRaceButton.frame.width
            statsButtonLeftConstraint.constant = -statsButton.frame.width
        case .localOptions:
            localRaceTypeButtonLeftConstraint.constant = -globalRaceTypeButton.frame.width
            joinLocalRaceButtonLeftConstraint.constant = 30
        case .noInterface:
            topViewLeftConstraint.constant = -topView.frame.width
            bottomViewAnchorConstraint.constant = bottomView.frame.height
            localRaceTypeButtonLeftConstraint.constant = 30
            joinLocalRaceButtonLeftConstraint.constant = 30
        case .plusOptions:
            localRaceTypeButtonLeftConstraint.constant = -globalRaceTypeButton.frame.width
            statsButtonLeftConstraint.constant = 30
        }

        localRaceTypeButtonHeightConstraint.constant = buttonHeight
        localRaceTypeButtonWidthConstraint.constant = buttonWidth + 18
        globalRaceTypeButtonWidthConstraint.constant = buttonWidth + 32

        joinLocalRaceButtonWidthConstraint.constant = buttonWidth
        createLocalRaceButtonWidthConstraint.constant = buttonWidth + 30
        localOptionsBackButtonWidth.constant = buttonHeight - 10

        statsButtonWidthConstraint.constant = buttonWidth + 13

        localOptionsBackButton.layer.cornerRadius = localOptionsBackButtonWidth.constant / 2
        plusOptionsBackButton.layer.cornerRadius = localOptionsBackButton.layer.cornerRadius
        plusButton.layer.cornerRadius = localOptionsBackButton.layer.cornerRadius
    }

    func promptForCustomName(isHost: Bool) -> Bool {
        guard !UserDefaults.standard.bool(forKey: "PromptedCustomName") else {
            return false
        }
        UserDefaults.standard.set(true, forKey: "PromptedCustomName")

        let message = "Would you like to set a custom player name for local races?"
        let alertController = UIAlertController(title: "Set Name?", message: message, preferredStyle: .alert)

        let laterAction = UIAlertAction(title: "Maybe Later", style: .cancel, handler: { _ in
            PlayerAnonymousMetrics.log(event: .userAction("promptForCustomNamePrompt:rejected"))
            PlayerAnonymousMetrics.log(event: .namePromptResult, attributes: ["Result": "Cancelled"])
            if isHost {
                self.createLocalRace()
            } else {
                self.joinLocalRace()
            }
        })
        alertController.addAction(laterAction)

        let settingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            PlayerAnonymousMetrics.log(event: .userAction("promptForCustomNamePrompt:accepted"))
            PlayerAnonymousMetrics.log(event: .namePromptResult, attributes: ["Result": "Accepted"])
            UIApplication.shared.openSettings()
        })
        alertController.addAction(settingsAction)

        listenerUpdate?(.presentAlert(alertController))
        return true
    }

    func promptGlobalRacesPopularity() -> Bool {
        guard !UserDefaults.standard.bool(forKey: "PromptedGlobalRacesPopularity") else {
            return false
        }
        UserDefaults.standard.set(true, forKey: "PromptedGlobalRacesPopularity")

        let message = "Most global races are started with invited friends. Invite a friend for the best chance at joining a race."
        let alertController = UIAlertController(title: "Global Races", message: message, preferredStyle: .alert)

        let action = UIAlertAction(title: "Ok", style: .default, handler: { _ in
            PlayerAnonymousMetrics.log(event: .userAction("promptGlobalRacesPopularity:ok"))
            self.animateMenuOut {
                self.listenerUpdate?(.presentGlobalConnect)
            }
        })
        alertController.addAction(action)

        listenerUpdate?(.presentAlert(alertController))
        return true
    }

}
