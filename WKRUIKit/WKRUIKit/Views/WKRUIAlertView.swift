//
//  WKRUIAlertView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

final public class WKRUIAlertView: WKRUIBottomOverlayView {

    // MARK: - Types -

    private struct WKRAlertMessage: Equatable {
        let text: String
        let duration: Double
        let isRaceSpecific: Bool
        let playHaptic: Bool
    }

    // MARK: - Properties -

    private var queue = [WKRAlertMessage]()

    private let label = UILabel()
    private let alertWindow: UIWindow
    private var topConstraint: NSLayoutConstraint!

    private var isPresenting = false

    // MARK: - Initalization -

    public override init() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            fatalError("Couldn't get key window")
        }
        alertWindow = window

        super.init()

        alertWindow.addSubview(self)

        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        topConstraint = topAnchor.constraint(equalTo: alertWindow.bottomAnchor)

        let inset: CGFloat = 10
        let constraints: [NSLayoutConstraint] = [
            topConstraint,
            leftAnchor.constraint(equalTo: alertWindow.leftAnchor),
            rightAnchor.constraint(equalTo: alertWindow.rightAnchor),

            label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset - alertWindow.safeAreaInsets.bottom / 2),

            label.leftAnchor.constraint(equalTo: leftAnchor, constant: inset),
            label.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset),

            label.heightAnchor.constraint(greaterThanOrEqualToConstant: WKRUIKitConstants.alertLabelHeight)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        label.textColor = .wkrTextColor(for: traitCollection)
    }

    // MARK: - Enqueuing Messages -

    public func enqueue(text: String,
                        duration: Double = WKRUIKitConstants.alertDefaultDuration,
                        isRaceSpecific: Bool,
                        playHaptic: Bool) {

        let message = WKRAlertMessage(text: text,
                                      duration: duration,
                                      isRaceSpecific: isRaceSpecific,
                                      playHaptic: playHaptic)

        // Make sure message doesn't equal most recent in queue.
        // If queue empty, make sure message isn't the same as the one being displayed.
        if let lastMessage = queue.last,
            lastMessage == message {
            return
        } else if queue.isEmpty,
            let currentMessageText = label.text,
            currentMessageText == text {
            return
        } else {
            queue.append(message)
            present()
        }
    }

    public func forceDismiss() {
        queue = []
        self.dismiss()
    }

    public func clearRaceSpecificMessages() {
        queue = queue.filter({ !$0.isRaceSpecific })
    }

    // MARK: - State -

    private func present() {
        guard !queue.isEmpty, !isPresenting else { return }
        isPresenting = true

        let message = queue.removeFirst()
        label.text = message.text.uppercased()
        setNeedsLayout()
        layoutIfNeeded()

        topConstraint.constant = -frame.height
        alertWindow.setNeedsLayout()
        alertWindow.bringSubviewToFront(self)

        if message.playHaptic {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }

        UIView.animate(withDuration: WKRUIKitConstants.alertAnimateInDuration) {
            self.alertWindow.layoutIfNeeded()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + message.duration) {
            self.dismiss()
        }
    }

    private func dismiss() {
        topConstraint.constant = 0
        alertWindow.setNeedsLayout()

        UIView.animate(withDuration: WKRUIKitConstants.alertAnimateOutDuration, animations: {
            self.alertWindow.layoutIfNeeded()
        }, completion: { _ in
            self.label.text = nil
            self.isPresenting = false
            self.present()
        })
    }

}
