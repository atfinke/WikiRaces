//
//  WKRResultsGetter.swift
//  WKRVisualizer
//
//  Created by Andrew Finke on 2/19/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRResultsGetter {

    static func fetchResults(atDirectory url: URL) -> [[WKRPlayerResult]] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: url,
                                                                          includingPropertiesForKeys: nil,
                                                                          options: .skipsSubdirectoryDescendants) else {
                                                                            return []
        }
        return contents.filter ({ url in
            return url.pathExtension == "csv" && !url.absoluteString.contains("Overview")
        }).flatMap { url in
            return WKRResultsParser.parse(fileURL: url)
        }
    }
    
}

