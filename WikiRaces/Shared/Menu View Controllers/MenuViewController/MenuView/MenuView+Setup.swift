//
//  MenuView+Setup.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/23/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

extension MenuView {

    // MARK: - Top View -

    /// Sets up the top view of the menu
    func setupTopView() {
        setupLabels()
        setupButtons()
        medalView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(medalView)

        titleLabelConstraint = titleLabel.topAnchor.constraint(equalTo: topView.safeAreaLayoutGuide.topAnchor)

        standardRaceButtonWidthConstraint = standardRaceButton.widthAnchor.constraint(equalToConstant: 0)
        standardRaceButtonHeightConstraint = standardRaceButton.heightAnchor.constraint(equalToConstant: 0)
        standardRaceButtonLeftConstraint = standardRaceButton.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 0)
        customRaceButtonWidthConstraint = customRaceButton.widthAnchor.constraint(equalToConstant: 0)

        joinButtonWidthConstraint = joinButton.widthAnchor.constraint(equalToConstant: 0)
        createButtonLeftConstraint = joinButton.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 0)
        createButtonWidthConstraint = createButton.widthAnchor.constraint(equalToConstant: 0)
        backButtonWidth = backButton.widthAnchor.constraint(equalToConstant: 30)

        statsButtonLeftConstraint = statsButton.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 0)
        statsButtonWidthConstraint = statsButton.widthAnchor.constraint(equalToConstant: 0)

        backButtonLeftConstraintForStats = backButton.leftAnchor.constraint(equalTo: statsButton.leftAnchor)
        backButtonLeftConstraintForJoinOptions = backButton.leftAnchor.constraint(equalTo: joinButton.leftAnchor)
        backButtonLeftConstraintForJoinOptions.isActive = true

        let constraints = [
            titleLabelConstraint!,

            medalView.topAnchor.constraint(equalTo: topView.topAnchor),
            medalView.bottomAnchor.constraint(equalTo: topView.bottomAnchor),
            medalView.leftAnchor.constraint(equalTo: topView.leftAnchor),
            medalView.rightAnchor.constraint(equalTo: topView.rightAnchor),

            titleLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            titleLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),

            subtitleLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            subtitleLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            standardRaceButtonWidthConstraint!,
            standardRaceButtonHeightConstraint!,
            standardRaceButtonLeftConstraint!,
            customRaceButtonWidthConstraint!,

            joinButtonWidthConstraint!,
            createButtonLeftConstraint!,
            createButtonWidthConstraint!,
            backButtonWidth!,

            statsButtonLeftConstraint!,
            statsButtonWidthConstraint!,

            standardRaceButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor,
                                            constant: 40.0),
            joinButton.topAnchor.constraint(equalTo: standardRaceButton.topAnchor),
            statsButton.topAnchor.constraint(equalTo: standardRaceButton.topAnchor),

            customRaceButton.heightAnchor.constraint(equalTo: standardRaceButton.heightAnchor),
            joinButton.heightAnchor.constraint(equalTo: standardRaceButton.heightAnchor),
            createButton.heightAnchor.constraint(equalTo: standardRaceButton.heightAnchor),
            statsButton.heightAnchor.constraint(equalTo: standardRaceButton.heightAnchor),

            customRaceButton.leftAnchor.constraint(equalTo: standardRaceButton.leftAnchor),
            createButton.leftAnchor.constraint(equalTo: joinButton.leftAnchor),
            customRaceButton.topAnchor.constraint(equalTo: standardRaceButton.bottomAnchor, constant: 20.0),
            createButton.topAnchor.constraint(equalTo: customRaceButton.topAnchor),

            plusButton.leftAnchor.constraint(equalTo: standardRaceButton.leftAnchor),
            plusButton.topAnchor.constraint(equalTo: customRaceButton.bottomAnchor, constant: 20.0),
            plusButton.widthAnchor.constraint(equalTo: backButton.widthAnchor),
            plusButton.heightAnchor.constraint(equalTo: backButton.widthAnchor),

            backButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 20.0),
            backButton.heightAnchor.constraint(equalTo: backButton.widthAnchor, multiplier: 1)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    /// Sets up the buttons
    private func setupButtons() {
        standardRaceButton.title = "standard"
        standardRaceButton.translatesAutoresizingMaskIntoConstraints = false
        standardRaceButton.addTarget(self, action: #selector(joinStandardRace), for: .touchUpInside)
        topView.addSubview(standardRaceButton)

        customRaceButton.title = "custom"
        customRaceButton.translatesAutoresizingMaskIntoConstraints = false
        customRaceButton.addTarget(self, action: #selector(showCustomOptions), for: .touchUpInside)
        topView.addSubview(customRaceButton)

        joinButton.title = "join"
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addTarget(self, action: #selector(joinCustomRace), for: .touchUpInside)
        topView.addSubview(joinButton)

        createButton.title = "create"
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createCustomRace), for: .touchUpInside)
        topView.addSubview(createButton)

        statsButton.title = "stats"
        statsButton.translatesAutoresizingMaskIntoConstraints = false
        statsButton.addTarget(self, action: #selector(statsButtonPressed), for: .touchUpInside)
        topView.addSubview(statsButton)

        if #available(iOS 13.4, *) {
            backButton.isPointerInteractionEnabled = true
            plusButton.isPointerInteractionEnabled = true
        }

        backButton.setImage(UIImage(named: "Back")!, for: .normal)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        topView.addSubview(backButton)

        let config = UIImage.SymbolConfiguration(weight: .semibold)
        plusButton.setImage(UIImage(systemName: "plus", withConfiguration: config)!,
                            for: .normal)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.addTarget(self, action: #selector(plusButtonPressed), for: .touchUpInside)
        topView.addSubview(plusButton)
    }

    /// Sets up the labels
    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(titleLabel)

        subtitleLabel.text = "Conquer the encyclopedia\nof everything."
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.clipsToBounds = true
        topView.addSubview(subtitleLabel)
    }

    // MARK: - Bottom View -

    /// Sets up the bottom views
    func setupBottomView() {
        let stackView = setupStatsStackView()
        bottomView.addSubview(movingPuzzleView)
        puzzleViewHeightConstraint = movingPuzzleView.heightAnchor.constraint(equalToConstant: 75)

        let constraints = [
            puzzleViewHeightConstraint!,
            movingPuzzleView.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
            movingPuzzleView.rightAnchor.constraint(equalTo: bottomView.rightAnchor),
            movingPuzzleView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),

            stackView.leftAnchor.constraint(equalTo: bottomView.leftAnchor, constant: 15),
            stackView.rightAnchor.constraint(equalTo: bottomView.rightAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: bottomView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: movingPuzzleView.topAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    /// Sets up the stack view that holds the menu tiles
    private func setupStatsStackView() -> UIStackView {
        let statsStackView = UIStackView()
        statsStackView.distribution = .fillEqually
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(statsStackView)

        let leftMenuTile = MenuTile(title: "WIKI POINTS")
        leftMenuTile.value = PlayerStatsManager.shared.multiplayerPoints
        statsStackView.addArrangedSubview(leftMenuTile)

        let middleMenuTile = MenuTile(title: "AVG PER RACE")
        middleMenuTile.isAverage = true
        middleMenuTile.value = PlayerUserDefaultsStat.multiplayerAverage.value()
        statsStackView.addArrangedSubview(middleMenuTile)

        let leftThinLine = WKRUIThinLineView()
        middleMenuTile.addSubview(leftThinLine)
        let rightThinLine = WKRUIThinLineView()
        middleMenuTile.addSubview(rightThinLine)

        let rightMenuTile = MenuTile(title: "RACES PLAYED")
        rightMenuTile.value = PlayerStatsManager.shared.multiplayerRaces
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

        leftMenuTile.addTarget(self, action: #selector(menuTilePressed), for: .touchUpInside)
        middleMenuTile.addTarget(self, action: #selector(menuTilePressed), for: .touchUpInside)
        rightMenuTile.addTarget(self, action: #selector(menuTilePressed), for: .touchUpInside)

        self.leftMenuTile = leftMenuTile
        self.middleMenuTile = middleMenuTile
        self.rightMenuTile = rightMenuTile

        PlayerStatsManager.shared.menuStatsUpdated = { points, races, average in
            DispatchQueue.main.async {
                self.leftMenuTile?.value = points
                self.middleMenuTile?.value = average
                self.rightMenuTile?.value = races
            }
        }

        if Defaults.isFastlaneSnapshotInstance {
            self.leftMenuTile?.value = 140
            self.middleMenuTile?.value = 140/72
            self.rightMenuTile?.value = 72
        }

        return statsStackView
    }

}
