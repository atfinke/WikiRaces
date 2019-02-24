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

    // MARK: - Top View

    /// Sets up the top view of the menu
    //swiftlint:disable:next function_body_length
    func setupTopView() {
        setupLabels()
        setupButtons()

        titleLabelConstraint = titleLabel.topAnchor.constraint(equalTo: topView.topAnchor, constant: 200)

        localRaceTypeButtonWidthConstraint = localRaceTypeButton.widthAnchor.constraint(equalToConstant: 0)
        localRaceTypeButtonHeightConstraint = localRaceTypeButton.heightAnchor.constraint(equalToConstant: 0)
        localRaceTypeButtonLeftConstraint = localRaceTypeButton.leftAnchor.constraint(equalTo: topView.leftAnchor,
                                                                                      constant: 0)
        globalRaceTypeButtonWidthConstraint = globalRaceTypeButton.widthAnchor.constraint(equalToConstant: 0)

        joinLocalRaceButtonWidthConstraint = joinLocalRaceButton.widthAnchor.constraint(equalToConstant: 0)
        joinLocalRaceButtonLeftConstraint = joinLocalRaceButton.leftAnchor.constraint(equalTo: topView.leftAnchor,
                                                                                      constant: 0)
        createLocalRaceButtonWidthConstraint = createLocalRaceButton.widthAnchor.constraint(equalToConstant: 0)
        localOptionsBackButtonWidth = localOptionsBackButton.widthAnchor.constraint(equalToConstant: 30)

        let constraints = [
            titleLabelConstraint!,

            titleLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            titleLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),

            subtitleLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            subtitleLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

            localRaceTypeButtonWidthConstraint!,
            localRaceTypeButtonHeightConstraint!,
            localRaceTypeButtonLeftConstraint!,
            globalRaceTypeButtonWidthConstraint!,

            joinLocalRaceButtonWidthConstraint!,
            joinLocalRaceButtonLeftConstraint!,
            createLocalRaceButtonWidthConstraint!,
            localOptionsBackButtonWidth!,

            localRaceTypeButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor,
                                                     constant: 40.0),
            joinLocalRaceButton.topAnchor.constraint(equalTo: localRaceTypeButton.topAnchor),

            globalRaceTypeButton.heightAnchor.constraint(equalTo: localRaceTypeButton.heightAnchor),
            joinLocalRaceButton.heightAnchor.constraint(equalTo: localRaceTypeButton.heightAnchor),
            createLocalRaceButton.heightAnchor.constraint(equalTo: localRaceTypeButton.heightAnchor),

            globalRaceTypeButton.leftAnchor.constraint(equalTo: localRaceTypeButton.leftAnchor),
            createLocalRaceButton.leftAnchor.constraint(equalTo: joinLocalRaceButton.leftAnchor),

            globalRaceTypeButton.topAnchor.constraint(equalTo: localRaceTypeButton.bottomAnchor,
                                                      constant: 20.0),
            createLocalRaceButton.topAnchor.constraint(equalTo: globalRaceTypeButton.topAnchor),

            localOptionsBackButton.leftAnchor.constraint(equalTo: joinLocalRaceButton.leftAnchor),
            localOptionsBackButton.topAnchor.constraint(equalTo: createLocalRaceButton.bottomAnchor,
                                                        constant: 20.0),

            localOptionsBackButton.heightAnchor.constraint(equalTo: localOptionsBackButton.widthAnchor,
                                                           multiplier: 1)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    /// Sets up the buttons
    private func setupButtons() {
        localRaceTypeButton.title = "local race"
        localRaceTypeButton.translatesAutoresizingMaskIntoConstraints = false
        localRaceTypeButton.addTarget(self, action: #selector(showLocalRaceOptions), for: .touchUpInside)
        topView.addSubview(localRaceTypeButton)

        globalRaceTypeButton.title = "global race"
        globalRaceTypeButton.translatesAutoresizingMaskIntoConstraints = false
        globalRaceTypeButton.addTarget(self, action: #selector(joinGlobalRace), for: .touchUpInside)
        topView.addSubview(globalRaceTypeButton)

        joinLocalRaceButton.title = "join race"
        joinLocalRaceButton.translatesAutoresizingMaskIntoConstraints = false
        joinLocalRaceButton.addTarget(self, action: #selector(joinLocalRace), for: .touchUpInside)
        topView.addSubview(joinLocalRaceButton)

        createLocalRaceButton.title = "create race"
        createLocalRaceButton.translatesAutoresizingMaskIntoConstraints = false
        createLocalRaceButton.addTarget(self, action: #selector(createLocalRace), for: .touchUpInside)
        topView.addSubview(createLocalRaceButton)

        localOptionsBackButton.setImage(UIImage(named: "Back")!, for: .normal)
        localOptionsBackButton.tintColor = .wkrTextColor
        localOptionsBackButton.translatesAutoresizingMaskIntoConstraints = false
        localOptionsBackButton.addTarget(self, action: #selector(localOptionsBackButtonPressed), for: .touchUpInside)
        topView.addSubview(localOptionsBackButton)

        localOptionsBackButton.layer.borderWidth = 1.7
        localOptionsBackButton.layer.borderColor = UIColor.wkrTextColor.cgColor
    }

    /// Sets up the labels
    private func setupLabels() {
        titleLabel.text = "WikiRaces"
        titleLabel.textColor = UIColor.wkrTextColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(titleLabel)

        #if DEBUG
        if !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            titleLabel.textColor = UIColor(red: 51.0 / 255.0,
                                           green: 102.0 / 255.0,
                                           blue: 204.0 / 255.0,
                                           alpha: 1.0)
        }
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
    func setupBottomView() {
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

}
