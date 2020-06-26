//
//  RaceCodeGenerator.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit

class RaceCodeGenerator {
    
    private static let _codes = ["Andrew", "Hello2"]
    private var callback: ((String) -> Void)?
    
    func new(code: @escaping ((String) -> Void)) {
        callback = code
        checkCode()
    }
    
    private func checkCode() {
        print(#function)
        guard let code = RaceCodeGenerator._codes.randomElement else { fatalError() }
        GKMatchmaker.shared().queryPlayerGroupActivity(code.hash) { [weak self] count, error in
            print(count)
            print(error)
            if count == 0 && error == nil {
                self?.callback?(code)
            } else {
                self?.checkCode()
            }
        }
    }
}
