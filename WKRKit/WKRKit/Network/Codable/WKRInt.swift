//
//  WKRInt.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRInt: Codable {

    enum WKRIntType: Int, Codable {
        case votingTime
        case resultsTime
        case bonusPoints
    }

    let type: WKRIntType
    let value: Int

    init(type: WKRIntType, value: Int) {
        self.type = type
        self.value = value
    }

}
