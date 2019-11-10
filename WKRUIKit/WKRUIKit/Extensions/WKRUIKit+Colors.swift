//
//  WKRUIKit+Color.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

extension UIColor {

    // MARK: - Properties

    public static func wkrBackgroundColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? .black : .white
    }

    public static func wkrTextColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? .white : #colorLiteral(red: 54.0/255.0, green: 54.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    }

    public static func wkrSubtitleTextColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? #colorLiteral(red: 210.0/255.0, green: 210.0/255.0, blue: 210.0/255.0, alpha: 1.0)  : #colorLiteral(red: 136.0/255.0, green: 136.0/255.0, blue: 136.0/255.0, alpha: 1.0)
    }

    public static func wkrMenuBottomViewColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? #colorLiteral(red: 0.05098039216, green: 0.05098039216, blue: 0.05098039216, alpha: 1) : #colorLiteral(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
    }

    public static func wkrMenuPuzzleViewColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? #colorLiteral(red: 0.1568627451, green: 0.1568627451, blue: 0.1568627451, alpha: 1) : #colorLiteral(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    }

    public static func wkrActivityIndicatorColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? #colorLiteral(red: 0.6470588235, green: 0.6470588235, blue: 0.6470588235, alpha: 1) : #colorLiteral(red: 84.0/255.0, green: 84.0/255.0, blue: 84.0/255.0, alpha: 1.0)
    }

    public static func wkrBarTextColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ?  .white : .black
    }

    public static func wkrVoteCountTextColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1) : .lightGray
    }

    public static func wkrVoteCountSelectedTextColor(for traitCollection: UITraitCollection) -> UIColor {
        return WKRUIStyle.isDark(traitCollection) ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) : .darkGray
    }

}
