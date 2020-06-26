//
//  ActivityButton.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

class ActivityButton: UIButton {

    // MARK: - Types -

    enum DisplayState {
        case label, activity
    }

    // MARK: - Properties -

    var displayState = DisplayState.label {
        didSet {
            setNeedsLayout()
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
    }

    let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemRoundedFont(ofSize: 14, weight: .medium)
        return label
    }()

    let activityIndicatorView: UIActivityIndicatorView = {
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }()

    // MARK: - Initalization -

    init() {
        super.init(frame: .zero)
        addSubview(label)
        addSubview(activityIndicatorView)

        label.isUserInteractionEnabled = false
        activityIndicatorView.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func layoutSubviews() {
        super.layoutSubviews()

        label.frame = bounds
        activityIndicatorView.center = label.center
        activityIndicatorView.color = .wkrActivityIndicatorColor(for: traitCollection)

        switch displayState {
        case .label:
            label.alpha = 1.0
            activityIndicatorView.alpha = 0.0
        case .activity:
            label.alpha = 0.0
            activityIndicatorView.alpha = 1.0
        }
    }
}
