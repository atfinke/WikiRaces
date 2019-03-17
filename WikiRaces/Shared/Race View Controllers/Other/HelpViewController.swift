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

internal class HelpViewController: UIViewController, WKNavigationDelegate {

    // MARK: - Properties

    var url: URL?
    var linkTapped: (() -> Void)?

    let webView = WKRUIWebView()
    let progressView = WKRUIProgressView()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "HELP"
        view.backgroundColor = UIColor.wkrBackgroundColor
        navigationController?.navigationBar.barStyle = UIBarStyle.wkrStyle
        navigationController?.view.backgroundColor = UIColor.wkrBackgroundColor

        webView.text = ""
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        webView.progressView = progressView

        let constraints: [NSLayoutConstraint] = [
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leftAnchor.constraint(equalTo: view.leftAnchor),
            progressView.rightAnchor.constraint(equalTo: view.rightAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 6)
        ]
        NSLayoutConstraint.activate(constraints)

        guard let url = url else {
           return // When would this happen?
        }

        webView.startedPageLoad()
        webView.load(URLRequest(url: url))

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                            target: self,
                                                            action: #selector(doneButtonPressed))
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.completedPageLoad()
    }

}
