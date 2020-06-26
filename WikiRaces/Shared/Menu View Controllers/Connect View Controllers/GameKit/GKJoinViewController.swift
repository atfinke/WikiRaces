//
//  GKJoinViewController.swift
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

final class GKJoinViewController: ConnectViewController {

    // MARK: - Properties -

    var match: GKMatch?

    let raceCode: String?
    let isPublicRace: Bool
    var publicRaceHostAlias: String?
    
    var isPlayerHost = false
    
    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
    var findTrace: Trace?
    #endif
    
    init(raceCode: String?) {
        self.raceCode = raceCode
        self.isPublicRace = raceCode == nil
        
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
                self.findMatch()
            } else if !success {
                self.showConnectionSpeedError()
            }
        }
        toggleCoreInterface(isHidden: false, duration: 0.5)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GKMatchmaker.shared().cancel()
    }
}
