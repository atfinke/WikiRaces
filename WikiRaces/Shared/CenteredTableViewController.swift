//
//  CenteredTableViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

class CenteredTableViewController: UIViewController {

    // MARK: Properties

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
            overlayBottomConstraint.constant = newValue ? 70 : 0
        }
        get {
            return overlayBottomConstraint.constant == 70
        }
    }

    let reuseIdentifier = "cell"
    let overlayButton = WKRUIButton()
    let descriptionLabel = UILabel()
    let tableView = WKRUICenteredTableView()
    var overlayBottomConstraint: NSLayoutConstraint!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
    }

    // MARK: - Helpers

    private func setupInterface() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

        tableView.estimatedRowHeight = 0
        tableView.isUserInteractionEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.contentView.addSubview(tableView)
        tableView.allowsSelection = true

        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont(monospaceSize: 20.0)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(descriptionLabel)

        self.view = visualEffectView

        let overlayView = setupBottomOverlayView()
        overlayBottomConstraint = overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 70)

        let fakeWidth = tableView.widthAnchor.constraint(equalToConstant: 500)
        fakeWidth.priority = UILayoutPriority.defaultLow

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        let constraints: [NSLayoutConstraint] = [
            tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(greaterThanOrEqualTo: visualEffectView.leftAnchor, constant: 25),
            tableView.rightAnchor.constraint(lessThanOrEqualTo: visualEffectView.rightAnchor),
            tableView.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            tableView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            fakeWidth,

            overlayView.leftAnchor.constraint(equalTo: view.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: 70),
            overlayBottomConstraint,

            descriptionLabel.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor),
            descriptionLabel.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: overlayView.topAnchor),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 50)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func setupBottomOverlayView() -> WKRUIBottomOverlayView {
        guard let visualEffectView = view as? UIVisualEffectView else {
            fatalError()
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
            overlayButton.centerYAnchor.constraint(equalTo: bottomOverlayView.centerYAnchor),
            overlayButton.widthAnchor.constraint(equalToConstant: 250),
            overlayButton.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)

        return bottomOverlayView
    }

    @objc func overlayButtonPressed() {}

    func registerTableView<T: UITableViewDelegate & UITableViewDataSource>(for controller: T) {
        tableView.delegate = controller
        tableView.dataSource = controller
    }

}
