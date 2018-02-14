//
//  WKRPeerNetworkConfig.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/10/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public enum WKRPeerNetworkConfig {

    case solo(name: String)
    case multiwindow(windowName: String, isHost: Bool)
    case mpc(serviceType: String, session: MCSession, isHost: Bool)

    public var isHost: Bool {
        switch self {
        case .solo:
            return true
        case .multiwindow(_, let isHost):
            return isHost
        case .mpc(_, _, let isHost):
            return isHost
        }
    }

}
