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

    func setupInterface() {
        UIApplication.shared.keyWindow?.backgroundColor = UIColor.white

        topView.alpha = 0.0
        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)

        bottomView.backgroundColor = UIColor(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomView)
        bottomViewAnchorConstraint = bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 250)

        setupButton()
        setupPuzzleView()
        setupStackView()

        let labels = setupLabels()

        let constraints = [
            topView.topAnchor.constraint(equalTo: view.topAnchor),
            topView.bottomAnchor.constraint(equalTo: bottomView.topAnchor),
            topView.leftAnchor.constraint(equalTo: view.leftAnchor),
            topView.rightAnchor.constraint(equalTo: view.rightAnchor),

            joinButton.bottomAnchor.constraint(equalTo: labels.descriptionLabel.bottomAnchor, constant: 90.0),
            createButton.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 20.0),

            joinButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            joinButton.widthAnchor.constraint(equalToConstant: 175),
            joinButton.heightAnchor.constraint(equalToConstant: 40),

            createButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            createButton.widthAnchor.constraint(equalToConstant: 205),
            createButton.heightAnchor.constraint(equalToConstant: 40),

            bottomView.leftAnchor.constraint(equalTo: view.leftAnchor),
            bottomView.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 250),
            bottomViewAnchorConstraint!
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupButton() {
        joinButton.title = "Join race"
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addTarget(self, action: #selector(advertise(_:)), for: .touchUpInside)
        topView.addSubview(joinButton)

        createButton.title = "Create race"
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(browse(_:)), for: .touchUpInside)
        topView.addSubview(createButton)

    }

    func setupLabels() -> (titleLabel: UILabel, descriptionLabel: UILabel) {
        let label = UILabel()
        label.text = "WikiRaces"
        label.textColor = UIColor.wkrTextColor
        label.font = titleLabelFont()
        label.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(label)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "Conquer the encyclopedia\nof everything."
        descriptionLabel.numberOfLines = 2
        descriptionLabel.textColor = UIColor.wkrTextColor
        descriptionLabel.font = descriptionLabelFont()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.clipsToBounds = true
        topView.addSubview(descriptionLabel)

        let contraints = [
            label.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            label.widthAnchor.constraint(equalTo: topView.widthAnchor),
            label.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: 0),

            descriptionLabel.leftAnchor.constraint(equalTo: topView.leftAnchor, constant: 30),
            descriptionLabel.widthAnchor.constraint(equalTo: topView.widthAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: topView.bottomAnchor, constant: -280)
        ]
        NSLayoutConstraint.activate(contraints)

        return (label, descriptionLabel)
    }

    func setupStackView() {
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
            rightThinLine.widthAnchor.constraint(equalToConstant: 2),

            statsStackView.leftAnchor.constraint(equalTo: bottomView.leftAnchor, constant: 15),
            statsStackView.rightAnchor.constraint(equalTo: bottomView.rightAnchor, constant: -15),
            statsStackView.topAnchor.constraint(equalTo: bottomView.topAnchor),
            statsStackView.heightAnchor.constraint(equalToConstant: 160)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupPuzzleView() {
        let puzzleBackgroundView = UIView()

        let color = UIColor(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
        puzzleBackgroundView.backgroundColor = color
        puzzleBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(puzzleBackgroundView)

        puzzleView.backgroundColor = UIColor(patternImage: UIImage(named: "puzzle")!)
        puzzleView.translatesAutoresizingMaskIntoConstraints = false
        puzzleBackgroundView.addSubview(puzzleView)

        let constraints = [
            puzzleBackgroundView.leftAnchor.constraint(equalTo: bottomView.leftAnchor),
            puzzleBackgroundView.rightAnchor.constraint(equalTo: bottomView.rightAnchor),
            puzzleBackgroundView.bottomAnchor.constraint(equalTo: bottomView.bottomAnchor),
            puzzleBackgroundView.heightAnchor.constraint(equalToConstant: 75),

            puzzleView.leftAnchor.constraint(equalTo: puzzleBackgroundView.leftAnchor),
            puzzleView.rightAnchor.constraint(equalTo: puzzleBackgroundView.rightAnchor),
            puzzleView.centerYAnchor.constraint(equalTo: puzzleBackgroundView.centerYAnchor),
            puzzleView.heightAnchor.constraint(equalToConstant: 30)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
