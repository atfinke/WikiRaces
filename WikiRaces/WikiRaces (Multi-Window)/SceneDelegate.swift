//
//  SceneDelegate.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/8/21.
//

import UIKit
import WKRUIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: WKRUIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = WKRUIWindow(windowScene: windowScene)
        let controller = ViewController()
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}

