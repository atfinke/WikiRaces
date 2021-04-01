//
//  PreRaceHostSelectionViewController+Selection.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import os.log

extension PreRaceHostSelectionViewController {
    
    func determineBestHostBasedOnNetwork(attempt: Int) {
        assert(Thread.isMainThread)
        os_log("%{public}s: started (%{public}ld)", log: .gameKit, type: .info, #function, attempt)
        if view.window == nil && attempt != 1 {
            os_log("%{public}s: window gone", log: .gameKit, type: .info, #function)
            return
        }
        
        if attempt == 1 {
            PlayerFirebaseAnalytics.log(event: .hostSelectionNeededOneAttempt)
        } else if attempt == 2 {
            PlayerFirebaseAnalytics.log(event: .hostSelectionNeededTwoAttempts)
        }
        
        let chooseBestPlayerStartDate = Date()
        
        var determinationTookTooLong = false
        
        var progressDelayMS = 0
        var textDelayMS = 0
        if attempt == 1 {
            if case Destination.joinStandard = destination {
                progressDelayMS = 4000
            } else if case Destination.joinCustom = destination {
                textDelayMS = 500
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(progressDelayMS)) {
            self.model.startedFindingHostBasedOnConnection(attempt: attempt)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(textDelayMS)) {
            self.model.title = "connecting to racers"
            self.model.progressDisplayState = .progress
        }
        
        isHostVoteProcessingNeeded = true
        match.chooseBestHostingPlayer { [weak self] player in
            guard let self = self else { return }
            guard !determinationTookTooLong, let hostAlias = player?.alias, let hostAliasData = hostAlias.data(using: .utf8) else {
                os_log("%{public}s: failed, t:%{public}ld", log: .gameKit, type: .error, #function, -Int(chooseBestPlayerStartDate.timeIntervalSinceNow))
                return
            }
            self.receivedHostAliasVotes.append(hostAlias)
            
            os_log("%{public}s: found best host: %{public}s, t:%{public}ld", log: .gameKit, type: .error, #function, hostAlias, -Int(chooseBestPlayerStartDate.timeIntervalSinceNow))
            
            self.messenger.send(message: .init(info: .voteForHost, data: hostAliasData))
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(WKRKitConstants.current.maxChooseHostTimeBasedOnConnection)) {
            determinationTookTooLong = true
            os_log("%{public}s: timeout", log: .gameKit, type: .info, #function)
            DispatchQueue.main.async {
                self.determineBestHostBasedOnHostVotes(attempt: attempt)
            }
        }
    }
    
    func determineBestHostBasedOnHostVotes(attempt: Int) {
        os_log("%{public}s: (%{public}ld)", log: .gameKit, type: .info, #function, attempt)
        guard locallyDeterminedHostAlias == nil, receivedHostAlias == nil else {
            os_log("%{public}s: already have host", log: .gameKit, type: .info, #function)
            return
        }
        
        guard !receivedHostAliasVotes.isEmpty else {
            os_log("%{public}s: hostAliasVotes empty, will try again or use names", log: .gameKit, type: .info, #function)
            if attempt < 2 {
                DispatchQueue.main.async {
                    self.determineBestHostBasedOnNetwork(attempt: attempt + 1)
                }
            } else {
                determineBestHostBasedOnName()
            }
            return
        }
        guard isHostVoteProcessingNeeded else {
            os_log("%{public}s: not needed", log: .gameKit, type: .error, #function)
            return
        }
        isHostVoteProcessingNeeded = false
        os_log("%{public}s: counting votes\n%{public}s\n", log: .gameKit, type: .info, #function, receivedHostAliasVotes.description)
        
        let topHostAlias = receivedHostAliasVotes
            .reduce(into: [:]) { counts, number in
                counts[number, default: 0] += 1
            }
            .sorted { (lhs, rhs) -> Bool in
                if lhs.value > rhs.value {
                    return true
                } else if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                } else {
                    return false
                }
            }
            .first
        guard let hostAlias = topHostAlias?.key else {
            fatalError()
        }
        determined(hostAlias: hostAlias)
    }
    
    func determineBestHostBasedOnName() {
        os_log("%{public}s: locallyDeterminedHostAlias: %{public}s, receivedHostAlias: %{public}s", log: .gameKit, type: .info, #function, locallyDeterminedHostAlias ?? "-", receivedHostAlias ?? "-")
        guard locallyDeterminedHostAlias == nil, receivedHostAlias == nil else {
            return
        }
        var players = match.players
        players.append(GKLocalPlayer.local)
        guard let hostAlias = players.sorted(by: { $0.alias > $1.alias }).first?.alias else {
            DispatchQueue.main.async {
                self.setupFailed(reason: .noPlayers)
            }
            return
        }
        determined(hostAlias: hostAlias)
        PlayerFirebaseAnalytics.log(event: .hostSelectionNeededToUseNames)
    }
    
    private func determined(hostAlias: String) {
        locallyDeterminedHostAlias = hostAlias
        os_log("%{public}s: determined host: %{public}s, self = %{public}ld", log: .gameKit, type: .info, #function, hostAlias, isLocalPlayerHost ? 1 : 0)
        
        if isLocalPlayerHost {
            receivedHostAlias = hostAlias
            messenger.send(message: .init(info: .playerIsHost, data: nil))
            
            if let data = try? JSONEncoder().encode(self.receivedSettings) {
                os_log("%{public}s: sent settings", log: .gameKit, type: .info, #function)
                messenger.send(message: .init(info: .settings, data: data))
            } else {
                os_log("%{public}s: failed to encode settings", log: .gameKit, type: .error, #function)
            }
            
            DispatchQueue.main.async {
                let time = WKRKitConstants.current.timeBetweenHostSelectionAndStartMessage
                    + WKRKitConstants.current.timeBetweenHostStartMessageAndRaceStart
                self.model.preparingToStartRace(estimatedTime: time)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(WKRKitConstants.current.timeBetweenHostSelectionAndStartMessage * 1000)), execute: {
                self.messenger.send(message: .init(info: .startMatch, data: nil), completion: { [weak self] success in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(WKRKitConstants.current.timeBetweenHostStartMessageAndRaceStart * 1000)), execute: {
                            self?.transitionToGame()
                        })
                    } else {
                        self?.setupFailed(reason: .matchError)
                    }
                })
            })
            
        }
    }
    
}
