//
//  HistoryTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

final internal class HistoryTableViewCell: UITableViewCell {

    // MARK: - Properties -

    let pageLabel = UILabel()
    let detailLabel = UILabel()

    private let linkHereLabel = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView(style: .medium)
    private var linkLabelTopConstraint: NSLayoutConstraint?

    var isShowingActivityIndicatorView: Bool = false {
        didSet {
            detailLabel.isHidden = isShowingActivityIndicatorView
            if isShowingActivityIndicatorView {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }

    var isLinkHere: Bool = true {
        didSet {
            linkHereLabel.text = isLinkHere ? "Link Here" : nil
            linkLabelTopConstraint?.constant = isLinkHere ? 5 : 0
        }
    }

    static let reuseIdentifier = "reuseIdentifier"

    // MARK: - Initialization -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        pageLabel.textAlignment = .left
        pageLabel.font = UIFont.systemRoundedFont(ofSize: 17, weight: .regular)
        pageLabel.numberOfLines = 0
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pageLabel)

        linkHereLabel.text = "Link Here"
        linkHereLabel.textColor = .lightGray
        linkHereLabel.textAlignment = .left
        linkHereLabel.font = UIFont.systemRoundedFont(ofSize: 16, weight: .medium)
        linkHereLabel.numberOfLines = 1
        linkHereLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(linkHereLabel)

        detailLabel.textAlignment = .right
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
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        let textColor = UIColor.wkrTextColor(for: traitCollection)
        tintColor = textColor
        pageLabel.textColor = textColor
        detailLabel.textColor = textColor
        activityIndicatorView.color = .wkrActivityIndicatorColor(for: traitCollection)
    }

    // MARK: - Constraints -

    private func setupConstraints() {
        let leftMarginConstraint = NSLayoutConstraint(item: pageLabel,
                                                      attribute: .left,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .leftMargin,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

        let rightMarginConstraint = NSLayoutConstraint(item: detailLabel,
                                                       attribute: .right,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .rightMargin,
                                                       multiplier: 1.0,
                                                       constant: 0.0)

        let linkLabelTopConstraint = linkHereLabel.topAnchor.constraint(equalTo: pageLabel.bottomAnchor,
                                                                        constant: 5)
        self.linkLabelTopConstraint = linkLabelTopConstraint

        let constraints = [
            leftMarginConstraint,
            pageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            pageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
            pageLabel.rightAnchor.constraint(lessThanOrEqualTo: detailLabel.leftAnchor, constant: -15),
            pageLabel.rightAnchor.constraint(lessThanOrEqualTo: activityIndicatorView.leftAnchor, constant: -15),

            linkLabelTopConstraint,
            linkHereLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            linkHereLabel.leftAnchor.constraint(equalTo: pageLabel.leftAnchor),
            linkHereLabel.rightAnchor.constraint(equalTo: pageLabel.rightAnchor),

            rightMarginConstraint,
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            activityIndicatorView.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
            activityIndicatorView.rightAnchor.constraint(equalTo: detailLabel.rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
