//
//  HostingViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import UIKit

internal class HostingViewController: UIViewController {
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let nav = navigationController else { return }
        nav.navigationBar.setBackgroundImage(UIImage(), for: .default)
        nav.navigationBar.shadowImage = UIImage()
        nav.navigationBar.isTranslucent = true
        nav.view.backgroundColor = .clear
    }
    
    func configure(hostingView: UIView) {
        hostingView.backgroundColor = .clear
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        let contraints = [
            hostingView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            hostingView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            hostingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        view.addSubview(hostingView)
        NSLayoutConstraint.activate(contraints)
    }
    
}
