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

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebaseAnalytics
import FirebaseCrashlytics
#endif

class GKHelper {

    enum AuthResult {
        case controller(UIViewController)
        case error(Error)
        case isAuthenticated
    }

    static let shared = GKHelper()

    private var pendingInvite: String?
    var inviteHandler: ((String) -> Void)? {
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

    // MARK: - Initalization -

    private init() {}

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
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                            WKRUIPlayerImageManager.shared.connected(to: GKLocalPlayer.local, completion: nil)
                        }

                        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                        let playerName = GKLocalPlayer.local.alias
                        Crashlytics.crashlytics().setUserID(playerName)
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
        pendingInvite = code
        pushInviteToHandler()
    }

}
