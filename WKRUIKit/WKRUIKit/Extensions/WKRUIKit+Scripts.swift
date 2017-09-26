//
//  WKRUIKit+Scripts.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

extension WKUserScript {
    public convenience init(source: String, injectionTime: WKUserScriptInjectionTime) {
        self.init(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
    }
}
