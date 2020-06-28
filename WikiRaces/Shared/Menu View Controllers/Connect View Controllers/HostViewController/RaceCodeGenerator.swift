//
//  RaceCodeGenerator.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit

class RaceCodeGenerator {
    
    private static var codes: [String] = {
        let invalidCharacters = CharacterSet.alphanumerics.inverted
        return WKRKitConstants.current.finalArticles
            .filter { $0.count < 10 }
            .map { String($0.dropFirst()) }
            .filter { $0.rangeOfCharacter(from: invalidCharacters) == nil }
    }()
    private var callback: ((String) -> Void)?
    
    func new(code: @escaping ((String) -> Void)) {
        callback = code
        generate()
    }
    
    // TODO: Switch to CloudKit
    private func generate() {
        print(#function)
        guard let code = RaceCodeGenerator.codes.randomElement else { fatalError() }
        GKMatchmaker.shared().queryPlayerGroupActivity(code.hash) { [weak self] count, error in
            print(count)
            print(error)
            if count == 0 && error == nil {
                self?.callback?(code)
                PlayerAnonymousMetrics.log(event: .revampRaceCodeGenerated)
            } else {
                self?.generate()
                PlayerAnonymousMetrics.log(event: .revampRaceCodeFailure)
            }
        }
    }
}
