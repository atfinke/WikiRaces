//
//  PlusView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

class PlusView: UIView {

    // MARK: - Properties -

    private let closeImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(weight: .light)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private let closeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Unlock WikiRaces+"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Thanks for using WikiRaces!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Please consider supporting development costs to unlock exclusive features."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private let iconView: UIView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "PreviewIcon.png")
        imageView.clipsToBounds = true
        return imageView
    }()

    private let standardOptionButton: ActivityButton = {
        let button = ActivityButton()
        button.label.text = PlusStore.shared.products?.standard.displayString
        button.layer.borderWidth = 1.7
        return button
    }()

    private let ultimateOptionButton: ActivityButton = {
        let button = ActivityButton()
        button.label.text = PlusStore.shared.products?.ultimate.displayString
        button.layer.borderWidth = 1.7
        return button
    }()

    private let restoreButton: ActivityButton = {
        let button = ActivityButton()
        button.label.text = "Restore\nPurchase"
        button.backgroundColor = .systemFill
        return button
    }()

    private let loadingOptionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading Products"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private let privacyButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitle("Privacy Policy", for: .normal)
        return button
    }()

    private let termsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitle("Terms of Use", for: .normal)
        return button
    }()

    var onCompletion: (() -> Void)?
    var onError: ((UIAlertController) -> Void)?

    // MARK: - Initalization -

    init() {
        super.init(frame: .zero)

        toggleProductButtons(on: false)

        addSubview(closeImageView)
        addSubview(closeButton)

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(descriptionLabel)
        addSubview(iconView)
        addSubview(loadingOptionsLabel)

        addSubview(standardOptionButton)
        addSubview(ultimateOptionButton)
        addSubview(restoreButton)

        addSubview(privacyButton)
        addSubview(termsButton)

        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        standardOptionButton.addTarget(self, action: #selector(purchaseStandard), for: .touchUpInside)
        ultimateOptionButton.addTarget(self, action: #selector(purchaseUltimate), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restorePurchase), for: .touchUpInside)
        privacyButton.addTarget(self, action: #selector(openPrivacy), for: .touchUpInside)
        termsButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            forName: PlusStore.productsUpdatedNotificationName,
                                               object: nil,
                                               queue: nil) { _ in
                                                DispatchQueue.main.async {
                                                    guard let products = PlusStore.shared.products else {
                                                        self.toggleProductButtons(on: false)
                                                        return
                                                    }
                                                    self.standardOptionButton.label.text = products.standard.displayString
                                                    self.ultimateOptionButton.label.text = products.ultimate.displayString
                                                    self.toggleProductButtons(on: true)
                                                }
        }

                self.toggleProductButtons(on: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let color: UIColor = .wkrTextColor(for: traitCollection)
        closeImageView.tintColor = color
        titleLabel.textColor = color
        descriptionLabel.textColor = color
        standardOptionButton.layer.borderColor = color.cgColor
        ultimateOptionButton.layer.borderColor = color.cgColor

        subtitleLabel.textColor = .secondaryLabel
        privacyButton.setTitleColor(.secondaryLabel, for: .normal)
        termsButton.setTitleColor(.secondaryLabel, for: .normal)

        let closeImageViewImageSize: CGFloat = 20
        closeButton.frame = CGRect(
            x: bounds.width - closeImageViewImageSize - 15,
            y: 15,
            width: closeImageViewImageSize,
            height: closeImageViewImageSize)
        closeImageView.frame = closeButton.frame

        let padding: CGFloat = 25
        let paddedWidth = frame.width - padding * 2

        let paddedSize = CGSize(width: paddedWidth, height: .greatestFiniteMagnitude)
        titleLabel.frame = CGRect(x: padding,
                                  y: padding * 1.5,
                                  width: paddedWidth,
                                  height: 28)

        subtitleLabel.frame = CGRect(x: padding,
                                     y: titleLabel.frame.maxY,
                                     width: paddedWidth,
                                     height: 30)

        let iconViewWidth: CGFloat = 100
        iconView.frame = CGRect(x: frame.width / 2 - iconViewWidth / 2,
                                y: subtitleLabel.frame.maxY + padding,
                                width: iconViewWidth,
                                height: iconViewWidth)
        iconView.layer.cornerRadius = 0.22 * iconViewWidth
        iconView.layer.cornerCurve = .continuous

        let descriptionOptions: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let descriptionLabelText = descriptionLabel.text ?? ""
        let descriptionLabelFittedSize = descriptionLabelText.boundingRect(with: paddedSize,
                                                                           options: descriptionOptions,
                                                                           attributes: [
                                                                            .font: descriptionLabel.font as Any],
                                                                           context: nil)

        descriptionLabel.frame = CGRect(x: frame.width / 2 - descriptionLabelFittedSize.width / 2,
                                        y: iconView.frame.maxY + padding,
                                        width: descriptionLabelFittedSize.width,
                                        height: descriptionLabelFittedSize.height)

        let buttonWidth = (paddedWidth - padding * 2) / 3
        standardOptionButton.layer.cornerRadius = 12
        standardOptionButton.layer.cornerCurve = .continuous
        standardOptionButton.frame = CGRect(x: padding,
                                            y: descriptionLabel.frame.maxY + padding,
                                            width: buttonWidth,
                                            height: 60)

        ultimateOptionButton.layer.cornerRadius = standardOptionButton.layer.cornerRadius
        ultimateOptionButton.layer.cornerCurve = .continuous
        ultimateOptionButton.frame = CGRect(x: frame.width / 2 - buttonWidth / 2,
                                            y: standardOptionButton.frame.minY,
                                            width: buttonWidth,
                                            height: standardOptionButton.frame.height)

        restoreButton.layer.cornerRadius = standardOptionButton.layer.cornerRadius
        restoreButton.layer.cornerCurve = .continuous
        restoreButton.frame = CGRect(x: padding + paddedWidth - buttonWidth,
                                     y: standardOptionButton.frame.minY,
                                     width: buttonWidth,
                                     height: standardOptionButton.frame.height)

        loadingOptionsLabel.frame = CGRect(x: standardOptionButton.frame.minX,
                                           y: standardOptionButton.frame.minY,
                                           width: paddedWidth,
                                           height: standardOptionButton.frame.height)

        let bottomButtonWidth = paddedWidth / 2
        let bottomButtonOffset = (frame.width / 2 - bottomButtonWidth) / 2
        privacyButton.frame = CGRect(x: bottomButtonOffset,
                                     y: standardOptionButton.frame.maxY + padding * 0.8,
                                     width: bottomButtonWidth,
                                     height: 20)

        termsButton.frame = CGRect(x: frame.width / 2 + bottomButtonOffset,
                                   y: privacyButton.frame.minY,
                                   width: bottomButtonWidth,
                                   height: privacyButton.frame.height)

        frame = CGRect(origin: frame.origin,
                       size: CGSize(
                        width: frame.size.width,
                        height: privacyButton.frame.maxY + padding / 2))

    }

    // MARK: - Helpers -

    //swiftlint:disable:next identifier_name
    private func toggleProductButtons(on: Bool) {
        loadingOptionsLabel.isHidden = on
        standardOptionButton.isHidden = !on
        ultimateOptionButton.isHidden = !on
        restoreButton.isHidden = !on
    }

    private func purchase(type: PlusStore.PlusType, onError: @escaping (() -> Void)) {
        func presentError() {
            let alertController = UIAlertController(
                title: "Signup Issue",
                message: "There was an issue processing your payment for WikiRaces+",
                preferredStyle: .alert)
            let action = UIAlertAction(title: "ok", style: .default, handler: nil)
            alertController.addAction(action)
            self.onError?(alertController)
        }

        PlusStore.shared.purchase(type: type) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    if success {
                        self.onCompletion?()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } else {
                        presentError()
                        onError()
                    }
                case .failure:
                    presentError()
                    onError()
                }
            }
        }
    }

    // MARK: - Buttons -

    @objc
    func close() {
        onCompletion?()
    }

    @objc
    func purchaseStandard() {
        standardOptionButton.displayState = .activity
        purchase(type: .standard, onError: { [weak self] in
            self?.standardOptionButton.displayState = .label
        })
    }

    @objc
    func purchaseUltimate() {
        standardOptionButton.displayState = .activity
        purchase(type: .ultimate, onError: { [weak self] in
            self?.standardOptionButton.displayState = .label
        })
    }

    @objc
    func restorePurchase() {
        PlusStore.shared.restore()
    }

    @objc
    func openPrivacy() {
        //  UIApplication.shared.open(resort.privacyURL, options: [:], completionHandler: nil)
    }

    @objc
    func openTerms() {
        // UIApplication.shared.open(resort.termsURL, options: [:], completionHandler: nil)
    }
}
