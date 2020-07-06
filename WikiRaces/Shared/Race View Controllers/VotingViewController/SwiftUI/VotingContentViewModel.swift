//
//  VotingContentViewModel.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRKit
import WKRUIKit

class VotingContentViewModel: ObservableObject {

    // MARK: - Types -

    struct Item: Identifiable, Equatable {
        var id: String { return page.url.absoluteString }
        var page: WKRPage
        var players: [WKRPlayerProfile]
        var isFinal: Bool = false
    }

    // MARK: - Properties -

    @Published var items = [Item]()
    @Published var isFinalArticleSelected: Bool = false
    @Published var isVotingEnabled: Bool = true

    @Published var footerTopText: String = " "
    @Published var footerBottomText: String = " "
    @Published var footerOpacity: Double = 1.0

    // MARK: - Helpers -

    func update(votingState: WKRVotingState?) {
        guard let state = votingState else {
            items = []
            return
        }
        items = state.current.map { page, players in
            return Item(page: page, players: players)
        }
    }

    func selected(finalPage: WKRPage) {
        for (index, item) in items.enumerated() {
            if item.page == finalPage {
                items[index].isFinal = true
            }
        }
        isFinalArticleSelected = true
        isVotingEnabled = false
    }
}
