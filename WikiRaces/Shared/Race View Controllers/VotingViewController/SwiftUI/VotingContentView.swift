//
//  VotingContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct VotingContentView: View {
    
    @ObservedObject var model: VotingContentViewModel
    let tapped: (VotingContentViewModel.Item) -> Void
    
    var body: some View {
        VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(self.model.items) { item in
                        VotingItemContentView(item: item, isFinalArticleSelected: self.model.isFinalArticleSelected) {
                            self.tapped(item)
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
