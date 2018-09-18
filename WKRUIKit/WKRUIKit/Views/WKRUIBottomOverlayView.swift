//
//  WKRUIBottomOverlayView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIBottomOverlayView: UIVisualEffectView {

    // MARK: - Initialization

    public init() {
        super.init(effect: UIBlurEffect.wkrBlurEffect)
        translatesAutoresizingMaskIntoConstraints = false

        let thinLine = UIView()
        thinLine.alpha = 0.25
        thinLine.backgroundColor = UIColor.wkrTextColor
        thinLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thinLine)

        let constraints = [
            thinLine.topAnchor.constraint(equalTo: topAnchor),
            thinLine.heightAnchor.constraint(equalToConstant: 1.0),
            thinLine.leftAnchor.constraint(equalTo: leftAnchor),
            thinLine.rightAnchor.constraint(equalTo: rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
