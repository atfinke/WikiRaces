//
//  HelpViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/30/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WebKit
import WKRUIKit

internal class HelpViewController: StateLogViewController, WKNavigationDelegate {

    // MARK: - Properties

    var url: URL?
    var linkTapped: (() -> Void)?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.wkrBackgroundColor
        navigationController?.navigationBar.barStyle = UIBarStyle.wkrStyle
        navigationController?.view.backgroundColor = UIColor.wkrBackgroundColor

        let webView = WKRUIWebView()
        webView.navigationDelegate = self
        view = webView

        guard let url = url else {
           return // When would this happen?
        }

        webView.load(URLRequest(url: url))
    }

    // MARK: - Actions

    @IBAction func doneButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url == url {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            linkTapped?()
        }
    }

}
