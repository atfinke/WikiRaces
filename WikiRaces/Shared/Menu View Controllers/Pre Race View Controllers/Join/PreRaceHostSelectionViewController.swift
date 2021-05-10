//
//  PreRaceHostSelectionViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import WKRUIKit
import os.log

class PreRaceHostSelectionViewController: PreRaceViewController, GKMatchDelegate {
    
    
    var isSetupRunning = true
    
    enum SetupFailureReason: String {
        case receivedStartRaceWhenHost, receivedHostWhenHost, hostCancelled, pressedCancelButton, noPlayers, matchError
    }
    
    let match: GKMatch
    let messenger: PreRaceMessenger
    
    var receivedSettings = WKRGameSettings()
    
    var receivedHostAliasVotes = [String]()
    var receivedHostAlias: String?
    var locallyDeterminedHostAlias: String?
    var isHostVoteProcessingNeeded = true
    var isLocalPlayerHost: Bool {
        return locallyDeterminedHostAlias == GKLocalPlayer.local.alias
    }
    
    init(match: GKMatch, destination: PreRaceViewController.Destination) {
        os_log("%{public}s: (PreRaceHostSelectionViewController)", log: .gameKit, type: .info, #function)
        self.match = match
        self.messenger = PreRaceMessenger(match: match)
        super.init(destination: destination)
        
        match.delegate = self
        view.alpha = 0
        
        if case Destination.joinCustom = destination {
            model.title = "waiting for host"
            model.progressDisplayState = .spinner
        } else {
            model.title = "connecting to racers"
            model.progressDisplayState = .progress
        }
        
        switch destination {
        case .joinStandard:
            determineBestHostBasedOnNetwork(attempt: 1)
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.alpha = 1
        })
    }
    
    override func cancel() {
        DispatchQueue.main.async {
            self.setupFailed(reason: .pressedCancelButton)
        }
        super.cancel()
    }
    
    func startCustomRaceHostDetermination(with settings: WKRGameSettings) {
        messenger.send(message: .init(info: .customMatchStartHostDetermination, data: nil))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.determineBestHostBasedOnNetwork(attempt: 1)
        }
        
        guard let data = try? JSONEncoder().encode(settings) else {
            os_log("%{public}s: failed to encode settings", log: .gameKit, type: .error, #function)
            return
        }
        receivedSettings = settings
        messenger.send(message: .init(info: .settings, data: data))
    }
    
    // MARK: - Match State -
    
    func setupFailed(reason: SetupFailureReason) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .error, #function, reason.rawValue)
        assert(Thread.isMainThread)
        
        guard isSetupRunning else { return }
        isSetupRunning = false
        
        switch reason {
        case .receivedStartRaceWhenHost, .receivedHostWhenHost, .matchError:
            PlayerFirebaseAnalytics.log(event: .globalFailedToFindHost)
            model.title = "Race Canceled"
            model.progressDisplayState = .none
            GKNotificationBanner.show(withTitle: "Game Center Issue",
                                      message: "There was an issue setting up the race",
                                      completionHandler: nil)
            PlayerFirebaseAnalytics.log(event: .hostSelectionFailed)
        case .hostCancelled:
            model.title = "Host Canceled Race"
            model.progressDisplayState = .none
            GKNotificationBanner.show(withTitle: "Game Center Issue",
                                      message: "The host canceled the race",
                                      completionHandler: nil)
        case .pressedCancelButton:
            if isLocalPlayerHost {
                messenger.send(message: .init(info: .hostCancelled, data: nil))
            }
            break
        case .noPlayers:
            model.title = "Race Canceled"
            model.progressDisplayState = .none
            GKNotificationBanner.show(withTitle: "Game Center Issue",
                                      message: "No ideal host found",
                                      completionHandler: nil)
        }
        
        match.delegate = nil
        match.disconnect()
    }
    
    func transitionToGame() {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        assert(Thread.isMainThread)
        
        guard isSetupRunning else { return }
        isSetupRunning = false
        
        let config: WKRPeerNetworkConfig
        switch destination {
        case .hostCustom, .joinCustom:
            config = .gameKitPrivate(match: match, isHost: isLocalPlayerHost)
        case .joinStandard(let invite):
            if invite != nil {
                config = .gameKitPrivate(match: match, isHost: isLocalPlayerHost)
            } else {
                config = .gameKitPublic(match: match, isHost: isLocalPlayerHost)
            }
        }
        
        let controller = GameViewController(network: config, settings: receivedSettings)
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        nav.isModalInPresentation = true
        
        present(nav, animated: true, completion: { [weak self] in
            self?.view.alpha = 0
        })
        
        PlayerFirebaseAnalytics.log(event: .hostSelectionSucceeded)
    }
    
    // MARK: - GKMatchDelegate -
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        os_log("%{public}s: player: %{public}s, state: %{public}ld", log: .gameKit, type: .info, #function, player.alias, state.rawValue)
        guard state == .connected else { return }
        WKRUIPlayerImageManager.shared.connected(to: player, completion: nil)
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .error, #function, error?.localizedDescription ?? "-")
        DispatchQueue.main.async {
            self.setupFailed(reason: .matchError)
        }
    }
    
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        guard let message = try? JSONDecoder().decode(PreRaceMessenger.Message.self, from: data) else {
            os_log("%{public}s: unknown data: %{public}s", log: .gameKit, type: .error, #function, String(data: data, encoding: .utf8) ?? "-")
            
            return
        }
        os_log("%{public}s: %{public}s (sender: %{public}s)", log: .gameKit, type: .info, #function, message.info.rawValue, player.alias)
        
        switch message.info {
        case .hostCancelled:
            DispatchQueue.main.async {
                self.setupFailed(reason: .hostCancelled)
            }
        case .customMatchStartHostDetermination:
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.4) {
                    self.contentViewHosting.view.alpha = 0
                } completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.5, delay: 0.2) {
                        self?.contentViewHosting.view.alpha = 1
                    }
                }
                self.determineBestHostBasedOnNetwork(attempt: 1)
            }
        case .voteForHost:
            guard let data = message.data, let hostAlias = String(data: data, encoding: .utf8) else {
                os_log("%{public}s: failed to decode hostAlias", log: .gameKit, type: .error, #function)
                return
            }
            receivedHostAliasVotes.append(hostAlias)
            let playerCount = match.players.count + 1
            os_log("%{public}s: processed: %{public}ld/%{public}ld", log: .gameKit, type: .info, #function, receivedHostAliasVotes.count, playerCount)
            if receivedHostAliasVotes.count == playerCount {
                determineBestHostBasedOnHostVotes(attempt: 1)
            }
        case .playerIsHost:
            receivedHostAlias = player.alias
            os_log("%{public}s: receivedHostAlias", log: .gameKit, type: .info, #function, receivedHostAlias ?? "-")
            
            guard !isLocalPlayerHost else {
                DispatchQueue.main.async {
                    self.setupFailed(reason: .receivedHostWhenHost)
                }
                return
            }
            DispatchQueue.main.async {
                self.model.preparingToStartRace(estimatedTime: WKRKitConstants.current.timeBetweenHostSelectionAndStartMessage)
            }
        case .settings:
            guard let settings = try? JSONDecoder().decode(WKRGameSettings.self, from: message.data ?? Data()) else {
                os_log("%{public}s: settings failed to decode", log: .gameKit, type: .error, #function)
                return
            }
            os_log("%{public}s: settings decoded successfully", log: .gameKit, type: .info, #function)
            self.receivedSettings = settings
        case .articles:
            guard isLocalPlayerHost else {
                return
            }
            guard let data = message.data, WKRSeenFinalArticlesStore.isRemoteTransferData(data) else {
                os_log("%{public}s: bad data", log: .gameKit, type: .error, #function)
                return
            }
            WKRSeenFinalArticlesStore.addRemoteTransferData(data)
        case .startMatch:
            DispatchQueue.main.async {
                guard !self.isLocalPlayerHost else {
                    os_log("%{public}s: startMatch from player but local was host, got: %{public}s", log: .gameKit, type: .info, #function, player.alias)
                    self.setupFailed(reason: .receivedStartRaceWhenHost)
                    return
                }
                if let data = WKRSeenFinalArticlesStore.encodedLocalPlayerSeenFinalArticles() {
                    os_log("%{public}s: encoded seen articles", log: .gameKit, type: .info, #function)
                    self.messenger.send(message: .init(info: .articles, data: data), toPlayer: player)
                }
                self.transitionToGame()
            }
        }
    }
    
}
