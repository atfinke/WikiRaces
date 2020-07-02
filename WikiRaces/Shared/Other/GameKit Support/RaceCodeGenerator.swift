//
//  RaceCodeGenerator.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import os.log

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

class RaceCodeGenerator {

    private static let validCharacters = "abcdefghijklmnopqrstuvwxyz"
    private static let validCharactersSet = CharacterSet(charactersIn: validCharacters)
    private static let validCharactersArray = validCharacters.map { $0 }

    private(set) static var codes: [String] = {
        let invalidCharacters = CharacterSet.alphanumerics.inverted
        return WKRKitConstants.current.finalArticles
            .filter { $0.count < 10 }
            .map { String($0.dropFirst()).lowercased() }
            .filter { validCharactersSet.isSuperset(of: CharacterSet(charactersIn: $0)) }
    }()
    private var callback: ((String) -> Void)?

    func new(code: @escaping ((String) -> Void)) {
        os_log("%{public}s", log: .matchSupport, type: .info, #function)
        callback = code
        generate()
    }

    // TODO: Switch to CloudKit
    private func generate() {
        guard let code = RaceCodeGenerator.codes.randomElement else { fatalError() }
        os_log("%{public}s: %{public}s", log: .matchSupport, type: .info, #function, code)

        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        let traceGK = Performance.startTrace(name: "Race Code Trace: queryPlayerGroupActivity")
        let traceTotal = Performance.startTrace(name: "Race Code Trace: Total Success Time")
        #endif
        
        let date = Date()
        GKMatchmaker.shared().queryPlayerGroupActivity(code.hash) { [weak self] count, error in
            if count == 0 && error == nil {
                os_log("%{public}s: queryPlayerGroupActivity success in %{public}f", log: .matchSupport, type: .info, #function, -date.timeIntervalSinceNow)
                PlayerAnonymousMetrics.log(event: .revampRaceCodeGKSuccess)
                PlayerDatabaseLiveRace.shared.isRaceCodeValid(raceCode: code, host: GKLocalPlayer.local.alias) { result in
                    switch result {
                    case .valid:
                        self?.callback?(code)
                        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                        traceTotal?.stop()
                        #endif
                    case .invalid:
                        self?.generate()
                    case .noiCloudAccount:
                        #if targetEnvironment(simulator)
                        self?.callback?(code)
                        #endif
                        break
                    }
                }
            } else {
                os_log("%{public}s: queryPlayerGroupActivity failed, count: %{public}ld, error: %{public}s", log: .matchSupport, type: .info, #function, count, error?.localizedDescription ?? "-")
                self?.generate()
                PlayerAnonymousMetrics.log(event: .revampRaceCodeGKFailed)
            }
            #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
            traceGK?.stop()
            #endif
        }
    }
    
    static func playerGroup(for raceCode: String) -> Int {
        assert(raceCode.count < 10)
        let formattedCode = raceCode.lowercased()
        var playerGroup = formattedCode.count
        for (index, char) in formattedCode.enumerated() {
            let charValue: Int = (validCharactersArray.firstIndex(of: char) ?? 50) + 1
            let offset = Int(pow(Double(10), Double(index * 2) + 1))
            playerGroup += offset * charValue
        }
        
        os_log("%{public}s: %{public}s -> %{public}ld", log: .matchSupport, type: .info, #function, raceCode, playerGroup)
        return playerGroup
    }
}
