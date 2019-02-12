//
//  MenuViewController+UI.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

extension MenuViewController {

    // MARK: - Interface

    /// By WikiRaces 4 I hope there is a better way to do this
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Button Styles

        let buttonStyle: WKRUIButtonStyle
        let buttonWidth: CGFloat
        let buttonHeight: CGFloat
        if view.frame.size.width > 420 {
            buttonStyle = .large
            buttonWidth = 195
            buttonHeight = 50
        } else {
            buttonStyle = .normal
            buttonWidth = 175
            buttonHeight = 40
        }

        if view.frame.size.width < UIScreen.main.bounds.width / 1.8 {
            leftMenuTile?.title = "WIKI\nPOINTS"
            middleMenuTile?.title = "AVG PER\nRACE"
            rightMenuTile?.title = "RACES\nPLAYED"
        } else {
            leftMenuTile?.title = "WIKI POINTS"
            middleMenuTile?.title = "AVG PER RACE"
            rightMenuTile?.title = "RACES PLAYED"
        }

        createButton.style = buttonStyle
        joinButton.style = buttonStyle

        // Label Fonts

        titleLabel.font = UIFont.boldSystemFont(ofSize: min(view.frame.size.width / 10.0, 55))
        subtitleLabel.font = UIFont.systemFont(ofSize: min(view.frame.size.width / 18.0, 30), weight: .medium)

        // Constraints

        titleLabelConstraint.constant = view.frame.size.height / 7

        if isMenuVisable {
            topViewLeftConstraint.constant = 0
            bottomViewAnchorConstraint.constant = 0

            if view.frame.size.height < 650 {
                bottomViewAnchorConstraint.constant = 75
            }
        } else {
            topViewLeftConstraint.constant = -topView.frame.width
            bottomViewAnchorConstraint.constant = bottomView.frame.height
        }

        createButtonWidthConstraint.constant = buttonWidth + 30
        createButtonHeightConstraint.constant = buttonHeight

        joinButtonWidthConstraint.constant = buttonWidth
        joinButtonHeightConstraint.constant = buttonHeight
    }

    /// One-off setup
    func setupInterface() {
        view.backgroundColor = UIColor.wkrBackgroundColor
        UIApplication.shared.keyWindow?.backgroundColor = UIColor.wkrBackgroundColor

        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.backgroundColor = UIColor.wkrMenuTopViewColor
        view.addSubview(topView)

        bottomView.backgroundColor = UIColor.wkrMenuBottomViewColor
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomView)

        topViewLeftConstraint = topView.leftAnchor.constraint(equalTo: view.leftAnchor)
        bottomViewAnchorConstraint = bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 250)
        bottomViewHeightConstraint = bottomView.heightAnchor.constraint(equalToConstant: 250)

        setupTopView()
        setupBottomView()

        let constraints = [
            topView.topAnchor.constraint(equalTo: view.topAnchor),
            topView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            topView.widthAnchor.constraint(equalTo: view.widthAnchor),

            bottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
            bottomView.widthAnchor.constraint(equalTo: view.widthAnchor),
            bottomViewHeightConstraint!,

            topViewLeftConstraint!,
            bottomViewAnchorConstraint!
        ]
        NSLayoutConstraint.activate(constraints)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        puzzleViewHeightConstraint.constant = 75 + view.safeAreaInsets.bottom / 2
        bottomViewHeightConstraint.constant = 250 + view.safeAreaInsets.bottom / 2
    }

    // MARK: - Top View

    /// Sets up the top view of the menu
    private func setupTopView() {
        setupLabels()
        setupButtons()

        titleLabelConstraint = titleLabel.topAnchor.constraint(equalTo: topView.topAnchor, constant: 200)

        createButtonWidthConstraint = createButton.widthAnchor.constraint(equalToConstant: 215)
        createButtonHeightConstraint = createButton.heightAnchor.constraint(equalToConstant: 45)
        joinButtonWidthConstraint = joinButton.widthAnchor.constraint(equalToConstant: 185)
        joinButtonHeightConstraint = joinButton.heightAnchor.constraint(equalToConstant: 45)

        let constraints = [
            titleLabelConstraint!,

            joinButtonWidthConstraint!,
            joinButtonHeightConstraint!,

            createButtonWidthConstraint!,
            createButtonHeightConstraint!,

            titleLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            titleLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),

            subtitleLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            subtitleLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            joinButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40.0),
            joinButton.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),

            createButton.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            createButton.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 20.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    /// Sets up the buttons
    private func setupButtons() {
        joinButton.title = "Join race"
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addTarget(self, action: #selector(joinRace), for: .touchUpInside)
        topView.addSubview(joinButton)

        createButton.title = "Create race"
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createRace), for: .touchUpInside)
        topView.addSubview(createButton)
    }

    /// Sets up the labels
    private func setupLabels() {
        titleLabel.text = "WikiRaces"
        titleLabel.textColor = UIColor.wkrTextColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(titleLabel)

        #if DEBUG
            titleLabel.textColor = UIColor(red: 51.0 / 255.0, green: 102.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)

            let networkType = UserDefaults.standard.bool(forKey: "NetworkTypeGameKit")
            titleLabel.text = networkType ? "WikiRaces [GK]" : "WikiRaces [MPC]"
        #endif

        subtitleLabel.text = "Conquer the encyclopedia\nof everything."
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textColor = UIColor.wkrTextColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.clipsToBounds = true
        topView.addSubview(subtitleLabel)
    }

    // MARK: - Bottom View

    /// Sets up the bottom views
    private func setupBottomView() {
        let stackView = setupStatsStackView()
        let puzzleView = setupPuzzleView()
        puzzleViewHeightConstraint = puzzleView.heightAnchor.constraint(equalToConstant: 75)

        let constraints = [
            puzzleViewHeightConstraint!,
            puzzleView.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
            puzzleView.rightAnchor.constraint(equalTo: bottomView.rightAnchor),
            puzzleView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),

            stackView.leftAnchor.constraint(equalTo: bottomView.leftAnchor, constant: 15),
            stackView.rightAnchor.constraint(equalTo: bottomView.rightAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: bottomView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: puzzleView.topAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    /// Sets up the stack view that holds the menu tiles
    //swiftlint:disable:next function_body_length
    private func setupStatsStackView() -> UIStackView {
        let statsStackView = UIStackView()
        statsStackView.distribution = .fillEqually
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(statsStackView)

        let leftMenuTile = MenuTile(title: "WIKI POINTS")
        leftMenuTile.stat = .mpcPoints
        leftMenuTile.value = StatsHelper.shared.points
        statsStackView.addArrangedSubview(leftMenuTile)

        let middleMenuTile = MenuTile(title: "AVG PER RACE")
        middleMenuTile.stat = .average
        middleMenuTile.value = StatsHelper.shared.statValue(for: .average)
        statsStackView.addArrangedSubview(middleMenuTile)

        let leftThinLine = WKRUIThinLineView()
        middleMenuTile.addSubview(leftThinLine)
        let rightThinLine = WKRUIThinLineView()
        middleMenuTile.addSubview(rightThinLine)

        let rightMenuTile = MenuTile(title: "RACES PLAYED")
        rightMenuTile.stat = .mpcRaces
        rightMenuTile.value = StatsHelper.shared.races
        statsStackView.addArrangedSubview(rightMenuTile)

        let constraints = [
            leftThinLine.leftAnchor.constraint(equalTo: middleMenuTile.leftAnchor),
            leftThinLine.topAnchor.constraint(equalTo: middleMenuTile.topAnchor, constant: 30),
            leftThinLine.bottomAnchor.constraint(equalTo: middleMenuTile.bottomAnchor, constant: -25),
            leftThinLine.widthAnchor.constraint(equalToConstant: 2),

            rightThinLine.rightAnchor.constraint(equalTo: middleMenuTile.rightAnchor),
            rightThinLine.topAnchor.constraint(equalTo: middleMenuTile.topAnchor, constant: 30),
            rightThinLine.bottomAnchor.constraint(equalTo: middleMenuTile.bottomAnchor, constant: -25),
            rightThinLine.widthAnchor.constraint(equalToConstant: 2)
        ]
        NSLayoutConstraint.activate(constraints)

        leftMenuTile.addTarget(self, action: #selector(menuTilePressed(sender:)), for: .touchUpInside)
        middleMenuTile.addTarget(self, action: #selector(menuTilePressed(sender:)), for: .touchUpInside)
        rightMenuTile.addTarget(self, action: #selector(menuTilePressed(sender:)), for: .touchUpInside)

        self.leftMenuTile = leftMenuTile
        self.middleMenuTile = middleMenuTile
        self.rightMenuTile = rightMenuTile

        StatsHelper.shared.keyStatsUpdated = { points, races, average in
            DispatchQueue.main.async {
                self.leftMenuTile?.value = points
                self.middleMenuTile?.value = average
                self.rightMenuTile?.value = races
            }
        }

        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            self.leftMenuTile?.value = 140
            self.middleMenuTile?.value = 140/72
            self.rightMenuTile?.value = 72
        }

        return statsStackView
    }

    /// Sets up the view that animates the puzzzle pieces
    private func setupPuzzleView() -> UIView {
        let puzzleBackgroundView = UIView()

        puzzleBackgroundView.isUserInteractionEnabled = false
        puzzleBackgroundView.backgroundColor = UIColor.wkrMenuPuzzleViewColor
        puzzleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(puzzleBackgroundView)

        puzzleView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "MenuBackgroundPuzzle"))
        puzzleView.translatesAutoresizingMaskIntoConstraints = false
        puzzleBackgroundView.addSubview(puzzleView)

        let constraints = [
            puzzleView.leftAnchor.constraint(equalTo: puzzleBackgroundView.leftAnchor),
            puzzleView.rightAnchor.constraint(equalTo: puzzleBackgroundView.rightAnchor),
            puzzleView.topAnchor.constraint(equalTo: puzzleBackgroundView.topAnchor, constant: 22.5),
            puzzleView.heightAnchor.constraint(equalToConstant: 30)
        ]
        NSLayoutConstraint.activate(constraints)

        return puzzleBackgroundView
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.wkrStatusBarStyle
    }
}
