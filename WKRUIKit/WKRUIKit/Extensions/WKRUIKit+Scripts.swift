//
//  WKRUIKit+Scripts.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

extension WKUserScript {

    @available(*, deprecated, message: "To be removed")
    public convenience init?(named: String, in bundle: Bundle?, injectionTime: WKUserScriptInjectionTime) {
        guard let url = bundle?.url(forResource: named, withExtension: "js"),
            let source = try? String(contentsOf: url) else {
            return nil
        }
        self.init(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
    }

    public convenience init(source: String, injectionTime: WKUserScriptInjectionTime) {
        self.init(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
    }

}
