//
//  VotingItemContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRUIKit

struct VotingItemContentView: View {

    // MARK: - Properties -

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let item: VotingContentViewModel.Item
    let isFinalArticleSelected: Bool
    let action: () -> Void

    // MARK: - Body -

    var body: some View {
        let isFinal = isFinalArticleSelected && item.isFinal
        let opacity = isFinal || !isFinalArticleSelected ? 1 : 0.2

        return Button(action: action) {
            HStack {
                Text(item.page.title ?? "-")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.wkrTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 10)
                Spacer()
                Color.clear.frame(width: 1, height: 26)
                ForEach(item.players) { player in
                    WKRUIPlayerImageView(player: player, size: 24, effectSize: 1)
                }
            }
        }
        .opacity(opacity)
        .animation(Animation.easeInOut(duration: 2), value: isFinalArticleSelected)
        .padding(.horizontal)
    }
}
