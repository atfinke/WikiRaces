//
//  WKROperation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// Subclass the allows async operation blocks
public class WKROperation: BlockOperation {

    // MARK: - Types

    public enum State: String {
        case isReady, isExecuting, isFinished
    }

    // MARK: - Properties

    public var state = State.isReady {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
            willChangeValue(forKey: state.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }

    public override var isReady: Bool {
        return super.isReady && state == .isReady
    }

    public override var isExecuting: Bool {
        return state == .isExecuting
    }

    public override var isFinished: Bool {
        return state == .isFinished
    }

    public override var isAsynchronous: Bool {
        return true
    }
}
