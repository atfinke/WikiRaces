//
//  GKHelper.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import GameKit
import WKRUIKit
import os.log

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebaseAnalytics
#endif

class GKHelper: NSObject, GKLocalPlayerListener {

    enum AuthResult {
        case controller(UIViewController)
        case error(Error)
        case isAuthenticated
    }
    
    enum Invite {
        case raceCode(String)
        case gkInvite(GKInvite)
    }

    static let shared = GKHelper()
    static let gkInviteCode = "GKHelper.GKInvite"

    private var pendingInvite: Invite?
    var inviteHandler: ((Invite) -> Void)? {
        didSet {
            pushInviteToHandler()
        }
    }

    private var pendingResult: AuthResult?
    var authHandler: ((AuthResult) -> Void)? {
        didSet {
            pushResultToHandler()
        }
    }
    
    public var isAuthenticated = false

    // MARK: - Initalization -

    private override init() {}

    // MARK: - Handlers -

    private func pushResultToHandler() {
        guard let result = pendingResult, let handler = authHandler else { return }
        DispatchQueue.main.async {
            handler(result)
        }
        pendingResult = nil
    }

    private func pushInviteToHandler() {
        guard let invite = pendingInvite, let handler = inviteHandler else { return }
        DispatchQueue.main.async {
            handler(invite)
        }
        pendingInvite = nil
    }

    // MARK: - Helpers -

    func start() {
        guard !Defaults.isFastlaneSnapshotInstance else {
            return
        }

        DispatchQueue.global().async {
            GKLocalPlayer.local.authenticateHandler = { controller, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.pendingResult = .error(error)
                    } else if let controller = controller {
                        self.pendingResult = .controller(controller)
                    } else if GKLocalPlayer.local.isAuthenticated {
                        self.pendingResult = .isAuthenticated
                        self.isAuthenticated = true
                        
                        GKLocalPlayer.local.unregisterAllListeners()
                        GKLocalPlayer.local.register(self)
                        
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                            WKRUIPlayerImageManager.shared.connected(to: GKLocalPlayer.local, completion: nil)
                        }

                        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                        let playerName = GKLocalPlayer.local.alias
                        Analytics.setUserProperty(playerName, forName: "playerName")
                        #endif
                    } else {
                        fatalError()
                    }
                    self.pushResultToHandler()
                }
            }
        }
    }

    func acceptedInvite(code: String) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, code)
        pendingInvite = .raceCode(code)
        pushInviteToHandler()
    }
    
    func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        pendingInvite = .gkInvite(invite)
        pushInviteToHandler()
    }

}
