//
//  WKRPlayerProfile.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 7/2/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import SwiftUI
import UIKit

public struct WKRPlayerProfile: Identifiable, Equatable, Hashable, Codable {
    
    // MARK: - Properties -
    
    public var id: String {
        return playerID
    }
    public let name: String
    public let playerID: String
    
    public var image: Image { Image(uiImage: rawImage) }
    public var rawImage: UIImage { WKRUIPlayerImageManager.shared.image(for: id) }

    // MARK: - Initalization -
    
    public init(name: String, playerID: String) {
        self.name = name
        self.playerID = playerID
    }
    
    public init(player: GKPlayer) {
        self.name = player.displayName
        self.playerID = player.alias
    }
    
    public static func ==(lhs: WKRPlayerProfile, rhs: WKRPlayerProfile) -> Bool {
        return lhs.playerID == rhs.playerID
    }
}
