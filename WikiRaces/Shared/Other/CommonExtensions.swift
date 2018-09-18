//
//  CommonExtensions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

extension NSNotification.Name {
    static let localPlayerQuit = NSNotification.Name(rawValue: "LocalPlayerQuit")
}

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

extension UIAlertController {
    func addCancelAction(title: String) {
        let action = UIAlertAction(title: title, style: .cancel, handler: nil)
        addAction(action)
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

    static func animateFlash(withDuration duration: TimeInterval,
                             items: [UIView],
                             whenHidden: (() -> Void)?,
                             completion: (() -> Void)?) {
        UIView.animate(withDuration: duration / 2.0, animations: {
            items.forEach { $0.alpha = 0.0 }
        }, completion: { _ in
            whenHidden?()
            UIView.animate(withDuration: duration / 2.0, animations: {
                items.forEach { $0.alpha = 1.0 }
            }, completion: { _ in
                completion?()
            })
        })
    }
}
