//
//  VisualEffectViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

internal class VisualEffectViewController: UIViewController {

    // MARK: - Properties

    final var contentView: UIView!

    // MARK: - View Life Cycle

    override func loadView() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect.wkrLightBlurEffect)
        contentView = visualEffectView.contentView
        self.view = visualEffectView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let nav = navigationController else { return }
        nav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nav.navigationBar.shadowImage = UIImage()
        nav.navigationBar.isTranslucent = true
        nav.view.backgroundColor = .clear
    }

    // MARK: - Interface

    func configure(hostingView: UIView) {
        hostingView.backgroundColor = .clear
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        let contraints = [
            hostingView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor),
            hostingView.rightAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.rightAnchor),
            hostingView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor)
        ]
        contentView.addSubview(hostingView)
        NSLayoutConstraint.activate(contraints)
    }
}
