//
//  WKRUIKit+Fonts.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

extension UIFont {

    public convenience init(monospaceSize: CGFloat, weight: UIFont.Weight = .regular) {
        let features: [[UIFontDescriptor.FeatureKey: Int]] = [
            [
                .featureIdentifier: kNumberSpacingType,
                .typeIdentifier: kMonospacedNumbersSelector
            ]
        ]

        let fontDescriptor = UIFont.systemFont(ofSize: monospaceSize, weight: weight).fontDescriptor.addingAttributes(
            [.featureSettings: features]
        )

        self.init(descriptor: fontDescriptor, size: monospaceSize)
    }

}

extension NSAttributedString {

    public convenience init(string: String,
                            spacing: Double,
                            font: UIFont = UIFont.systemFont(ofSize: 16.0),
                            textColor: UIColor = UIColor.wkrTextColor) {

        let attributes: [NSAttributedStringKey: Any] = [
            .font: font,
            .kern: spacing,
            .foregroundColor: textColor
        ]
        self.init(string: string, attributes: attributes)
    }

}
