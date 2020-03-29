//
//  WKRUIProgressView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

final public class WKRUIProgressView: UIProgressView {

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)

        progressViewStyle = .bar
        progressTintColor = .white

        layer.borderWidth = 0.1

        isHidden = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = UIColor.wkrTextColor(for: traitCollection).cgColor
    }

    // MARK: - State

    func show() {
        setProgress(0.0, animated: false)
        isHidden = false
    }

    func hide() {
        let delay    = WKRUIKitConstants.progessViewAnimateOutDelay
        let duration = WKRUIKitConstants.progessViewAnimateOutDuration

        UIView.animate(withDuration: duration, delay: delay, options: [], animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.isHidden = true
            self.alpha = 1.0
        })
    }

}
