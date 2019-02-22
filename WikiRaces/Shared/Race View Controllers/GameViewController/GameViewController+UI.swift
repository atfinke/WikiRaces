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

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    func setupInterface() {
        guard let navigationController = navigationController,
            let navigationView = navigationController.view else {
                fatalError("No navigation controller view")
        }

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.navigationBar.barStyle = UIBarStyle.wkrStyle

        view.backgroundColor = UIColor.wkrBackgroundColor

        helpBarButtonItem = navigationItem.leftBarButtonItem
        quitBarButtonItem = navigationItem.rightBarButtonItem

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        navigationBarBottomLine.alpha = 0
        navigationBarBottomLine.backgroundColor = UIColor.wkrTextColor
        navigationBarBottomLine.translatesAutoresizingMaskIntoConstraints = false
        navigationView.addSubview(navigationBarBottomLine)

        setupWebView()

        let constraints: [NSLayoutConstraint] = [
            navigationBarBottomLine.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            navigationBarBottomLine.leftAnchor.constraint(equalTo: navigationView.leftAnchor),
            navigationBarBottomLine.rightAnchor.constraint(equalTo: navigationView.rightAnchor),
            navigationBarBottomLine.heightAnchor.constraint(equalToConstant: 1)
        ]
        NSLayoutConstraint.activate(constraints)
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
        webView.backgroundColor = UIColor.wkrBackgroundColor

        let constraints: [NSLayoutConstraint] = [
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leftAnchor.constraint(equalTo: view.leftAnchor),
            progressView.rightAnchor.constraint(equalTo: view.rightAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3)
        ]
        NSLayoutConstraint.activate(constraints)

        gameManager.webView = webView
    }

    // MARK: - Alerts

    func quitAlertController(raceStarted: Bool) -> UIAlertController {
        let message = "Are you sure you want to quit?"

        let alertController = UIAlertController(title: "Quit the Race", message: message, preferredStyle: .alert)
        alertController.addCancelAction(title: "Keep Playing")

        if raceStarted {
            let forfeitAction = UIAlertAction(title: "Forfeit Race", style: .default) {  [weak self] _ in
                PlayerMetrics.log(event: .userAction("quitAlertController:forfeit"))
                PlayerMetrics.log(event: .forfeited, attributes: ["Page": self?.finalPage?.title as Any])
                self?.gameManager.player(.forfeited)
            }
            alertController.addAction(forfeitAction)

            let reloadAction = UIAlertAction(title: "Reload Page", style: .default) { _ in
                PlayerMetrics.log(event: .userAction("quitAlertController:reload"))
                PlayerMetrics.log(event: .usedReload)
                self.webView.reload()
            }
            alertController.addAction(reloadAction)
        }

        let quitAction = UIAlertAction(title: "Quit Race", style: .destructive) {  [weak self] _ in
            PlayerMetrics.log(event: .userAction("quitAlertController:quit"))
            PlayerMetrics.log(event: .quitRace, attributes: ["View": self?.activeViewController?.description as Any])
            self?.playerQuit()
        }
        alertController.addAction(quitAction)

        return alertController
    }

    func playerQuit() {
        DispatchQueue.main.async {
            self.isPlayerQuitting = true
            self.resetActiveControllers()
            self.gameManager.player(.quit)
            NotificationCenter.default.post(name: NSNotification.Name.localPlayerQuit, object: nil)
        }
    }

}
