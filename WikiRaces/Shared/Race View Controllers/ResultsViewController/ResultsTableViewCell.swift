//
//  ResultsTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

internal class ResultsTableViewCell: UITableViewCell {

    // MARK: - Properties

    private let playerLabel = UILabel()
    private let detailLabel = UILabel()
    private let subtitleLabel = UILabel()

    private var rightMarginConstraint: NSLayoutConstraint?

    var isShowingActivityIndicatorView: Bool = false {
        didSet {
            if isShowingActivityIndicatorView {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }
    var isShowingCheckmark: Bool = false {
        didSet {
            guard isShowingCheckmark != oldValue else { return }
            if isShowingCheckmark {
                rightMarginConstraint?.constant = -20
            } else {
                rightMarginConstraint?.constant = 0
            }

            setNeedsLayout()
            if isShowingCheckmark {
                UIView.animate(withDuration: WKRAnimationDurationConstants.resultsCellLabelsFade, animations: {
                    self.layoutIfNeeded()
                }, completion: { _ in
                    self.accessoryType = self.isShowingCheckmark ? .checkmark : .none
                })
            } else {
                layoutIfNeeded()
                accessoryType = isShowingCheckmark ? .checkmark : .none
            }
        }
    }

    private let activityIndicatorView = UIActivityIndicatorView(style: .gray)

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        tintColor = UIColor.wkrTextColor
        selectionStyle = .none
        backgroundColor = UIColor.clear

        playerLabel.textColor = UIColor.wkrTextColor
        playerLabel.textAlignment = .left
        playerLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        playerLabel.numberOfLines = 0
        playerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerLabel)

        subtitleLabel.textColor = UIColor.wkrTextColor
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        detailLabel.textAlignment = .right
        detailLabel.textColor = UIColor.lightGray
        detailLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

        activityIndicatorView.color = UIColor.wkrActivityIndicatorColor
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
        activityIndicatorView.setContentCompressionResistancePriority(.required, for: .horizontal)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        let leftMarginConstraint = NSLayoutConstraint(item: playerLabel,
                                                      attribute: .left,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .leftMargin,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

        rightMarginConstraint = NSLayoutConstraint(item: detailLabel,
                                                   attribute: .right,
                                                   relatedBy: .equal,
                                                   toItem: self,
                                                   attribute: .rightMargin,
                                                   multiplier: 1.0,
                                                   constant: 0.0)

        var constraints = [
            leftMarginConstraint,
            playerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            playerLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
            playerLabel.rightAnchor.constraint(lessThanOrEqualTo: detailLabel.leftAnchor, constant: -10),
            playerLabel.rightAnchor.constraint(lessThanOrEqualTo: activityIndicatorView.leftAnchor, constant: -10),

            subtitleLabel.topAnchor.constraint(equalTo: playerLabel.bottomAnchor, constant: 5),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            subtitleLabel.leftAnchor.constraint(equalTo: playerLabel.leftAnchor),
            subtitleLabel.rightAnchor.constraint(equalTo: playerLabel.rightAnchor),

            rightMarginConstraint!,
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            activityIndicatorView.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
            activityIndicatorView.rightAnchor.constraint(equalTo: detailLabel.rightAnchor)
        ]

        if UIScreen.main.bounds.width > 340 {
            constraints.append(subtitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15)
            )
        } else {
            constraints.append(subtitleLabel.heightAnchor.constraint(equalToConstant: 0)
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updating

    func update(playerName: String, detail: String, subtitle: NSAttributedString, animated: Bool) {
        if animated {
            UIView.transition(with: playerLabel,
                              duration: WKRAnimationDurationConstants.resultsCellLabelsFade,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.playerLabel.text = playerName
                }, completion: nil)
            UIView.transition(with: detailLabel,
                              duration: WKRAnimationDurationConstants.resultsCellLabelsFade,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.detailLabel.text = detail
                }, completion: nil)
            UIView.transition(with: subtitleLabel,
                              duration: WKRAnimationDurationConstants.resultsCellLabelsFade,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.subtitleLabel.attributedText = subtitle
                }, completion: nil)
        } else {
            playerLabel.text = playerName
            detailLabel.text = detail
            subtitleLabel.attributedText = subtitle
        }
    }

    func update(for player: WKRPlayer, animated: Bool) {
        guard let history = player.raceHistory, let entry = history.entries.last else {
            playerLabel.text = player.name
            subtitleLabel.text = "-"
            detailLabel.text = "-"
            if player.state == .forcedEnd {
                detailLabel.text = "DNF"
            } else if player.state == .quit {
                detailLabel.text = "Quit"
            }
            return
        }

        let pageTitle = entry.page.title ?? "-"
        var pageTitleAttributedString = NSMutableAttributedString(string: pageTitle, attributes: nil)
        if entry.linkHere {
            let detail = " Link Here"
            pageTitleAttributedString = NSMutableAttributedString(string: pageTitle + detail, attributes: nil)

            let range = NSRange(location: pageTitle.count, length: detail.count)
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray,
                .font: UIFont.systemFont(ofSize: 15)
            ]
            pageTitleAttributedString.addAttributes(attributes, range: range)
        }

        var detailString = player.state.text
        if player.state == .foundPage, let duration = DurationFormatter.string(for: history.duration) {
            detailString = duration
        } else if player.state == .racing {
            detailString = ""
        } else if player.state == .forcedEnd || player.state == .forfeited {
            detailString = "DNF"
        }
        isShowingActivityIndicatorView = player.state == .racing

        update(playerName: player.name,
               detail: detailString,
               subtitle: pageTitleAttributedString,
               animated: animated)
    }

}
