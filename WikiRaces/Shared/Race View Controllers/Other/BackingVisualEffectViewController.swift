//
//  BackingVisualEffectViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 7/2/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

internal class BackingVisualEffectViewController: UIViewController {

    // MARK: - Properties

    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect.wkrBlurEffect)
    final var contentView: UIView {
        return visualEffectView.contentView
    }

    private var hostingView: UIView?
    private let backingAlphaView = UIView()
    var backingAlpha: CGFloat {
        set {
            backingAlphaView.alpha = newValue
        }
        get {
            return backingAlphaView.alpha
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let nav = navigationController else { return }
        nav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nav.navigationBar.shadowImage = UIImage()
        nav.navigationBar.isTranslucent = true
        nav.view.backgroundColor = .clear

        backingAlphaView.backgroundColor = UIColor.systemBackground

        view.addSubview(backingAlphaView)
        view.addSubview(visualEffectView)
    }

    // MARK: - Interface

    func configure(hostingView: UIView) {
        hostingView.frame = view.frame
        hostingView.backgroundColor = .clear
        contentView.addSubview(hostingView)
        self.hostingView = hostingView
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        backingAlphaView.frame = view.frame
        visualEffectView.frame = view.frame
        hostingView?.frame = view.frame
    }
}
