//
//  WKRUIStyle.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 9/22/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

final public class WKRUIStyle {
    public static func isDark(_ traitCollection: UITraitCollection) -> Bool {
        if traitCollection.userInterfaceStyle == .dark {
            return true
        } else {
            return false
        }
    }
}
