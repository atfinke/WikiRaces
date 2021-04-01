//
//  PreRaceConnectionTestViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//


import GameKit
import WKRKit
import WKRUIKit
import os.log

final class PreRaceConnectionTestViewController: PreRaceViewController {

    // MARK: - Properties -

    private var isViewDisplayed = false

    // MARK: - Initalization -

    override init(destination: Destination) {
        super.init(destination: destination)
        model.title = "Checking Connection"
        model.disclaimerButtonTitle = "Manage Game Center"
        model.progressDisplayState = GKHelper.shared.isAuthenticated ? .progress : .spinner
        view.alpha = 0
        
        switch destination {
        case .hostCustom:
            PlayerFirebaseAnalytics.log(event: .raceDestinationHostCustom)
        case .joinCustom:
            PlayerFirebaseAnalytics.log(event: .raceDestinationJoinCustom)
        case .joinStandard(let invite):
            if invite == nil {
                PlayerFirebaseAnalytics.log(event: .raceDestinationJoinStandardPublic)
            } else {
                PlayerFirebaseAnalytics.log(event: .raceDestinationJoinStandardInvite)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        model.startedConnectionTest()
        let startDate = Date()
        WKRConnectionTester.start { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    os_log("%{public}s: connection success: %{public}f", log: .matchSupport, type: .info, #function, -startDate.timeIntervalSinceNow)
                    self.connectionSuccess()
                } else {
                    os_log("%{public}s: connection error", log: .matchSupport, type: .error, #function)
                    GKNotificationBanner.show(
                        withTitle: "Slow Connection",
                        message: "A faster internet connection is required",
                        completionHandler: nil)
                    self.model.title = "connection issue"
                    self.model.progressDisplayState = .none
                }
                PlayerFirebaseAnalytics.log(
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
        os_log("%{public}s: (PreRaceConnectionTestViewController)", log: .gameKit, type: .info, #function)
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.alpha = 1
        }, completion: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                os_log("%{public}s: (PreRaceConnectionTestViewController) isViewDisplayed", log: .gameKit, type: .info, #function)
                self?.isViewDisplayed = true
            })
        })
    }

    // MARK: - Helpers -

    final func connectionSuccess() {
        let isAuthenticated = GKHelper.shared.isAuthenticated
        os_log("%{public}s: isAuthenticated: %{public}s", log: .gameKit, type: .info, #function, isAuthenticated.description)
        let startDate = Date()
        if isAuthenticated {
            if isViewDisplayed {
                model.finishedConnectionTest()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.model.finishedConnectionTest()
                }
            }
        } else {
            model.title = "WAITING FOR GAME CENTER"
            model.progressDisplayState = .spinner
        }

        DispatchQueue.global(qos: .userInitiated).async {
            while !GKHelper.shared.isAuthenticated {
                os_log("%{public}s: not auth", log: .gameKit, type: .info, #function)
                if -startDate.timeIntervalSinceNow > 8 && self.model.disclaimerButtonOpacity == 0 {
                    os_log("%{public}s: showing help button", log: .gameKit, type: .info, #function)
                    DispatchQueue.main.async {
                        self.model.disclaimerButtonOpacity = 1
                    }
                }
                sleep(2)
            }

            // Give Game Center more time to get its act together
            if !isAuthenticated {
                os_log("%{public}s: wasn't auth, giving more time", log: .gameKit, type: .info, #function)
                sleep(2)
            }
            
            // manually call bc the game center auth handler doesn't get called sometimes
            WKRUIPlayerImageManager.shared.connected(to: GKLocalPlayer.local, completion: {
                DispatchQueue.main.async { [weak self] in
                    self?.model.disclaimerButtonOpacity = 0
                    self?.readyForNextMatchmakingStep()
                }
            })
        }
    }

    func readyForNextMatchmakingStep() {
        os_log("%{public}s: (PreRaceConnectionTestViewController)", log: .gameKit, type: .info, #function)
        
        DispatchQueue.global().async {
            while !self.isViewDisplayed {
                sleep(1)
            }
            DispatchQueue.main.async {
                
                let controller: UIViewController
                switch self.destination {
                case .hostCustom:
                    controller = GKHostViewController()
                case .joinCustom, .joinStandard:
                    controller = PreRaceJoinStandardViewController(destination: self.destination)
                }
                
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    self?.contentViewHosting.view.alpha = 0
                }, completion: { [weak self] _ in
                    self?.navigationController?.pushViewController(controller, animated: false)
                })
            }
        }
        
    }

}
