//
//  WKRPreRaceConfig.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
public struct WKRPreRaceConfig: Codable, Equatable {

    // MARK: - Properties

    internal var voteInfo: WKRVoteInfo
    internal let startingPage: WKRPage

    // MARK: Initialization

    init(startingPage: WKRPage, voteInfo: WKRVoteInfo) {
        self.voteInfo = voteInfo
        self.startingPage = startingPage
    }

    // MARK: - Creation

    internal func raceConfig() -> WKRRaceConfig? {
        guard let finalPage = voteInfo.selectFinalPage() else {
            return nil
        }
        return WKRRaceConfig(starting: startingPage, ending: finalPage)
    }

    static func new(completionHandler: @escaping ((_ config: WKRPreRaceConfig?) -> Void)) {
        let finalArticles = WKRKitConstants.current.finalArticles()
        let operationQueue = OperationQueue()

        var randomPaths = [String]()
        while randomPaths.count < Int(Double(WKRRaceConstants.votingArticlesCount) * 1.5) {
            if let randomPath = finalArticles.randomElement, !randomPaths.contains(randomPath) {
                randomPaths.append(randomPath)
            }
        }

        var pages = [WKRPage]()
        var startingPage: WKRPage?

        let completedOperation = BlockOperation {
            if WKRKitConstants.current.quickRace {
                let startingURL = URL(string: "https://en.m.wikipedia.org/wiki/Apple_Inc.")!
                startingPage = WKRPage(title: "Apple Inc.", url: startingURL)

                let endingURL = URL(string: "https://en.m.wikipedia.org/wiki/Multinational_corporation")!
                let fakeEnd = WKRPage(title: "Multinational Corporation", url: endingURL)

                pages.removeLast()
                pages.insert(fakeEnd, at: 0)
            }

            let config = preRaceConfig(startingPage: startingPage, pages)
            completionHandler(config)
        }
        completedOperation.name = "Completion Operation"

        let startingPageOperation = WKROperation()
        startingPageOperation.addExecutionBlock {
            WKRPageFetcher.fetchRandom { page in
                startingPage = page
                startingPageOperation.state = .isFinished
            }
        }
        startingPageOperation.name = "Starting Page Operation"
        completedOperation.addDependency(startingPageOperation)

        let operations = randomPaths.map { path -> WKROperation in
            let operation = WKROperation()
            operation.addExecutionBlock {
                WKRPageFetcher.fetch(path: path) { (page) in
                    if let page = page {
                        pages.append(page)
                    }
                    operation.state = .isFinished
                }
            }
            operation.name = "Page Fetch Operation"
            completedOperation.addDependency(operation)
            return operation
        }
        operationQueue.addOperations(operations, waitUntilFinished: false)
        operationQueue.addOperations([startingPageOperation, completedOperation], waitUntilFinished: false)
    }

    private static func preRaceConfig(startingPage: WKRPage?, _ pages: [WKRPage]) -> WKRPreRaceConfig? {
        let finalPages = Array(pages.prefix(WKRRaceConstants.votingArticlesCount))
        if !finalPages.isEmpty, let page = startingPage {
            return WKRPreRaceConfig(startingPage: page, voteInfo: WKRVoteInfo(pages: finalPages))
        }
        return nil
    }

    // MARK: - Equatable

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRPreRaceConfig, rhs: WKRPreRaceConfig) -> Bool {
        return lhs.voteInfo == rhs.voteInfo && lhs.startingPage == rhs.startingPage
    }

}
