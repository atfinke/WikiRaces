//
//  WKRKit+Array.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension Array {
    public var randomElement: Element? {
        guard !isEmpty else { return nil }
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}

//swiftlint:disable identifier_name line_length
public func _debugLog(_ object: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    let bridgedFileName = file as NSString
    let fileName = bridgedFileName.substring(from: bridgedFileName.range(of: "/", options: .backwards).location + 1) as String + " "

    let functionLine = function + ": " + line.description + " "

    let fileNameString: String
    if fileName.characters.count < 40 {
        fileNameString = fileName + (0..<(40 - fileName.characters.count)).map({ _ in return " " }).reduce("", +)
    } else {
        fileNameString = fileName + "\n"
    }

    let functionString: String
    if functionLine.characters.count < 40 {
        functionString = functionLine + (0..<(40 - functionLine.characters.count)).map({ _ in return " " }).reduce("", +)
    } else {
        functionString = functionLine + "\n"
    }

    let objectString: String
    if object.debugDescription.characters.count < 90 {
        objectString = object.debugDescription + (0..<(90 - object.debugDescription.characters.count)).map({ _ in return " " }).reduce("", +)
    } else {
        objectString = "\n" + object.debugDescription + "\n\n"
    }

    //print(fileNameString + functionString + objectString)
}
