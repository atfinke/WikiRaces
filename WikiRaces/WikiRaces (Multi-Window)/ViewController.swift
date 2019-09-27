//
//  ViewController.swift
//  WikiRaces (Multi-Window)
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

//swiftlint:disable line_length function_body_length force_cast superfluous_disable_command
class ViewController: UIViewController {

    var windows = [DebugWindow]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let twoRows = false
        let windows = CGFloat(4)

        let windowWidth: CGFloat
        if twoRows {
            windowWidth = ((view.frame.width + 2) / windows * 2)
        } else {
            windowWidth = ((view.frame.width + 2) / windows) - CGFloat(windows)
        }

        let windowNames = [
            "First",
            "Second",
            "Third",
            "Forth",
            "Fifth",
            "Sixth",
            "Seventh",
            "Eighth"
        ]

        if twoRows {
            for xPos in 0..<Int(windows / 2) {
                let frame = CGRect(x: CGFloat(xPos) * (windowWidth + 1.0), y: 0, width: windowWidth, height: (view.frame.height - 2) / 2)
                let name = windowNames[xPos]
                createDebugWindow(frame: frame, named: name)
            }
            for xPos in 0..<Int(windows / 2) {
                let frame = CGRect(x: CGFloat(xPos) * (windowWidth + 1.0), y: (view.frame.height + 2) / 2, width: windowWidth, height: (view.frame.height - 2) / 2)
                let name = windowNames[xPos + Int(windows / 2)]
                createDebugWindow(frame: frame, named: name)
            }
        } else {
            for xPos in 0..<Int(windows) {
                let frame = CGRect(x: CGFloat(xPos) * (windowWidth + 1.0), y: 0, width: windowWidth, height: view.frame.height)
                let name = windowNames[xPos]
                createDebugWindow(frame: frame, named: name)
            }
        }
        view.backgroundColor = .purple
    }

    func createDebugWindow(frame: CGRect, named name: String) {
        let window = DebugWindow(frame: frame)
        window.playerName = name
        window.rootViewController = MenuViewController()
        window.makeKeyAndVisible()
        windows.append(window)
    }

}
