//
//  WKRUIKit+Blurs.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/10/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

extension UIBlurEffect {
    public static var wkrBlurEffect: UIBlurEffect {
        if #available(iOS 13.0, *) {
            return UIBlurEffect(style: .systemThickMaterial)
        } else {
            return UIBlurEffect(style: .extraLight)
        }
    }

    public static var wkrLightBlurEffect: UIBlurEffect {
        if #available(iOS 13.0, *) {
            return UIBlurEffect(style: .systemMaterial)
        } else {
            return UIBlurEffect(style: .extraLight)
        }
    }
}
