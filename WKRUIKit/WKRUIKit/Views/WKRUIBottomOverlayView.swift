//
//  WKRUIBottomOverlayView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIBottomOverlayView: UIVisualEffectView {

    // MARK: - Properties -

    private let thinLine = UIView()

    // MARK: - Initialization -

    public init() {
        super.init(effect: UIBlurEffect.wkrBlurEffect)
        translatesAutoresizingMaskIntoConstraints = false

        thinLine.alpha = 0.25
        contentView.addSubview(thinLine)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        thinLine.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 1)
        thinLine.backgroundColor = .wkrTextColor(for: traitCollection)
    }

}
