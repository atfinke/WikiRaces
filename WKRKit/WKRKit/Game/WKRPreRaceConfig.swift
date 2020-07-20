//
//  WKRPreRaceConfig.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit
import os.log

/// Used to transmit voting data and starting page
public struct WKRPreRaceConfig: Codable, Equatable {
    
    // MARK: - Properties
    
    /// The voting info
    internal var votingState: WKRVotingState
    /// The starting page
    internal let startingPage: WKRPage
    
    // MARK: Initialization
    
    /// Creates a WKRPreRaceConfig object
    ///
    /// - Parameters:
    ///   - startingPage: The starting page
    ///   - votingState: The voting info
    private init(startingPage: WKRPage, votingState: WKRVotingState) {
        self.votingState = votingState
        self.startingPage = startingPage
    }
    
    // MARK: - Creation
    
    /// Creates a race config object based on starting page and voting data
    ///
    /// - Returns: The new race config
    internal func raceConfig(with weights: [WKRPlayerProfile: Int]) -> (WKRRaceConfig?, WKRLogEvent?) {
        let (finalPage, logEvent) = votingState.selectFinalPage(with: weights)
        guard let page = finalPage else {
            return (nil, logEvent)
        }
        return (WKRRaceConfig(starting: startingPage, ending: page), logEvent)
    }
    
    /// Creates a WKRPreRaceConfig object
    ///
    /// - Parameter completionHandler: The handler holding the new config object
    static func new(settings: WKRGameSettings, completionHandler: @escaping ((_ config: WKRPreRaceConfig?, _ logEvents: [WKRLogEvent]) -> Void)) {
        var logEvents = [WKRLogEvent]()
        let operationQueue = OperationQueue()
        
        var potentialFinalPages = [WKRPage]()
        var startingPage: WKRPage?
        var fastlaneFinalPage: WKRPage?
        
        let completedOperation = BlockOperation {
            // Used for quick debug to set first page to Apple and final page to first link on page.
            if WKRKitConstants.current.isQuickRaceMode {
                let startingURL = URL(string: "https://en.m.wikipedia.org/wiki/Apple_Inc.")!
                startingPage = WKRPage(title: "Apple Inc.", url: startingURL)
                
                let endingURL = URL(string: "https://en.m.wikipedia.org/wiki/Apple_Park")!
                let fakeEnd = WKRPage(title: "Apple Park", url: endingURL)
                
                potentialFinalPages.removeLast()
                potentialFinalPages.insert(fakeEnd, at: 0)
            }
            
            // Uses a set to remove any duplicates. This could happen if two final articles end up redirecting to the same page.
            let finalPages = Array(Set(potentialFinalPages.prefix(WKRKitConstants.current.votingArticlesCount)))
            
            let events = logEvents.compactMap { $0 }
            if !finalPages.isEmpty, let page = startingPage {
                var config = WKRPreRaceConfig(startingPage: page, votingState: WKRVotingState(pages: finalPages))
                if WKRDefaults.isFastlaneSnapshotInstance, let page = fastlaneFinalPage {
                    config.votingState.fastlaneVotes(finalPage: page)
                }
                completionHandler(config, events)
            } else {
                completionHandler(nil, events)
            }
        }
        
        // Gets the starting page
        let startingPageOperation = WKROperation()
        startingPageOperation.addExecutionBlock { [unowned startingPageOperation] in
            switch settings.startPage {
            case .random:
                if WKRDefaults.isFastlaneSnapshotInstance {
                    if WKRLanguageHackery.shared.isEnglish {
                        guard let url = URL(string: "https://en.m.wikipedia.org/wiki/Walt_Disney_World_Monorail_System") else { fatalError() }
                        startingPage = WKRPage(title: "Walt Disney World Monorail System", url: url)
                        startingPageOperation.state = .isFinished
                    } else {
                        WKRLanguageHackery.shared.adjustedPath(for: "/Walt_Disney") { path in
                            guard let path = path else { fatalError() }
                            WKRPageFetcher.fetch(path: path, useCache: true) { page, _ in
                                guard let page = page else { fatalError() }
                                startingPage = page
                                startingPageOperation.state = .isFinished
                            }
                        }
                    }
                } else {
                    WKRPageFetcher.fetchRandom { page in
                        startingPage = page
                        startingPageOperation.state = .isFinished
                        os_log("fetched random start: %{public}s", log: .articlesValidation, type: .info, page?.title ?? "-")
                    }
                }
            case .custom(let page):
                startingPage = page
                startingPageOperation.state = .isFinished
            }
        }
        completedOperation.addDependency(startingPageOperation)
        
        let endingPageOperations: [BlockOperation]
        switch settings.endPage {
        case .curatedVoting:
            // Get a few more than neccessary random paths in case some final articles are no longer valid
            let (finalArticles, resetLogEvent) = WKRSeenFinalArticlesStore.unseenArticles()
            if let event = resetLogEvent {
                logEvents.append(event)
            }
            var randomPaths = [String]()
            let numberOfPagesToFetch = WKRKitConstants.current.votingArticlesCount + 1
            
            // pages are suffled so we can just take index 0-n from the shuffled array
            for index in 0..<numberOfPagesToFetch where index < finalArticles.count {
                randomPaths.append(finalArticles[index])
            }
            
            var fastlanePath: String?
            if WKRDefaults.isFastlaneSnapshotInstance {
                if WKRLanguageHackery.shared.isEnglish {
                    randomPaths[0] = "/Star_Wars:_Galaxy%27s_Edge"
                } else {
                    randomPaths[0] = "/Magic_Kingdom"
                }
                fastlanePath = randomPaths[0]
            }
            
            // All the operations for get WKRPage objects to vote on
            endingPageOperations = randomPaths.map { path -> WKROperation in
                let operation = WKROperation()
                operation.addExecutionBlock { [unowned operation] in
                    
                    WKRLanguageHackery.shared.adjustedPath(for: path) { adjustedPath in
                        guard let adjustedPath = adjustedPath else {
                            operation.state = .isFinished
                            os_log("fetched error: no adjusted path", log: .articlesValidation, type: .error)
                            return
                        }
                        
                        // don't use cache to make sure to get most recent page
                        WKRPageFetcher.fetch(path: adjustedPath, useCache: false) { page, isRedirect in
                            // 1. Make sure not redirect
                            // 2. Make sure page not nil
                            // 3. Make sure page not already in voting list for this race
                            // 4. Make sure page is not a link to a section "/USA#History"
                            // 5. Sometimes removed pages redirect to the Wikipedia homepage.
                            // 6. Make sure path in unseen
                            // 7/8. Make sure link not equal to starting page
                            if !isRedirect,
                                let page = page,
                                !potentialFinalPages.contains(page),
                                !page.url.absoluteString.contains("#"),
                                page.title != "Wikipedia, the free encyclopedia",
                                let startingPage = startingPage,
                                startingPage.url.absoluteString.lowercased() != page.url.absoluteString.lowercased() {
                                potentialFinalPages.append(page)
                                os_log("fetched final: %{public}s", log: .articlesValidation, type: .info, page.title ?? "-")
                            } else {
                                logEvents.append(WKRLogEvent(type: .votingArticleValidationFailure,
                                                             attributes: ["PagePath": adjustedPath]))
                                os_log("fetched error final: %{public}s", log: .articlesValidation, type: .error, page?.title ?? "-")
                            }
                            
                            if WKRDefaults.isFastlaneSnapshotInstance && fastlanePath == path {
                                fastlaneFinalPage = page
                            }
                            operation.state = .isFinished
                        }
                    }
                }
                operation.addDependency(startingPageOperation)
                completedOperation.addDependency(operation)
                return operation
            }
        case .randomVoting:
            let numberOfPagesToFetch = Int(Double(WKRKitConstants.current.votingArticlesCount) * 1.5)
            
            // All the operations for get WKRPage objects to vote on
            endingPageOperations = (0..<numberOfPagesToFetch).map { _ -> WKROperation in
                let operation = WKROperation()
                operation.addExecutionBlock { [unowned operation] in
                    // truly the wild west approach
                    // steps are less strict then curated
                    WKRPageFetcher.fetchRandom { page in
                        if let page = page,
                            let title = page.title,
                            !page.url.absoluteString.contains("#"),
                            title != "Wikipedia, the free encyclopedia",
                            title.count < WKRKitConstants.current.pageTitleMaxRandomLength {
                            potentialFinalPages.append(page)
                        } else {
                            // Don't log the analytics, keep validation to just curated articles
                        }
                        operation.state = .isFinished
                    }
                }
                operation.addDependency(startingPageOperation)
                completedOperation.addDependency(operation)
                return operation
            }
        case .custom(let page):
            let operation = WKROperation()
            operation.addExecutionBlock { [unowned operation] in
                potentialFinalPages.append(page)
                operation.state = .isFinished
            }
            operation.addDependency(startingPageOperation)
            completedOperation.addDependency(operation)
            endingPageOperations = [operation]
        }
        
        operationQueue.addOperations([startingPageOperation, completedOperation], waitUntilFinished: false)
        operationQueue.addOperations(endingPageOperations, waitUntilFinished: false)
    }
    
}
