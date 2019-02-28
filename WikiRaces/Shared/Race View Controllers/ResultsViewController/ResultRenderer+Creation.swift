//
//  ResultRenderer+Creation.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/4/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

//swiftlint:disable function_body_length cyclomatic_complexity
extension ResultRenderer {

    // MARK: - Section Creation

    func createHeaderView(title: String) -> UIView {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.text = title.uppercased()
        label.textAlignment = .left
        label.textColor = tintColor
        label.numberOfLines = 0
        headerView.addSubview(label)

        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = tintColor
        lineView.layer.cornerRadius = 2
        headerView.addSubview(lineView)

        let constraints = [
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 25),
            label.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            label.rightAnchor.constraint(equalTo: headerView.rightAnchor),

            lineView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
            lineView.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            lineView.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 4),

            headerView.bottomAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)

        return headerView
    }

    func createBannerView() -> UIView {
        let bannerView = UIView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        let innerBannerView = UIView()
        innerBannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.addSubview(innerBannerView)

        let imageView = UIImageView(image: UIImage(named: "PreviewIcon")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        innerBannerView.addSubview(imageView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        titleLabel.text = "WikiRaces 3"
        titleLabel.textColor = tintColor
        innerBannerView.addSubview(titleLabel)

        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        detailLabel.text = "RACE RESULTS"
        detailLabel.textColor = .darkGray
        innerBannerView.addSubview(detailLabel)

        let constraints = [
            innerBannerView.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 10),
            innerBannerView.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor),
            innerBannerView.centerXAnchor.constraint(equalTo: bannerView.centerXAnchor, constant: -10),
            innerBannerView.widthAnchor.constraint(equalToConstant: 250),

            imageView.leftAnchor.constraint(equalTo: innerBannerView.leftAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.heightAnchor.constraint(equalTo: innerBannerView.heightAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 10),
            titleLabel.rightAnchor.constraint(equalTo: innerBannerView.rightAnchor),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        return bannerView
    }

    func createRankingView(for results: WKRResultsInfo, localPlayer: WKRPlayer) -> UIView {
        let rankingView = UIView()
        rankingView.translatesAutoresizingMaskIntoConstraints = false

        let innerRankingsView = UIView()
        innerRankingsView.translatesAutoresizingMaskIntoConstraints = false
        rankingView.addSubview(innerRankingsView)

        let entrySpacing = CGFloat(15)
        var anchorView: UIView = innerRankingsView

        var constraints = [
            innerRankingsView.topAnchor.constraint(equalTo: rankingView.topAnchor),
            innerRankingsView.bottomAnchor.constraint(equalTo: rankingView.bottomAnchor),
            innerRankingsView.centerXAnchor.constraint(equalTo: rankingView.centerXAnchor),
            innerRankingsView.widthAnchor.constraint(equalTo: rankingView.widthAnchor)
        ]

        var lastDetailLabel: UILabel?
        for index in 0..<results.playerCount {
            let player = results.raceRankingsPlayer(at: index)

            let nameLabel = UILabel()
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.numberOfLines = 0

            var placeString = (index + 1).description + "th"
            if index == 0 {
                placeString = "1st"
            } else if index == 1 {
                placeString = "2nd"
            } else if index == 2 {
                placeString = "3rd"
            }
            placeString += ": "
            let nameString = placeString + player.name

            let weight: UIFont.Weight = player == localPlayer ? .medium : .medium
            let nameFont = UIFont.systemFont(ofSize: 18, weight: weight)

            let style = NSMutableParagraphStyle()
            style.headIndent = 35

            let attributes: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .paragraphStyle: style
            ]
            let placeFont = UIFont(name: "Menlo-Bold", size: 14)!

            let mutableString = NSMutableAttributedString(string: nameString,
                                                          attributes: attributes)
            mutableString.addAttribute(.font,
                                       value: placeFont,
                                       range: NSRange(location: 0, length: placeString.count - 2))
            mutableString.addAttribute(.foregroundColor,
                                       value: UIColor.darkGray,
                                       range: NSRange(location: 0, length: placeString.count))
            nameLabel.attributedText = mutableString
            innerRankingsView.addSubview(nameLabel)

            let detailLabel = UILabel()
            detailLabel.translatesAutoresizingMaskIntoConstraints = false

            detailLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            if player.state == .foundPage {
                detailLabel.font = UIFont(monospaceSize: 18, weight: .semibold)
            }

            detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            detailLabel.textAlignment = .right
            detailLabel.textColor = UIColor.darkGray

            var detailString = ""
            switch player.state {
            case .foundPage:
                if let history = player.raceHistory,
                    let duration = WKRDurationFormatter.resultsString(for: history.duration) {
                    detailString = duration
                }
            case .forcedEnd:
                detailString = "DNF"
            case .forfeited:
                detailString = "Forfeited"
            case .quit:
                detailString = "Quit"
            case .racing, .connecting, .readyForNextRound, .voting:
                break
            }

            detailLabel.text = detailString.uppercased()
            innerRankingsView.addSubview(detailLabel)

            let anchor = index == 0 ? anchorView.topAnchor : anchorView.bottomAnchor
            constraints.append(contentsOf: [
                nameLabel.topAnchor.constraint(equalTo: anchor, constant: entrySpacing),
                nameLabel.leftAnchor.constraint(equalTo: innerRankingsView.leftAnchor),
                nameLabel.rightAnchor.constraint(equalTo: detailLabel.leftAnchor, constant: -10),

                detailLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
                detailLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),
                detailLabel.rightAnchor.constraint(equalTo: innerRankingsView.rightAnchor)
                ])

            if let label = lastDetailLabel {
                constraints.append(detailLabel.leftAnchor.constraint(equalTo: label.leftAnchor))
            }
            lastDetailLabel = detailLabel
            anchorView = nameLabel
        }

        constraints.append(rankingView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor))
        NSLayoutConstraint.activate(constraints)

        return rankingView
    }

    func createHistoryView(for localPlayer: WKRPlayer) -> UIView {
        let historyView = UIView()
        historyView.translatesAutoresizingMaskIntoConstraints = false

        guard let entries = localPlayer.raceHistory?.entries else { return historyView }
        var constraints = [NSLayoutConstraint]()
        let entrySpacing = CGFloat(15)
        var anchorView: UIView = historyView
        for (index, entry) in entries.enumerated() {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            let num = index + 1
            let indexString = num.description + ". "
            let fullString = indexString + (entry.page.title ?? "")

            let entryFont = UIFont.systemFont(ofSize: 18, weight: .medium)
            let style = NSMutableParagraphStyle()
            style.headIndent = 18
            if num >= 100 {
                style.headIndent = 34
            } else if num >= 10 {
                style.headIndent = 26
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .font: entryFont,
                .paragraphStyle: style
            ]

            let indexFont = UIFont(name: "Menlo-Bold", size: 14)!

            let mutableString = NSMutableAttributedString(string: fullString,
                                                          attributes: attributes)
            mutableString.addAttribute(.font,
                                       value: indexFont,
                                       range: NSRange(location: 0, length: indexString.count - 2))
            mutableString.addAttribute(.foregroundColor,
                                       value: UIColor.darkGray,
                                       range: NSRange(location: 0, length: indexString.count))
            label.attributedText = mutableString

            historyView.addSubview(label)

            let anchor = index == 0 ? anchorView.topAnchor : anchorView.bottomAnchor
            constraints.append(contentsOf: [
                label.topAnchor.constraint(equalTo: anchor, constant: entrySpacing),
                label.leftAnchor.constraint(equalTo: historyView.leftAnchor),
                label.rightAnchor.constraint(equalTo: historyView.rightAnchor)
                ])
            anchorView = label
        }
        constraints.append(historyView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor))
        NSLayoutConstraint.activate(constraints)

        return historyView
    }
}
//swiftlint:enable function_body_length type_body_length cyclomatic_complexity
