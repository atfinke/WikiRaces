//
//  VotingContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

private struct Table: View {
    let items: [VotingContentViewModel.Item]
    let isFinalArticleSelected: Bool
    let tappedVotingItem: (VotingContentViewModel.Item) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                VotingItemContentView(item: item, isFinalArticleSelected: isFinalArticleSelected) {
                    tappedVotingItem(item)
                }
            }
        }
        .padding(.all, 20)
        .animation(.spring())
        .frame(maxWidth: 500)
    }
}

struct VotingContentView: View {

    // MARK: - Properties -

    @ObservedObject var model: VotingContentViewModel
    let tappedVotingItem: (VotingContentViewModel.Item) -> Void

    // MARK: - Body -

    var body: some View {
        VStack {
            Spacer()
            Table(items: model.items, isFinalArticleSelected: model.isFinalArticleSelected, tappedVotingItem: tappedVotingItem)
            Spacer()
            ListFooterView(
                topText: model.footerTopText,
                bottomStartText: model.footerBottomStartText,
                bottomNumberText: model.footerBottomNumberText,
                bottomEndText: model.footerBottomEndText,
                textOpacity: model.footerOpacity,
                dividerOpacity: 1)
        }
        .allowsHitTesting(model.isVotingEnabled)
    }

}
