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

        helpBarButtonItem = WKRUIBarButtonItem(
            systemName: "questionmark",
            target: self,
            action: #selector(helpButtonPressed))

        quitBarButtonItem = WKRUIBarButtonItem(
            systemName: "xmark",
            target: self,
            action: #selector(quitButtonPressed))

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        navigationView.addSubview(navigationBarBottomLine)

        setupElements()
        setupProgressView()

        let constraints: [NSLayoutConstraint] = [
            navigationBarBottomLine.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            navigationBarBottomLine.leftAnchor.constraint(equalTo: navigationView.leftAnchor),
            navigationBarBottomLine.rightAnchor.constraint(equalTo: navigationView.rightAnchor),
            navigationBarBottomLine.heightAnchor.constraint(equalToConstant: 1),

            connectingLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
            connectingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 185),

            activityIndicatorView.topAnchor.constraint(equalTo: connectingLabel.bottomAnchor, constant: 25),
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        navigationController.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Elements

    private func setupElements() {
        navigationBarBottomLine.alpha = 0
        navigationBarBottomLine.translatesAutoresizingMaskIntoConstraints = false

        connectingLabel.translatesAutoresizingMaskIntoConstraints = false
        connectingLabel.alpha = 0.0
        connectingLabel.text = "PREPARING"
        connectingLabel.textAlignment = .center
        connectingLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        view.addSubview(connectingLabel)

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.alpha = 0.0
        activityIndicatorView.color = .darkText
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)
    }

    private func setupProgressView() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        let constraints: [NSLayoutConstraint] = [
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leftAnchor.constraint(equalTo: view.leftAnchor),
            progressView.rightAnchor.constraint(equalTo: view.rightAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func setupNewWebView() {
        webView?.removeFromSuperview()

        let webView = WKRUIWebView()

        view.addSubview(webView)
        view.bringSubviewToFront(progressView)
        webView.progressView = progressView

        let constraints: [NSLayoutConstraint] = [
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        gameManager.webView = webView
        self.webView = webView
    }

    // MARK: - Alerts

    func quitAlertController(raceStarted: Bool) -> UIAlertController {
        let message = "Are you sure you want to leave the match?"

        let alertController = UIAlertController(title: "Leave the Match?",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addCancelAction(title: "Keep Playing")

        if raceStarted {
            let forfeitAction = UIAlertAction(title: "Forfeit Race", style: .default) {  [weak self] _ in
                PlayerFirebaseAnalytics.log(event: .userAction("quitAlertController:forfeit"))
                PlayerFirebaseAnalytics.log(event: .forfeited, attributes: ["Page": self?.finalPage?.title as Any])
                self?.gameManager.player(.forfeited)
            }
            alertController.addAction(forfeitAction)

            let reloadAction = UIAlertAction(title: "Reload Page", style: .default) { _ in
                PlayerFirebaseAnalytics.log(event: .userAction("quitAlertController:reload"))
                PlayerFirebaseAnalytics.log(event: .usedReload)
                self.webView?.reload()
            }
            alertController.addAction(reloadAction)
        }

        let quitAction = UIAlertAction(title: "Leave Match", style: .destructive) {  [weak self] _ in
            PlayerFirebaseAnalytics.log(event: .userAction("quitAlertController:quit"))
            PlayerFirebaseAnalytics.log(event: .quitRace, attributes: nil)
            self?.attemptQuit()
        }
        alertController.addAction(quitAction)

        return alertController
    }

    func attemptQuit() {
        guard transitionState == TransitionState.none || transitionState == TransitionState.inProgress else {
            return
        }

        if transitionState == .none {
            performQuit()
        } else {
            transitionState = .quitting(.waiting)
        }
    }

    func performQuit() {
        transitionState = .quitting(.inProgress)
        resetActiveControllers()
        gameManager.player(.quit)
        NotificationCenter.default.post(name: NSNotification.Name.localPlayerQuit,
                                        object: nil)
    }

}
