//
//  WKRUIAlertView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIAlertView: WKRUIBottomOverlayView {

    // MARK: - Types

    private struct WKRAlertMessage {
        let text: String
        let duration: Double
    }

    // MARK: - Properties

    private var queue = [WKRAlertMessage]()

    private let presentationHandler: () -> Void
    private let dismissalHandler: () -> Void

    private let label = UILabel()
    private let alertWindow: UIWindow
    private var bottomConstraint: NSLayoutConstraint!

    private var height: CGFloat {
        return WKRUIConstants.alertHeight
    }

    // MARK: - Initalization

    public init(window: UIWindow,
                presentationHandler: @escaping () -> Void,
                dismissalHandler: @escaping () -> Void) {

        alertWindow = window
        self.presentationHandler = presentationHandler
        self.dismissalHandler = dismissalHandler

        super.init()

        alertWindow.addSubview(self)

        label.textColor = UIColor.wkrTextColor
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        bottomConstraint = bottomAnchor.constraint(equalTo: alertWindow.bottomAnchor, constant: height)
        let constraints: [NSLayoutConstraint] = [
            bottomConstraint,
            heightAnchor.constraint(equalToConstant: height),
            leftAnchor.constraint(equalTo: alertWindow.leftAnchor),
            rightAnchor.constraint(equalTo: alertWindow.rightAnchor),

            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 10.0),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -10.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Enqueuing Messages

    public func enqueue(text: String, duration: Double = 5.0) {
        let message = WKRAlertMessage(text: text, duration: duration)
        queue.append(message)
        present()
    }

    // MARK: - State

    private func present() {
        guard !queue.isEmpty, bottomConstraint.constant == height else { return }

        presentationHandler()

        let message = queue.removeFirst()
        label.text = message.text.uppercased()

        bottomConstraint.constant = 0
        alertWindow.setNeedsUpdateConstraints()
        alertWindow.bringSubview(toFront: self)

        UIView.animate(withDuration: WKRUIConstants.alertAnimateInDuration) {
            self.alertWindow.layoutIfNeeded()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) {
            self.dismiss()
        }
    }

    private func dismiss() {
        bottomConstraint.constant = height
        alertWindow.setNeedsUpdateConstraints()

        dismissalHandler()

        UIView.animate(withDuration: WKRUIConstants.alertAnimateOutDuration, animations: {
            self.alertWindow.layoutIfNeeded()
        }, completion: { _ in
            self.present()
        })
    }

}

extension UIViewController {
    public var alertViewHeight: CGFloat {
        return WKRUIConstants.alertHeight
    }

    public var alertViewAnimateInDuration: Double {
        return WKRUIConstants.alertAnimateInDuration
    }

    public var alertViewAnimateOutDuration: Double {
        return WKRUIConstants.alertAnimateOutDuration
    }
}
