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
    private var isCancelled = false
    private var attempts = 0
    private var newStartDate = Date()

    func new(code: @escaping ((String) -> Void)) {
        os_log("RaceCodeGenerator: %{public}s", log: .matchSupport, type: .info, #function)
        callback = code
        attempts = 0
        newStartDate = Date()
        generate()
    }

    func cancel() {
        os_log("RaceCodeGenerator: %{public}s", log: .matchSupport, type: .info, #function)
        callback = nil
        isCancelled = true
    }

    // TODO: Switch to CloudKit
    private func generate() {
        guard !isCancelled else { return }
        attempts += 1

        guard let code = RaceCodeGenerator.codes.randomElement else { fatalError() }
        os_log("RaceCodeGenerator: %{public}s: %{public}s", log: .matchSupport, type: .info, #function, code)

        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        let traceGK = Performance.startTrace(name: "Race Code Trace: queryPlayerGroupActivity")
        let traceTotal = Performance.startTrace(name: "Race Code Trace: Total Success Time")
        #endif

        let queryCheckStartDate = Date()
        GKMatchmaker.shared().queryPlayerGroupActivity(RaceCodeGenerator.playerGroup(for: code)) { [weak self] count, error in
            if count == 0 && error == nil {
                os_log("RaceCodeGenerator: %{public}s: queryPlayerGroupActivity success in %{public}f", log: .matchSupport, type: .info, #function, -queryCheckStartDate.timeIntervalSinceNow)
                PlayerFirebaseAnalytics.log(event: .raceCodeGKSuccess)

                guard let self = self, !self.isCancelled else { return }
                PlayerCloudKitLiveRaceManager.shared.isRaceCodeValid(raceCode: code, host: GKLocalPlayer.local.alias) { result in
                    switch result {
                    case .valid:
                        self.callback?(code)
                        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                        traceTotal?.stop()
                        #endif
                        PlayerFirebaseAnalytics.log(event: .raceCodeGenerationFinished, attributes: [
                            "attempts": self.attempts,
                            "duration": -self.newStartDate.timeIntervalSinceNow
                        ])
                    case .invalid:
                        self.generate()
                    case .noiCloudAccount:
                        #if targetEnvironment(simulator)
                        self.callback?(code)
                        #endif
                        break
                    }
                }
            } else {
                os_log("RaceCodeGenerator: %{public}s: queryPlayerGroupActivity failed, count: %{public}ld, error: %{public}s", log: .matchSupport, type: .info, #function, count, error?.localizedDescription ?? "-")
                self?.generate()
                PlayerFirebaseAnalytics.log(event: .raceCodeGKFailed)
            }
            #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
            traceGK?.stop()
            #endif
        }
    }

    static func playerGroup(for raceCode: String) -> Int {
        guard raceCode.count < 10 else { return -1 }

        let formattedCode = raceCode.lowercased()
        var playerGroup = formattedCode.count + 1 // + X == force version compatibility due to App Store Connect being broken
        for (index, char) in formattedCode.enumerated() {
            let charValue: Int = (validCharactersArray.firstIndex(of: char) ?? 50) + 1
            let offset = Int(pow(Double(10), Double(index * 2) + 1))
            playerGroup += offset * charValue
        }

        os_log("%{public}s: %{public}s -> %{public}ld", log: .matchSupport, type: .info, #function, raceCode, playerGroup)
        return playerGroup
    }
}
