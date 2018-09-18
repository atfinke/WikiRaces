//
//  WKRUILabel.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUILabel: UILabel {

    // MARK: - Properties

    private let spacing: Double
    public override var text: String? {
        didSet {
            if let text = text?.uppercased() {
                super.attributedText = NSAttributedString(string: text, spacing: spacing)
            } else {
                super.attributedText = nil
            }
        }
    }

    // MARK: - Initialization

    public init(spacing: Double = 2.0) {
        self.spacing = spacing
        super.init(frame: .zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
