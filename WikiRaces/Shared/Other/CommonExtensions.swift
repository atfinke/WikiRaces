//
//  CommonExtensions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

extension IndexPath {
    init(row: Int) {
        self.init(row: row, section: 0)
    }
}

extension UINavigationController {
    var rootViewController: UIViewController? {
        return viewControllers.first
    }
}

extension UIView {
    static func animate(withDuration duration: Double,
                        delay: Double,
                        animations: @escaping () -> Void,
                        completion: ((Bool) -> Void)? = nil) {

        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .beginFromCurrentState,
                       animations: animations,
                       completion: completion)
    }
}
