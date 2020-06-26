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

        let fontDescriptor = UIFont.systemRoundedFont(ofSize: monospaceSize, weight: weight).fontDescriptor.addingAttributes(
            [.featureSettings: features]
        )

        self.init(descriptor: fontDescriptor, size: monospaceSize)
    }

    static public func systemRoundedFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
            fatalError()
        }
        return UIFont(descriptor: descriptor, size: size)
    }

}

extension NSAttributedString {

    public convenience init(string: String,
                            spacing: Double,
                            font: UIFont = UIFont.systemFont(ofSize: 16.0)) {

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .kern: spacing
        ]
        self.init(string: string, attributes: attributes)
    }

}
