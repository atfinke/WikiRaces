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
        
        let date = Date()
        GKMatchmaker.shared().queryPlayerGroupActivity(code.hash) { [weak self] count, error in
            if count == 0 && error == nil {
                os_log("%{public}s: success %{public}f", log: .matchSupport, type: .info, #function, -date.timeIntervalSinceNow)
                self?.callback?(code)
                PlayerAnonymousMetrics.log(event: .revampRaceCodeGenerated)
            } else {
                os_log("%{public}s: count: %{public}ld, error: %{public}s", log: .matchSupport, type: .info, #function, count, error?.localizedDescription ?? "-")
                self?.generate()
                PlayerAnonymousMetrics.log(event: .revampRaceCodeFailure)
            }
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
