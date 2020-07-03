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
        case joinOrCreate, noOptions, joinOptions, plusOptions, noInterface
    }

    enum ListenerUpdate {
        case presentDebug, presentLeaderboard
        case presentJoinPublicRace, presentJoinPrivateRace
        case presentCreateRace
        case presentAlert(UIAlertController)
        case presentStats, presentSubscription
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

    let joinButton = WKRUIButton()
    let createButton = WKRUIButton()

    let publicButton = WKRUIButton()
    let privateButton = WKRUIButton()

    let backButton = UIButton()
    let plusButton = UIButton()

    let statsButton = WKRUIButton()

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

    var joinButtonLeftConstraint: NSLayoutConstraint!
    var joinButtonWidthConstraint: NSLayoutConstraint!
    var joinButtonHeightConstraint: NSLayoutConstraint!
    var createButtonWidthConstraint: NSLayoutConstraint!

    var publicButtonWidthConstraint: NSLayoutConstraint!
    var privateButtonLeftConstraint: NSLayoutConstraint!
    var privateButtonWidthConstraint: NSLayoutConstraint!

    var backButtonLeftConstraintForJoinOptions: NSLayoutConstraint!
    var backButtonLeftConstraintForStats: NSLayoutConstraint!
    var backButtonWidth: NSLayoutConstraint!

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

        titleLabel.text = "WikiRaces"
        bottomView.backgroundColor = .wkrMenuBottomViewColor(for: traitCollection)

        let textColor: UIColor = .wkrTextColor(for: traitCollection)
        titleLabel.textColor = textColor
        subtitleLabel.textColor = textColor
        backButton.tintColor = textColor
        backButton.layer.borderColor = textColor.cgColor
        backButton.layer.borderWidth = 1.7

        plusButton.tintColor = backButton.tintColor
        plusButton.layer.borderColor = backButton.layer.borderColor
        plusButton.layer.borderWidth = backButton.layer.borderWidth

        // Button Styles
        let buttonStyle: WKRUIButtonStyle
        let buttonWidth: CGFloat
        let buttonHeight: CGFloat
        if frame.size.width > 420 {
            buttonStyle = .large
            buttonWidth = 150
            buttonHeight = 50
        } else {
            buttonStyle = .normal
            buttonWidth = 100
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

        joinButton.style = buttonStyle
        createButton.style = buttonStyle
        publicButton.style = buttonStyle
        privateButton.style = buttonStyle
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
        case .joinOrCreate:
            joinButtonLeftConstraint.constant = 30
            privateButtonLeftConstraint.constant = -privateButton.frame.width * 2

            statsButtonLeftConstraint.constant = -statsButton.frame.width

            topViewLeftConstraint.constant = 0
            bottomViewAnchorConstraint.constant = 0

            if frame.size.height < 650 {
                bottomViewAnchorConstraint.constant = 75
            }
        case .noOptions:
            joinButtonLeftConstraint.constant = -createButton.frame.width
            privateButtonLeftConstraint.constant = -privateButton.frame.width
            statsButtonLeftConstraint.constant = -statsButton.frame.width
        case .joinOptions:
            joinButtonLeftConstraint.constant = -createButton.frame.width
            privateButtonLeftConstraint.constant = 30

            backButtonLeftConstraintForStats.isActive = false
            backButtonLeftConstraintForJoinOptions.isActive = true
        case .noInterface:
            topViewLeftConstraint.constant = -topView.frame.width
            bottomViewAnchorConstraint.constant = bottomView.frame.height
            joinButtonLeftConstraint.constant = 30
            privateButtonLeftConstraint.constant = 30
        case .plusOptions:
            joinButtonLeftConstraint.constant = -createButton.frame.width
            statsButtonLeftConstraint.constant = 30

            backButtonLeftConstraintForJoinOptions.isActive = false
            backButtonLeftConstraintForStats.isActive = true
        }

        joinButtonHeightConstraint.constant = buttonHeight
        joinButtonWidthConstraint.constant = buttonWidth + 10
        createButtonWidthConstraint.constant = buttonWidth + 40

        publicButtonWidthConstraint.constant = buttonWidth + 34
        privateButtonWidthConstraint.constant = buttonWidth + 44
        statsButtonWidthConstraint.constant = buttonWidth + 20

        backButtonWidth.constant = buttonHeight - 10

        backButton.layer.cornerRadius = backButtonWidth.constant / 2
        plusButton.layer.cornerRadius = backButton.layer.cornerRadius
    }

    func promptGlobalRacesPopularity() -> Bool {
        guard !Defaults.promptedGlobalRacesPopularity else {
            return false
        }
        Defaults.promptedGlobalRacesPopularity = true

        let message = "Most racers use private races to play with friends. Create a private race and invite a friend for the best chance at joining a race. You can also start a solo race at any time."
        let alertController = UIAlertController(title: "Public Races", message: message, preferredStyle: .alert)

        let action = UIAlertAction(title: "Find Public Race", style: .default, handler: { _ in
            PlayerFirebaseAnalytics.log(event: .userAction("promptGlobalRacesPopularity:ok"))
            self.animateMenuOut {
                self.listenerUpdate?(.presentJoinPublicRace)
            }
        })
        alertController.addAction(action)

        listenerUpdate?(.presentAlert(alertController))
        return true
    }

}
