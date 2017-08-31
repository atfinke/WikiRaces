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
            let navigationView = navigationController.view else { fatalError() }

        navigationItem.hidesBackButton = true
        navigationController.hidesBarsOnSwipe = true
        navigationController.navigationBar.layer.zPosition = 0
        navigationController.navigationBar.isTranslucent = false

        let action = #selector(navigationControllerPanGestureUpdated(_:))
        navigationController.barHideOnSwipeGestureRecognizer.addTarget(self, action: action)

        flagBarButtonItem = navigationItem.leftBarButtonItem
        quitBarButtonItem = navigationItem.rightBarButtonItem

        let statusBarBackgroundView = UIView()
        statusBarBackgroundView.backgroundColor = UIColor.white
        statusBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        statusBarBackgroundView.layer.zPosition = 1
        navigationView.addSubview(statusBarBackgroundView)

        thinLine.alpha = 0
        thinLine.backgroundColor = UIColor.wkrTextColor
        thinLine.translatesAutoresizingMaskIntoConstraints = false
        navigationView.addSubview(thinLine)

        setupWebView()

        let constraints: [NSLayoutConstraint] = [
            statusBarBackgroundView.topAnchor.constraint(equalTo: navigationView.topAnchor),
            statusBarBackgroundView.leftAnchor.constraint(equalTo: navigationView.leftAnchor),
            statusBarBackgroundView.rightAnchor.constraint(equalTo: navigationView.rightAnchor),
            statusBarBackgroundView.heightAnchor.constraint(
                equalToConstant: UIApplication.shared.statusBarFrame.height),

            thinLine.topAnchor.constraint(equalTo: statusBarBackgroundView.bottomAnchor),
            thinLine.leftAnchor.constraint(equalTo: statusBarBackgroundView.leftAnchor),
            thinLine.rightAnchor.constraint(equalTo: statusBarBackgroundView.rightAnchor),
            thinLine.heightAnchor.constraint(equalToConstant: 1)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupAlertView() {
        guard let window = navigationController?.view.window else {
            fatalError("Couldn't get window")
        }

        alertView = WKRUIAlertView(window: window, presentationHandler: {
            self.alertViewWillAppear()
        }, dismissalHandler: {
            self.alertViewWillDisappear()
        })

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

        bottomConstraint = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        let constraints: [NSLayoutConstraint] = [
            webView.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomConstraint!,

            progressView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            progressView.leftAnchor.constraint(equalTo: view.leftAnchor),
            progressView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    @objc func navigationControllerPanGestureUpdated(_ sender: UIPanGestureRecognizer) {
        guard let yCord = navigationController?.navigationBar.frame.origin.y, sender.state == .ended else { return }
        if yCord < 0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.thinLine.alpha = 0.2
            })
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.thinLine.alpha = 0.0
            })
        }
    }

    // MARK: - Alerts

    func alertViewWillAppear() {
        wikiDebugLog(nil)

        let scrollView = webView.scrollView
        var contentOffset = scrollView.contentOffset
        let trueContentOffset = contentOffset.y - scrollView.contentInset.bottom

        if trueContentOffset + scrollView.frame.height == scrollView.contentSize.height {
            contentOffset.y += alertViewHeight
        }

        bottomConstraint?.constant = -alertViewHeight
        view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: alertViewAnimateInDuration) {
            self.view.layoutIfNeeded()
            self.webView.scrollView.contentOffset = contentOffset
        }
    }

    func alertViewWillDisappear() {
        wikiDebugLog(nil)

        bottomConstraint?.constant = 0
        view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: alertViewAnimateOutDuration) {
            self.view.layoutIfNeeded()
        }
    }

}
