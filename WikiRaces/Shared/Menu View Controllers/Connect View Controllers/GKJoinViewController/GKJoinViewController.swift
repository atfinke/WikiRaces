//
//  GKJoinViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit
import SwiftUI
import os.log

import WKRKit
import WKRUIKit

final class GKJoinViewController: GKConnectViewController, GKMatchmakerViewControllerDelegate {
    
    // MARK: - Types -
    
    struct PublicRaceHostVoteMessage: Codable {
        let hostName: String
    }
    
    // MARK: - Properties -
    
    let raceCode: String?
    
    let isPublicRace: Bool
    var publicRaceHostAlias: String?
    
    var model = LoadingContentViewModel()
    lazy var contentViewHosting = UIHostingController(
        rootView: LoadingContentView(model: model, cancel: { [weak self] in
            self?.isShowingError = true
            self?.cancelMatch()
            }, disclaimerButton: nil))
    
    var matchmaker: GKMatchmakerViewController?
    
    var publicRaceHostVoteMessages = [PublicRaceHostVoteMessage]()
    var isPublicRaceHostVoteMessageProcessingNeeded = true
    
    // MARK: - Initalization -
    
    init(raceCode: String?) {
        self.raceCode = raceCode
        self.isPublicRace = raceCode == nil
        super.init(isPlayerHost: false)
        
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        
        
        if !isPublicRace {
            joinMatch()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(hostingView: contentViewHosting.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isPublicRace, matchmaker == nil {
            if let invite = GKHelper.shared._invite {
                GKHelper.shared._invite = nil
                matchmaker = GKMatchmakerViewController(invite: invite)
            } else {
                matchmaker = GKMatchmakerViewController(matchRequest: GKMatchRequest.joinRequest(raceCode: raceCode))
            }
            matchmaker?.matchmakingMode = .default
            matchmaker?.matchmakerDelegate = self
            if let matchmaker = matchmaker {
                present(matchmaker, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - GKMatchmakerViewControllerDelegate -
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        self.view.alpha = 0.0
        viewController.dismiss(animated: true, completion: {
            self.navigationController?.popToRootViewController(animated: false)
        })
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        viewController.dismiss(animated: true, completion: nil)
        
        DispatchQueue.main.async {
            let bannerTitle: String
            let interfaceTitle: String
            if self.isPublicRace {
                bannerTitle = "Unable To Find Race"
                interfaceTitle = "NO OPEN RACES"
            } else {
                bannerTitle = "Unable To Join Race"
                interfaceTitle = "MATCHMAKING ISSUE"
            }
            self.showError(title: bannerTitle, message: "Please try again later.")
            self.model.title = interfaceTitle
            self.model.activityOpacity = 0
        }
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        os_log("%{public}s: expectedPlayerCount: %{public}i", log: .gameKit, type: .info, #function, match.expectedPlayerCount)
        
        self.match = match
        match.delegate = self
        
        DispatchQueue.main.async {
            self.model.title = ""
            self.model.activityOpacity = 0
        }
        
        DispatchQueue.global().async {
            while match.expectedPlayerCount != 0 {
                sleep(1)
            }
            self.publicRaceDetermineHost(match: match)
        }
    }
    
    // MARK: - Helpers -
    
    func joinMatch() {
        os_log("%{public}s: race code: %{public}s", log: .gameKit, type: .info, #function, raceCode ?? "-")
        
        DispatchQueue.main.async {
            if self.raceCode == nil {
                self.model.title = "searching for race"
            } else {
                self.model.title = "joining race"
            }
        }
        
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.joinRequest(raceCode: raceCode)) { [weak self] match, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error != nil || match == nil {
                    os_log("%{public}s: result: error: %{public}s", log: .gameKit, type: .error, #function, error?.localizedDescription ?? "-")
                    
                    let bannerTitle: String
                    let interfaceTitle: String
                    if self.isPublicRace {
                        bannerTitle = "Unable To Find Race"
                        interfaceTitle = "NO OPEN RACES"
                    } else {
                        bannerTitle = "Unable To Join Race"
                        interfaceTitle = "MATCHMAKING ISSUE"
                    }
                    self.showError(title: bannerTitle, message: "Please try again later.")
                    self.model.title = interfaceTitle
                    self.model.activityOpacity = 0
                } else if let match = match {
                    os_log("%{public}s: found match", log: .gameKit, type: .info, #function)
                    
                    self.match = match
                    match.delegate = self
                    
                    if self.isPublicRace {
                        self.publicRaceDetermineHost(match: match)
                    }
                }
            }
        }
    }
}
