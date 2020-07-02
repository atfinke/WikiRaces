//
//  RaceChecksViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/27/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import SwiftUI
import WKRKit
import os.log

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

final class RaceChecksViewController: VisualEffectViewController {
    
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
        }, disclaimerButton: {
            UIApplication.shared.open(WKRKitConstants.current.manageGameCenterLink)
        }))
    
    // MARK: - Initalization -
    
    init(destination: Destination) {
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
        model.title = "Checking Connection"
        model.disclaimerButtonTitle = "Manage Game Center"
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
                    os_log("%{public}s: connection success: %{public}f", log: .matchSupport, type: .info, #function, -startDate.timeIntervalSinceNow)
                    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                    trace?.stop()
                    #endif
                    self.connectionSuccess()
                } else {
                    os_log("%{public}s: connection error", log: .matchSupport, type: .error, #function)
                    GKNotificationBanner.show(
                        withTitle: "Slow Connection",
                        message: "A faster internet connection is required",
                        completionHandler: nil)
                    self.model.title = "connection issue"
                    self.model.activityOpacity = 0
                }
                PlayerAnonymousMetrics.log(
                    event: .connectionTestResult,
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
    
    final func connectionSuccess() {
        let startDate = Date()
        let isAuthenticated = GKLocalPlayer.local.isAuthenticated
        if !isAuthenticated {
            self.model.title = "WAITING FOR GAME CENTER"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            while !GKLocalPlayer.local.isAuthenticated {
                if -startDate.timeIntervalSinceNow > 8 && self.model.disclaimerButtonOpacity == 0 {
                    DispatchQueue.main.async {
                        self.model.disclaimerButtonOpacity = 1
                    }
                }
                sleep(2)
            }
            
            // Give Game Center more time to get its act together
            if !isAuthenticated {
                sleep(2)
            }
            
            DispatchQueue.main.async {
                self.model.disclaimerButtonOpacity = 0
            }
            
            DispatchQueue.main.async {
                self.readyForNextMatchmakingStep()
            }
        }
    }
    
    func readyForNextMatchmakingStep() {
        let shouldFadeAlpha: Bool
        let controller: UIViewController
        switch self.destination {
        case .joinPrivate(let raceCode):
            shouldFadeAlpha = false
            controller = GKJoinViewController(raceCode: raceCode)
        case .joinPublic:
            shouldFadeAlpha = false
            controller = GKJoinViewController(raceCode: nil)
        case .hostPrivate:
            shouldFadeAlpha = true
            controller = GKHostViewController()
        }
        
        let delay = max(0, 2 - (-self.startDate.timeIntervalSinceNow))
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(delay * 1000))) {
            UIView.animate(withDuration: 0.5, animations: { [weak self] in
                self?.contentViewHosting.view.alpha = shouldFadeAlpha ? 0 : 1
            }, completion: { [weak self] _ in
                self?.navigationController?.pushViewController(controller, animated: false)
            })
        }
    }

    
}
