//
//  ViewController.swift
//  WKRUIKit (UI Catalog)
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

class ViewController: UIViewController {

    var webView: WKRUIWebView!

    override func viewDidLoad() {
        WKRUIKitConstants.updateConstants()

        super.viewDidLoad()

        webView = WKRUIWebView()
        webView.load(URLRequest(url: URL(string: "https://en.m.wikipedia.org/wiki/apple_inc")!))

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        let constraints: [NSLayoutConstraint] = [
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        navigationController?.navigationBar.barStyle = .wkrStyle

        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { (_) in
            DispatchQueue.main.async {
                self.title = self.webView.pixelsScrolled.description
            }
        }
    }

}
