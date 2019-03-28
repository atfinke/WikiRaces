//
//  WKRLogEvent.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRLogEvent {

    public enum EventType: String {
        case linkOnPage, missedLink, foundPage, pageBlocked, pageLoadingError, pageView
        case collectiveVotingArticlesSeen, localVotingArticlesSeen, localVotingArticlesReset
        case votingArticleValidationFailure, votingArticlesWeightedTiebreak
    }

    public let type: EventType
    public let attributes: [String: Any]?
}
