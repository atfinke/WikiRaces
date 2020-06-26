//
//  GameKitMatchmakingViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit

import WKRKit
import WKRUIKit

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
import FirebaseAnalytics
import Crashlytics
#endif

extension GKMatchRequest {
    

    static func hostRequest(raceCode: String, isInital: Bool) -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = isInital ? 2 : GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer) //WKRKitConstants.current.maxGlobalRacePlayers
        request.playerGroup = raceCode.hash
        request.playerAttributes = 0xFFFF0000
        return request
    }
    
    static func joinRequest(raceCode: String?) -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer) //WKRKitConstants.current.maxGlobalRacePlayers
        request.playerGroup = (raceCode ?? "<GLOBAL>").hash
        if raceCode != nil {
            request.playerAttributes = 0x0000FFFF
        }
        return request
    }
    
}


final class GKConnectViewController: ConnectViewController {

    // MARK: - Properties -

    var match: GKMatch?

    let raceCode: String?
    let isPublicRace: Bool
    
    
    
    var isPlayerHost: Bool
    var publicRaceHostAlias: String?
    
    
    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
    var findTrace: Trace?
    #endif
    
    init(raceCode: String?, isPlayerHost: Bool) {
        self.raceCode = raceCode
        self.isPublicRace = raceCode == nil
        self.isPlayerHost = isPlayerHost
        
        Defaults.isAutoInviteOn = true
        
        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        let playerName = GKLocalPlayer.local.alias
        Crashlytics.sharedInstance().setUserName(playerName)
        Analytics.setUserProperty(playerName, forName: "playerName")
        #endif
        
        super.init(nibName: nil, bundle: nil)
        
        onQuit = { [weak self] in
            guard let self = self, let match = self.match else { return }
            match.delegate = nil
            match.disconnect()
        }
        
        setupCoreInterface()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        PlayerAnonymousMetrics.log(event: .userAction("issue#119: viewDidAppear"))

        guard isFirstAppear else {
            return
        }
        isFirstAppear = false
        
        runConnectionTest { [weak self] success in
            guard let self = self else { return }
            if success {
                if self.isPlayerHost {
                    self.toggleCoreInterface(
                        isHidden: true,
                                        duration: 0.25,
                                        completion: { [weak self] in
                                            self?.presentHostInterface()
                    })
                } else {
                    self.findMatch()
                }
            } else if !success {
                self.showConnectionSpeedError()
            }
        }

        toggleCoreInterface(isHidden: false, duration: 0.5)
    }
    
    func presentHostInterface() {
        let controller = HostViewController { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .start(match: let match, settings: let settings):
                self.dismiss(animated: true, completion: { [weak self] in
                    self?.showMatch(for: .gameKit(match: match, isHost: true), settings: settings, andHide: [])
                })
            case .startSolo(settings: let settings):
                self.dismiss(animated: true, completion: { [weak self] in
                    self?.showMatch(for: .solo(name: GKLocalPlayer.local.alias), settings: settings, andHide: [])
                })
            case .cancel:
                self.dismiss(animated: true, completion: {
                    self.navigationController?.popToRootViewController(animated: false)
                })
            }
        }

        let nav = WKRUINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
    }
    
}
