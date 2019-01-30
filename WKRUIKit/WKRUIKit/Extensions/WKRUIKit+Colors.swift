//
//  WKRUIKit+Color.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIStyle {

    private static let interfaceKey = "experimental_dark_interface"

    public static var isDark: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: interfaceKey)
        }
        get {
            if ProcessInfo.processInfo.environment["Force_Dark"] == "true" {
                return true
            }
            return UserDefaults.standard.bool(forKey: interfaceKey)
        }
    }
}

extension UIBarStyle {
    public static var wkrStyle: UIBarStyle {
        return WKRUIStyle.isDark ? .black : .default
    }
}

extension UIColor {

    // MARK: - Properties

    public static var wkrBackgroundColor: UIColor {
        return WKRUIStyle.isDark ? .black : .white
    }

    public static var wkrTextColor: UIColor {
        return WKRUIStyle.isDark ? .white : #colorLiteral(red: 54.0/255.0, green: 54.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    }

    public static var wkrLightTextColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 210.0/255.0, green: 210.0/255.0, blue: 210.0/255.0, alpha: 1.0)  : #colorLiteral(red: 136.0/255.0, green: 136.0/255.0, blue: 136.0/255.0, alpha: 1.0)
    }

    public static var wkrMenuTopViewColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }

    public static var wkrMenuBottomViewColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 0.05098039216, green: 0.05098039216, blue: 0.05098039216, alpha: 1) : #colorLiteral(red: 242.0/255.0, green: 242.0/255.0, blue: 242.0/255.0, alpha: 1.0)
    }

    public static var wkrMenuPuzzleViewColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 0.1568627451, green: 0.1568627451, blue: 0.1568627451, alpha: 1) : #colorLiteral(red: 218.0/255.0, green: 218.0/255.0, blue: 218.0/255.0, alpha: 1.0)
    }

    public static var wkrActivityIndicatorColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 0.6470588235, green: 0.6470588235, blue: 0.6470588235, alpha: 1) : #colorLiteral(red: 84.0/255.0, green: 84.0/255.0, blue: 84.0/255.0, alpha: 1.0)
    }

    public static var wkrBarTextColor: UIColor {
        return WKRUIStyle.isDark ?  .white : .black
    }

    public static var wkrVoteCountTextColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1) : .lightGray
    }

    public static var wkrVoteCountSelectedTextColor: UIColor {
        return WKRUIStyle.isDark ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) : .darkGray
    }

}

extension UIBlurEffect {
    public static var wkrBlurEffect: UIBlurEffect {
        return WKRUIStyle.isDark ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .extraLight)
    }
}

extension UIStatusBarStyle {
    public static var wkrStatusBarStyle: UIStatusBarStyle {
        return WKRUIStyle.isDark ? .lightContent : .default
    }
}
