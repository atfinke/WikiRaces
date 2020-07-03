//
//  WKRUIAlertView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit

final public class WKRUIAlertView: WKRUIBottomOverlayView {

    // MARK: - Types -

    private struct WKRAlertMessage: Equatable {
        let text: String
        let player: WKRPlayerProfile?
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
    private let imageView = UIImageView()

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
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(label)

        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.layer.cornerRadius = WKRUIKitConstants.alertViewImageHeight / 2
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        topConstraint = topAnchor.constraint(equalTo: alertWindow.bottomAnchor)

        let constraints: [NSLayoutConstraint] = [
            topConstraint,
            leftAnchor.constraint(equalTo: alertWindow.leftAnchor),
            rightAnchor.constraint(equalTo: alertWindow.rightAnchor),
            heightAnchor.constraint(equalToConstant: WKRUIKitConstants.alertViewHeight + alertWindow.safeAreaInsets.bottom / 2)
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
                        for player: WKRPlayerProfile?,
                        duration: Double = WKRUIKitConstants.alertDefaultDuration,
                        isRaceSpecific: Bool,
                        playHaptic: Bool) {

        let message = WKRAlertMessage(
            text: text,
            player: player,
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

        let rect = label.attributedText?.boundingRect(
            with: CGSize(width: frame.width, height: .infinity),
            options: .usesLineFragmentOrigin,
            context: nil) ?? bounds

        label.frame = rect

        let viewCenterY = frame.height / 2 - alertWindow.safeAreaInsets.bottom / 4
        let imageViewPadding = WKRUIKitConstants.alertViewImagePadding
        let imageViewWidth = WKRUIKitConstants.alertViewImageHeight

        if let player = message.player {
            imageView.isHidden = false
            label.center = CGPoint(x: center.x + (imageViewWidth + imageViewPadding) / 2, y: viewCenterY)
            imageView.image = player.rawImage

            imageView.frame = CGRect(
                x: label.frame.minX - imageViewWidth - imageViewPadding,
                y: viewCenterY - imageViewWidth / 2,
                width: imageViewWidth,
                height: imageViewWidth)

        } else {
            imageView.isHidden = true
            label.center = CGPoint(x: center.x, y: viewCenterY)
        }

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
