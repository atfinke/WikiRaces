//
//  WKRResultsParser.swift
//  WKRVisualizer
//
//  Created by Andrew Finke on 2/19/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRPageResult {
    let title: String
    let duration: Int
}

struct WKRPlayerResult {
    let name: String
    let state: String
    let duration: Int
    let pages: [WKRPageResult]
}

struct WKRResultsParser {

    static func parse(fileURL: URL) -> [WKRPlayerResult]? {
        guard let string = try? String(contentsOf: fileURL) else {
            return nil
        }

        return parse(string: string)
    }

    static func parse(string: String) -> [WKRPlayerResult] {
        let rows = string.components(separatedBy: "\n").dropFirst()

        var playerResults = [WKRPlayerResult]()
        for row in rows where row.count > 2 {
            let columns = row.components(separatedBy: ",")
            let name = columns[0]
            let state = columns[1]
            let duration = Int(columns[2]) ?? 0

            var pageResults = [WKRPageResult]()
            for pageNumber in 3..<columns.count {
                let pageItem = columns[pageNumber] as NSString
                let range = pageItem.range(of: "|")
                let pageDuration = Int(pageItem.substring(to: range.location)) ?? 0
                let pageTitle = pageItem.substring(from: range.location + 1)
                let pageResult = WKRPageResult(title: pageTitle, duration: pageDuration)
                pageResults.append(pageResult)
            }

            let playerResult = WKRPlayerResult(name: name,
                                               state: state,
                                               duration: duration,
                                               pages: pageResults)

            playerResults.append(playerResult)
        }

        return playerResults
    }

}
