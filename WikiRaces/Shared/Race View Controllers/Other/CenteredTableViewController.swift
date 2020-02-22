//
//  CenteredTableViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

internal class CenteredTableViewController: UIViewController {

    // MARK: - Properties

    var overlayButtonTitle: String? {
        set {
            overlayButton.title = newValue ?? ""
        }
        get {
            return overlayButton.title
        }
    }

    var isOverlayButtonHidden: Bool {
        set {
            guard isInterfaceLoaded else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                    self.isOverlayButtonHidden = newValue
                })
                return
            }
            overlayBottomConstraint.constant = newValue ? overlayHeightConstraint.constant : 0
            descriptionLabelBottomConstraint.constant = newValue ? -view.safeAreaInsets.bottom: 0
        }
        get {
            return overlayBottomConstraint.constant == overlayHeightConstraint.constant
        }
    }

    let guideLabel = UILabel()
    let descriptionLabel = UILabel()

    let reuseIdentifier = "cell"
    let tableView = WKRUICenteredTableView()
    let overlayButton = WKRUIButton()

    var contentView: UIView!
    private var overlayBottomConstraint: NSLayoutConstraint!
    private var overlayHeightConstraint: NSLayoutConstraint!
    private var descriptionLabelBottomConstraint: NSLayoutConstraint!

    private var isInterfaceLoaded = false

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
        isInterfaceLoaded = true
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guideLabel.textColor = .wkrSubtitleTextColor(for: traitCollection)
        descriptionLabel.textColor = .wkrTextColor(for: traitCollection)
    }

    // MARK: - Interface

    //swiftlint:disable:next function_body_length
    private func setupInterface() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect.wkrLightBlurEffect)

        tableView.estimatedRowHeight = 0
        tableView.isUserInteractionEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.contentView.addSubview(tableView)
        tableView.allowsSelection = true

        guideLabel.textAlignment = .center
        guideLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .medium)
        guideLabel.adjustsFontSizeToFitWidth = true
        guideLabel.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(guideLabel)

        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont(monospaceSize: 20, weight: .medium)
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(descriptionLabel)

        self.view = visualEffectView
        self.contentView = visualEffectView.contentView

        let overlayView = setupBottomOverlayView()
        overlayBottomConstraint = overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 70)
        overlayHeightConstraint = overlayView.heightAnchor.constraint(equalToConstant: 70)

        let fakeWidth = tableView.widthAnchor.constraint(equalToConstant: 500)
        fakeWidth.priority = UILayoutPriority.defaultLow

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        descriptionLabelBottomConstraint = descriptionLabel.bottomAnchor.constraint(equalTo: overlayView.topAnchor)

        let constraints: [NSLayoutConstraint] = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leftAnchor.constraint(greaterThanOrEqualTo: visualEffectView.leftAnchor, constant: 25),
            tableView.rightAnchor.constraint(lessThanOrEqualTo: visualEffectView.rightAnchor),
            tableView.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            tableView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            fakeWidth,

            overlayView.leftAnchor.constraint(equalTo: view.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayHeightConstraint,
            overlayBottomConstraint,

            descriptionLabel.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor),
            descriptionLabel.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor),
            descriptionLabelBottomConstraint,
            descriptionLabel.heightAnchor.constraint(equalToConstant: 50),

            guideLabel.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor),
            guideLabel.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor),
            guideLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupBottomOverlayView() -> WKRUIBottomOverlayView {
        guard let visualEffectView = view as? UIVisualEffectView else {
            fatalError("View not a UIVisualEffectView")
        }

        let bottomOverlayView = WKRUIBottomOverlayView()
        bottomOverlayView.translatesAutoresizingMaskIntoConstraints = false
        bottomOverlayView.clipsToBounds = true
        visualEffectView.contentView.addSubview(bottomOverlayView)

        overlayButton.title = "Ready up"
        overlayButton.translatesAutoresizingMaskIntoConstraints = false
        overlayButton.addTarget(self, action: #selector(overlayButtonPressed), for: .touchUpInside)
        bottomOverlayView.contentView.addSubview(overlayButton)

        let constraints = [
            overlayButton.centerXAnchor.constraint(equalTo: bottomOverlayView.centerXAnchor),
            overlayButton.topAnchor.constraint(equalTo: bottomOverlayView.topAnchor, constant: 15),
            overlayButton.widthAnchor.constraint(equalToConstant: 250),
            overlayButton.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)

        return bottomOverlayView
    }

    @objc
    func overlayButtonPressed() {
        fatalError("overlayButtonPressed not implemented")
    }

    func registerTableView<T: UITableViewDelegate & UITableViewDataSource>(for controller: T) {
        tableView.delegate = controller
        tableView.dataSource = controller
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        descriptionLabelBottomConstraint.constant = -view.safeAreaInsets.bottom
        overlayHeightConstraint.constant = 70 + view.safeAreaInsets.bottom
        isOverlayButtonHidden = true
    }

}
