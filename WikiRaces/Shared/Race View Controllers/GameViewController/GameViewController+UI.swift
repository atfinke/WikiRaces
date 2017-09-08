//
//  GameViewController+UI.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

extension GameViewController {

    // MARK: - Interface

    func setupInterface() {
        guard let navigationController = navigationController,
            let navigationView = navigationController.view else {
                fatalError()
        }

        navigationItem.hidesBackButton = true

        flagBarButtonItem = navigationItem.leftBarButtonItem
        quitBarButtonItem = navigationItem.rightBarButtonItem

        thinLine.alpha = 0
        thinLine.backgroundColor = UIColor.wkrTextColor
        thinLine.translatesAutoresizingMaskIntoConstraints = false
        navigationView.addSubview(thinLine)

        setupWebView()

        let constraints: [NSLayoutConstraint] = [
            thinLine.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            thinLine.leftAnchor.constraint(equalTo: navigationView.leftAnchor),
            thinLine.rightAnchor.constraint(equalTo: navigationView.rightAnchor),
            thinLine.heightAnchor.constraint(equalToConstant: 1)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupAlertView() {
        guard let window = navigationController?.view.window else {
            fatalError("Couldn't get window")
        }

        alertView = WKRUIAlertView(window: window)
        manager.configure(webView: webView, alertView: alertView)
    }

    // MARK: - Elements

    private func setupWebView() {
        webView.alpha = 0.0

        var contentInset = webView.scrollView.contentInset
        contentInset.bottom = -20
        webView.scrollView.contentInset = contentInset

        view.addSubview(webView)
        view.addSubview(progressView)
        webView.progressView = progressView

        let constraints: [NSLayoutConstraint] = [
            webView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            progressView.leftAnchor.constraint(equalTo: view.leftAnchor),
            progressView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Alerts

    func quitAlertController(raceStarted: Bool) -> UIAlertController {
        var message = "Are you sure you want to quit? You will be disconnected from the match and returned to the menu."
        if raceStarted {
            message += " Press the forfeit button to give up on the race but stay in the match."
        }

        let alertController = UIAlertController(title: "Leave The Match?", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Keep Playing", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if raceStarted {
            let forfeitAction = UIAlertAction(title: "Forfeit Race", style: .default) {  [weak self] _ in
                self?.manager.player(.forfeited)
            }
            alertController.addAction(forfeitAction)
        }
        let quitAction = UIAlertAction(title: "Quit Match", style: .destructive) {  [weak self] _ in
            self?.manager.player(.quit)

            guard let window = self?.view.window else {
                NotificationCenter.default.post(name: NSNotification.Name("PlayerQuit"), object: nil)
                return
            }
            let fadeView = UIView()
            fadeView.backgroundColor = UIColor.white
            fadeView.alpha = 0.0
            fadeView.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(fadeView)

            let constraints = [
                fadeView.leftAnchor.constraint(equalTo: window.leftAnchor),
                fadeView.rightAnchor.constraint(equalTo: window.rightAnchor),
                fadeView.topAnchor.constraint(equalTo: window.topAnchor),
                fadeView.bottomAnchor.constraint(equalTo: window.bottomAnchor)
            ]
            NSLayoutConstraint.activate(constraints)

            UIView.animate(withDuration: 0.5, animations: {
                //fadeView.alpha = 1.0
            }, completion: { _ in
                //self?.navigationController?.dismiss(animated: true, completion: nil)
                NotificationCenter.default.post(name: NSNotification.Name("PlayerQuit"), object: nil)
                fadeView.removeFromSuperview()
            })
        }
        alertController.addAction(quitAction)
        return alertController
    }

}
