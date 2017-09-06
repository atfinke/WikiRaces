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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print(size.height)
        bottomViewAnchorConstraint.constant = 0
        if size.height > 1200 {
            titleLabelConstraint.constant = 400
        } else if size.height > 1000 {
            titleLabelConstraint.constant = 250
        } else if size.height > 800 {
            titleLabelConstraint.constant = 120
        } else if size.height > 730 {
            titleLabelConstraint.constant = 100
        } else if size.height > 650 {
            titleLabelConstraint.constant = 90
        } else if size.height > 0 {
            titleLabelConstraint.constant = 80
            bottomViewAnchorConstraint.constant = 75
        }

        let buttonStyle: WKRUIButtonStyle
        let buttonWidth: CGFloat
        let buttonHeight: CGFloat
        if size.width < 370 {
            buttonStyle = .normal
            buttonWidth = 175
            buttonHeight = 40
        } else {
            buttonStyle = .large
            buttonWidth = 195
            buttonHeight = 50
        }

        titleLabel.font = titleLabelFont(for: size.width)
        subtitleLabel.font = descriptionLabelFont(for: size.width)

        createButton.style = buttonStyle
        joinButton.style = buttonStyle

        createButtonWidthConstraint.constant = buttonWidth + 30
        createButtonHeightConstraint.constant = buttonHeight

        joinButtonWidthConstraint.constant = buttonWidth
        joinButtonHeightConstraint.constant = buttonHeight

        coordinator.animate(alongsideTransition: { _ in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func setupInterface() {
        UIApplication.shared.keyWindow?.backgroundColor = UIColor.white

        topView.alpha = 0.0
        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)

        bottomView.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomView)

        topViewLeftConstraint = topView.leftAnchor.constraint(equalTo: view.leftAnchor)
        bottomViewAnchorConstraint = bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 250)

        setupTopView()
        setupBottomView()


        let constraints = [
            topView.topAnchor.constraint(equalTo: view.topAnchor),
            topView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            topView.rightAnchor.constraint(equalTo: view.rightAnchor),

            bottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
            bottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 250),

            topViewLeftConstraint!,
            bottomViewAnchorConstraint!
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Top View

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
            joinButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),

            createButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            createButton.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 20.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupButtons() {
        joinButton.title = "Join race"
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addTarget(self, action: #selector(advertise(_:)), for: .touchUpInside)
        topView.addSubview(joinButton)

        createButton.title = "Create race"
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(browse(_:)), for: .touchUpInside)
        topView.addSubview(createButton)
    }

    private func setupLabels() {
        titleLabel.text = "WikiRaces"
        titleLabel.textColor = UIColor.wkrTextColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(titleLabel)

        subtitleLabel.text = "Conquer the encyclopedia\nof everything."
        subtitleLabel.numberOfLines = 2
        subtitleLabel.textColor = UIColor.wkrTextColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.clipsToBounds = true
        topView.addSubview(subtitleLabel)
    }

    // MARK: - Bottom View

    private func setupBottomView() {
        let stackView = setupStatsStackView()
        let puzzleView = setupPuzzleView()

        let constraints = [
            puzzleView.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
            puzzleView.rightAnchor.constraint(equalTo: bottomView.rightAnchor),
            puzzleView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            puzzleView.heightAnchor.constraint(equalToConstant: 75),

            stackView.leftAnchor.constraint(equalTo: bottomView.leftAnchor, constant: 15),
            stackView.rightAnchor.constraint(equalTo: bottomView.rightAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: bottomView.topAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 160)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupStatsStackView() -> UIStackView {
        let statsStackView = UIStackView()
        statsStackView.distribution = .fillEqually
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(statsStackView)

        let leftMenuTitle = MenuTile(title: "WIKI POINTS", value: 86)
        statsStackView.addArrangedSubview(leftMenuTitle)

        let middleMenuTitle = MenuTile(title: "AVG PER RACE", value: 0.6)
        statsStackView.addArrangedSubview(middleMenuTitle)
        let leftThinLine = WKRUIThinLineView()
        middleMenuTitle.addSubview(leftThinLine)
        let rightThinLine = WKRUIThinLineView()
        middleMenuTitle.addSubview(rightThinLine)

        let rightMenuTitle = MenuTile(title: "RACES PLAYED", value: 123)
        statsStackView.addArrangedSubview(rightMenuTitle)

        let constraints = [
            leftThinLine.leftAnchor.constraint(equalTo: middleMenuTitle.leftAnchor),
            leftThinLine.topAnchor.constraint(equalTo: middleMenuTitle.topAnchor, constant: 30),
            leftThinLine.bottomAnchor.constraint(equalTo: middleMenuTitle.bottomAnchor, constant: -25),
            leftThinLine.widthAnchor.constraint(equalToConstant: 2),

            rightThinLine.rightAnchor.constraint(equalTo: middleMenuTitle.rightAnchor),
            rightThinLine.topAnchor.constraint(equalTo: middleMenuTitle.topAnchor, constant: 30),
            rightThinLine.bottomAnchor.constraint(equalTo: middleMenuTitle.bottomAnchor, constant: -25),
            rightThinLine.widthAnchor.constraint(equalToConstant: 2)
        ]
        NSLayoutConstraint.activate(constraints)

        return statsStackView
    }

    private func setupPuzzleView() -> UIView {
        let puzzleBackgroundView = UIView()

        let color = UIColor(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        puzzleBackgroundView.backgroundColor = color
        puzzleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(puzzleBackgroundView)

        puzzleView.backgroundColor = UIColor(patternImage: UIImage(named: "puzzle")!)
        puzzleView.translatesAutoresizingMaskIntoConstraints = false
        puzzleBackgroundView.addSubview(puzzleView)

        let constraints = [
            puzzleView.leftAnchor.constraint(equalTo: puzzleBackgroundView.leftAnchor),
            puzzleView.rightAnchor.constraint(equalTo: puzzleBackgroundView.rightAnchor),
            puzzleView.centerYAnchor.constraint(equalTo: puzzleBackgroundView.centerYAnchor),
            puzzleView.heightAnchor.constraint(equalToConstant: 30)
        ]
        NSLayoutConstraint.activate(constraints)

        return puzzleBackgroundView
    }

}
