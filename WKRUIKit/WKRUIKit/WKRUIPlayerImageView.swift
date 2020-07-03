//
//  WKRUIPlayerImageView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 7/2/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

public struct WKRUIPlayerImageView: View {

    // MARK: - Properties -

    let player: WKRPlayerProfile
    let size: CGFloat
    let effectSize: CGFloat

    // MARK: - Body -

    public var body: some View {
        Image(uiImage: WKRUIPlayerImageManager.shared.image(for: player.playerID))
            .renderingMode(.original)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(radius: effectSize)
    }

    public init(player: WKRPlayerProfile, size: CGFloat, effectSize: CGFloat) {
        self.player = player
        self.size = size
        self.effectSize = effectSize
    }
}
