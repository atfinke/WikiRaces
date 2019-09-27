//
//  WKRUIThinLineView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIThinLineView: UIView {

    // MARK: - Initialization -

    public init() {
        super.init(frame: .zero)
        alpha = 0.25
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 1
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .wkrTextColor(for: traitCollection)
    }

}
