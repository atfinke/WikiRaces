//
//  ConnectViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

class ConnectViewController: UIViewController {

    // MARK: - Types -

    struct StartMessage: Codable {
        let hostName: String
        let gameSettings: WKRGameSettings
    }

    // MARK: - Interface Elements -

    /// General status label
    final let descriptionLabel = UILabel()
    /// Activity spinner
    final let activityIndicatorView = UIActivityIndicatorView(style: .large)
    /// The button to cancel joining/creating a race
    final let cancelButton = UIButton()

    final var isFirstAppear = true
    final var isShowingMatch = false
    final var onQuit: (() -> Void)?
    final var isShowingError = false

    // MARK: - Connection -

    final func runConnectionTest(completion: @escaping (Bool) -> Void) {
        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        let trace = Performance.startTrace(name: "Connection Test Trace")
        #endif

        let startDate = Date()
        WKRConnectionTester.start { success in
            DispatchQueue.main.async {
                if success {
                    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                    trace?.stop()
                    #endif
                }
                PlayerAnonymousMetrics.log(event: .connectionTestResult,
                                           attributes: [
                                            "Result": NSNumber(value: success).intValue,
                                            "Duration": -startDate.timeIntervalSinceNow
                ])
                completion(success)
            }
        }
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        WKRSeenFinalArticlesStore.resetRemotePlayersSeenFinalArticles()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        descriptionLabel.alpha = 0.0
        activityIndicatorView.alpha = 0.0
        cancelButton.alpha = 0.0
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let textColor: UIColor = .wkrTextColor(for: traitCollection)
        cancelButton.setTitleColor(textColor, for: .normal)
        descriptionLabel.textColor = textColor
        activityIndicatorView.color = .wkrActivityIndicatorColor(for: traitCollection)
        view.backgroundColor = .wkrBackgroundColor(for: traitCollection)
    }

    // MARK: - Core Interface -

    final func setupCoreInterface() {
        if #available(iOS 13.4, *) {
            cancelButton.isPointerInteractionEnabled = true
        }
        cancelButton.setAttributedTitle(NSAttributedString(string: "CANCEL",
                                                           spacing: 1.5), for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        cancelButton.alpha = 0.0
        cancelButton.addTarget(self, action: #selector(pressedCancelButton), for: .touchUpInside)
        view.addSubview(cancelButton)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.alpha = 0.0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        view.addSubview(descriptionLabel)
        updateDescriptionLabel(to: "CHECKING CONNECTION")

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.alpha = 0.0
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)

        let constraints = [
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    final func toggleCoreInterface(isHidden: Bool,
                                   duration: TimeInterval,
                                   and items: [UIView] = [],
                                   completion: (() -> Void)? = nil) {
        let views = [descriptionLabel, activityIndicatorView, cancelButton] + items
        UIView.animate(withDuration: duration,
                       animations: {
                        views.forEach({ $0.alpha = isHidden ? 0 : 1})
        }, completion: { _ in
            completion?()
        })
    }

    // MARK: - Interface Updates -

    final func updateDescriptionLabel(to text: String) {
        descriptionLabel.attributedText = NSAttributedString(string: text.uppercased(),
                                                             spacing: 2.0,
                                                             font: UIFont.systemFont(ofSize: 20.0, weight: .semibold))
    }

    final func showConnectionSpeedError() {
        showError(title: "Slow Connection",
                  message: "A fast internet connection is required to play WikiRaces.")
    }

    /// Shows an error with a title
    ///
    /// - Parameters:
    ///   - title: The title of the error message
    ///   - message: The message body of the error
    @objc
    func showError(title: String, message: String, showSettingsButton: Bool = false) {
        guard !isShowingError else { return }
        isShowingError = true

        onQuit?()

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Menu", style: .default) { _ in
            self.pressedCancelButton()
        }
        alertController.addAction(action)

        if showSettingsButton, let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            let settingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                PlayerAnonymousMetrics.log(event: .userAction("showError:settings"))
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                self.pressedCancelButton()
            })
            alertController.addAction(settingsAction)
        }

        present(alertController, animated: true, completion: nil)
    }

    /// Cancels the join/create a race action and sends player back to main menu
    @objc
    final func pressedCancelButton() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        onQuit?()

        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            self.navigationController?.popToRootViewController(animated: false)
        })
    }

    final func showMatch(for networkConfig: WKRPeerNetworkConfig,
                         settings: WKRGameSettings,
                         andHide views: [UIView]) {

        guard !isShowingError else { return }
        isShowingError = true

        guard !isShowingMatch else { return }
        isShowingMatch = true

        DispatchQueue.main.async {
            self.toggleCoreInterface(
                isHidden: true,
                duration: 0.25,
                and: views,
                completion: {
                    let controller = GameViewController(network: networkConfig, settings: settings)
                    let nav = WKRUINavigationController(rootViewController: controller)
                    nav.modalPresentationStyle = .fullScreen
                    nav.modalTransitionStyle = .crossDissolve
                    nav.isModalInPresentation = true
                    self.present(nav, animated: true, completion: nil)
            })
        }
    }
}
