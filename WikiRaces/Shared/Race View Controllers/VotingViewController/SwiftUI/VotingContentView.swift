//
//  VotingContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct VotingContentView: View {

    // MARK: - Properties -

    @ObservedObject var model: VotingContentViewModel
    let tappedVotingItem: (VotingContentViewModel.Item) -> Void

    // MARK: - Body -

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(self.model.items) { item in
                    VotingItemContentView(item: item, isFinalArticleSelected: self.model.isFinalArticleSelected) {
                        self.tappedVotingItem(item)
                    }
                }
            }
            .padding(.all, 20)
            .animation(.spring())
            Spacer()
            ListFooterView(topText: model.footerTopText, bottomText: model.footerBottomText, textOpacity: model.footerOpacity)
        }
        .allowsHitTesting(model.isVotingEnabled)
    }

}
