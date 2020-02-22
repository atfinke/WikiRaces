//
//  CommonExtensions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import StoreKit

extension Bundle {
    var appInfo: (build: Int, version: String) {
        guard let bundleBuildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            let bundleBuild = Int(bundleBuildString),
            let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                fatalError("No bundle info dictionary")
        }
        return (bundleBuild, bundleVersion)
    }
}

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
                             toAlpha alpha: CGFloat = 0,
                             items: [UIView],
                             whenHidden: (() -> Void)?,
                             completion: (() -> Void)?) {
        UIView.animate(withDuration: duration / 2.0, animations: {
            items.forEach { $0.alpha = alpha }
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

extension SKStoreReviewController {
    private static let shouldPromptForRatingKey = "ShouldPromptForRating"

    static var shouldPromptForRating: Bool {
        get {
            return UserDefaults.standard.bool(forKey: shouldPromptForRatingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: shouldPromptForRatingKey)
        }
    }
}

extension UIApplication {
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            fatalError("Settings URL nil")
        }
        open(settingsURL, options: [:], completionHandler: nil)
    }
}
