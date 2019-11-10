//
//  UIFont+Rounded.swift
//  magic.world
//
//  Created by Andrew Finke on 10/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

extension UIFont {
    static func systemRoundedFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont? {
        if #available(iOS 13.0, *) {
            let font = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
                fatalError()
            }
            return UIFont(descriptor: descriptor, size: size)
        } else {
            return nil
        }
    }
}
