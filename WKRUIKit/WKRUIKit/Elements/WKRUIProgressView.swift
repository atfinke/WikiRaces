//
//  WKRUIProgressView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIProgressView: UIProgressView {

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)

        progressViewStyle = .bar
        progressTintColor = UIColor.white

        layer.borderWidth = 0.1
        layer.borderColor = UIColor.wkrTextColor.cgColor

        isHidden = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - State

    func show() {
        setProgress(0.0, animated: false)
        isHidden = false
    }

    func hide() {
        let delay    = WKRUIConstants.progessViewAnimateOutDelay
        let duration = WKRUIConstants.progessViewAnimateOutDuration

        UIView.animate(withDuration: duration, delay: delay, options: [], animations: {
            self.alpha = 0.0
        }, completion: { _ in
            self.isHidden = true
            self.alpha = 1.0
        })
    }

}
