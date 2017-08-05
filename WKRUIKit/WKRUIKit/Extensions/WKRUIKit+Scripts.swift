//
//  WKRUIKit+Scripts.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

extension WKUserScript {

    public convenience init?(name: String, injectionTime: WKUserScriptInjectionTime) {
        class BundleClass {}
        guard let url = Bundle(for: BundleClass.self).url(forResource: name, withExtension: "js") else {
            return nil
        }
        guard let source = try? String(contentsOf: url) else {
            return nil
        }
        self.init(source: source, injectionTime: injectionTime, forMainFrameOnly: false)
    }
    
}
