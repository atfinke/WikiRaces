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
                let window = DebugWindow(frame: CGRect(x: CGFloat(xPos) * (windowWidth + 1.0), y: 0, width: windowWidth, height: (view.frame.height - 2) / 2))
                window.playerName = windowNames[xPos]
                window.rootViewController = self.menuViewController()
                window.makeKeyAndVisible()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    window.rootViewController?.viewDidAppear(false)
                }
            }
            for xPos in 0..<Int(windows / 2) {
                let window = DebugWindow(frame: CGRect(x: CGFloat(xPos) * (windowWidth + 1.0), y: (view.frame.height + 2) / 2, width: windowWidth, height: (view.frame.height - 2) / 2))
                window.playerName = windowNames[xPos + Int(windows / 2)]
                window.rootViewController = self.menuViewController()
                window.makeKeyAndVisible()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    window.rootViewController?.viewDidAppear(false)
                }
            }
        } else {
            for xPos in 0..<Int(windows) {
                let window = DebugWindow(frame: CGRect(x: CGFloat(xPos) * (windowWidth + 1.0), y: 0, width: windowWidth, height: view.frame.height))
                window.playerName = windowNames[xPos]
                window.rootViewController = self.menuViewController()
                window.makeKeyAndVisible()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    window.rootViewController?.viewDidAppear(false)
                }
            }
        }
        view.backgroundColor = UIColor.purple
    }

    func menuViewController() -> MenuViewController {
        let controller = UIStoryboard(name: "Main", bundle: nil)
            .instantiateInitialViewController() as! UINavigationController
        return controller.viewControllers.first as! MenuViewController
    }

}
