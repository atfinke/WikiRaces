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

    private struct WKRAlertMessage: Equatable {
        let text: String
        let duration: Double

        //swiftlint:disable:next operator_whitespace
        static func ==(lhs: WKRAlertMessage, rhs: WKRAlertMessage) -> Bool {
            return lhs.text == rhs.text
        }
    }

    // MARK: - Properties

    private var queue = [WKRAlertMessage]()

    private let label = UILabel()
    private let alertWindow: UIWindow
    private var bottomConstraint: NSLayoutConstraint!

    private var height: CGFloat {
        if #available(iOS 11.0, *) {
            return WKRUIConstants.alertHeight + (window?.safeAreaInsets.bottom ?? 0) / 2
        } else {
            return WKRUIConstants.alertHeight
        }
    }

    // MARK: - Initalization

    public override init() {
        guard let window = UIApplication.shared.keyWindow else {
            fatalError("Couldn't get key window")
        }

        alertWindow = window

        super.init()

        alertWindow.addSubview(self)

        label.textColor = UIColor.wkrTextColor
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        bottomConstraint = bottomAnchor.constraint(equalTo: alertWindow.bottomAnchor, constant: height)
        let constraints: [NSLayoutConstraint] = [
            bottomConstraint,
            heightAnchor.constraint(equalToConstant: height),
            leftAnchor.constraint(equalTo: alertWindow.leftAnchor),
            rightAnchor.constraint(equalTo: alertWindow.rightAnchor),

            label.topAnchor.constraint(equalTo: topAnchor),
            label.heightAnchor.constraint(equalToConstant: WKRUIConstants.alertHeight),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 10.0),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -10.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Enqueuing Messages

    public func enqueue(text: String, duration: Double = WKRUIConstants.alertDefaultDuration) {
        let message = WKRAlertMessage(text: text, duration: duration)

        // Make sure message doesn't equal most recent in queue.
        // If queue empty, make sure message isn't the same as the one being displayed.
        if let lastMessage = queue.last {
            if lastMessage != message {
                queue.append(message)
                present()
            }
        } else if let currentMessageText = label.text {
            if currentMessageText != text {
                queue.append(message)
                present()
            }

        } else {
            queue.append(message)
            present()
        }
    }

    // MARK: - State

    private func present() {
        guard !queue.isEmpty, bottomConstraint.constant == height else { return }

        let message = queue.removeFirst()
        label.text = message.text.uppercased()

        bottomConstraint.constant = 0
        alertWindow.setNeedsUpdateConstraints()
        alertWindow.bringSubview(toFront: self)

        UINotificationFeedbackGenerator().notificationOccurred(.warning)

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

        UIView.animate(withDuration: WKRUIConstants.alertAnimateOutDuration, animations: {
            self.alertWindow.layoutIfNeeded()
        }, completion: { _ in
            self.label.text = nil
            self.present()
        })
    }

}
