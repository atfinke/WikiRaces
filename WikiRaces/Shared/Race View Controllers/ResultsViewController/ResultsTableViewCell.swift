//
//  ResultsTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

final internal class ResultsTableViewCell: PointerInteractionTableViewCell {

    // MARK: - Properties -

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
                if #available(iOS 13.0, *) {
                    rightMarginConstraint?.constant = -30
                } else {
                    rightMarginConstraint?.constant = -20
                }
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

    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    private var isPlayerCreator = false

    // MARK: - Initialization -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        playerLabel.textAlignment = .left
        playerLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        playerLabel.numberOfLines = 0
        playerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playerLabel)

        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        detailLabel.textAlignment = .right
        detailLabel.textColor = .lightGray
        detailLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

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

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        let textColor = UIColor.wkrTextColor(for: traitCollection)
        tintColor = textColor
        if !isPlayerCreator {
            playerLabel.textColor =  textColor
        }
        subtitleLabel.textColor = textColor
        activityIndicatorView.color = .wkrActivityIndicatorColor(for: traitCollection)
    }

    // MARK: - Constraints -

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
            constraints.append(subtitleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15))
        } else {
            constraints.append(subtitleLabel.heightAnchor.constraint(equalToConstant: 0))
        }

        NSLayoutConstraint.activate(constraints)

    }

    // MARK: - Updating -

    private func update(playerName: NSAttributedString,
                        detail: String,
                        subtitle: NSAttributedString,
                        animated: Bool) {
        if animated {
            UIView.transition(with: playerLabel,
                              duration: WKRAnimationDurationConstants.resultsCellLabelsFade,
                              options: .transitionCrossDissolve,
                              animations: { [weak self] in
                                self?.playerLabel.attributedText = playerName
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
            playerLabel.attributedText = playerName
            detailLabel.text = detail
            subtitleLabel.attributedText = subtitle
        }
    }

    func updateResults(for player: WKRPlayer, animated: Bool) {
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
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
            ]
            pageTitleAttributedString.addAttributes(attributes, range: range)
        }

        var detailString = player.state.text
        if player.state == .foundPage, let duration = WKRDurationFormatter.string(for: history.duration) {
            detailString = duration
        } else if player.state == .racing {
            detailString = ""
        } else if player.state == .forcedEnd || player.state == .forfeited {
            detailString = "DNF"
        }
        isShowingActivityIndicatorView = player.state == .racing

        update(playerName: playerNameAttributedString(for: player),
               detail: detailString,
               subtitle: pageTitleAttributedString,
               animated: animated)
    }

    func updateStandings(for sessionResults: WKRResultsInfo.WKRProfileSessionResults) {
        isShowingActivityIndicatorView = false
        isShowingCheckmark = false

        let detailString: String
        if sessionResults.points == 1 {
            detailString = sessionResults.points.description + " PT"
        } else {
            detailString = sessionResults.points.description + " PTS"
        }

        var subtitleString: String
        if sessionResults.ranking == 1 {
            subtitleString = "1st Place"
        } else if  sessionResults.ranking == 2 {
            subtitleString = "2nd Place"
        } else if  sessionResults.ranking == 3 {
            subtitleString = "3rd Place"
        } else {
            subtitleString = "\(sessionResults.ranking)th Place"
        }
        subtitleString += sessionResults.isTied ? " (Tied)" : ""

        update(playerName: NSAttributedString(string: sessionResults.profile.name),
               detail: detailString,
               subtitle: NSAttributedString(string: subtitleString),
               animated: false)
    }

    // MARK: - Other -

    func playerNameAttributedString(for player: WKRPlayer) -> NSAttributedString {
        if player.isCreator {
            self.isPlayerCreator = true
            let name = player.name
            let nameAttributedString = NSMutableAttributedString(string: name, attributes: nil)
            let range = NSRange(location: 0, length: name.count)

            let font = UIFont.systemRoundedFont(ofSize: 20, weight: .semibold) ??
                UIFont.systemFont(ofSize: 18, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(displayP3Red: 69.0/255.0,
                                          green: 145.0/255.0,
                                          blue: 208.0/255.0,
                                          alpha: 1.0),
                .font: font
            ]
            nameAttributedString.addAttributes(attributes, range: range)
            return nameAttributedString
        }
        return NSAttributedString(string: player.name, attributes: nil)
    }

}
