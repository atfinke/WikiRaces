//
//  WKRUIPlayer.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 7/2/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import UIKit

public struct WKRUIPlayer: Identifiable, Equatable {
    public let id: String
    public var image: Image { Image(uiImage: rawImage) }
    public var rawImage: UIImage { WKRUIPlayerImageManager.shared.image(for: id) }

    public init(id: String) {
        self.id = id
    }
}
