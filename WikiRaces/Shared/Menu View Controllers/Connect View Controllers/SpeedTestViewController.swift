//
//  SpeedTestViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/27/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import SwiftUI
import WKRKit

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

final class SpeedTestViewController: VisualEffectViewController {

    // MARK: - Types -

    enum Destination {
        case joinPrivate(raceCode: String), joinPublic, hostPrivate
    }

    // MARK: - Properties -

    let startDate = Date()
    let destination: Destination
    final var model = LoadingContentViewModel()
    final lazy var contentViewHosting = UIHostingController(
        rootView: LoadingContentView(model: model, cancel: { [weak self] in
            self?.cancel()
        }))

    // MARK: - Initalization -

    init(destination: Destination) {
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
        model.title = "Checking Connection"
        view.alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(hostingView: contentViewHosting.view)

        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        let trace = Performance.startTrace(name: "Connection Test Trace")
        #endif

        let startDate = Date()
        WKRConnectionTester.start { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                    trace?.stop()
                    #endif
                    self.success()
                } else {
                    GKNotificationBanner.show(
                        withTitle: "Slow Connection",
                        message: "A fast internet connection is required to play WikiRaces.",
                        completionHandler: nil)
                    self.model.title = "connection issue"
                    self.model.activityOpacity = 0
                }
                PlayerAnonymousMetrics.log(event: .connectionTestResult,
                                           attributes: [
                                            "Result": NSNumber(value: success).intValue,
                                            "Duration": -startDate.timeIntervalSinceNow
                                           ])
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.view.alpha = 1
        }
    }

    // MARK: - Helpers -

    final func cancel() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.alpha = 0
        }, completion: { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: false)
        })
    }

    final func success() {
        let delay = max(0, 2 - (-startDate.timeIntervalSinceNow))
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(delay * 1000))) {
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.contentViewHosting.view.alpha = 0
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                switch self.destination {
                case .joinPrivate(let raceCode):
                    self.navigationController?.pushViewController(GKJoinViewController(raceCode: raceCode), animated: false)
                case .joinPublic:
                    self.navigationController?.pushViewController(GKJoinViewController(raceCode: nil), animated: false)
                case .hostPrivate:
                    self.navigationController?.pushViewController(GKHostViewController(), animated: false)
                }
            })
        }
    }

}
