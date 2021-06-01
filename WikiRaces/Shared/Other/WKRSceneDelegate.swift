//
//  WKRSceneDelegate.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/8/21.
//

import UIKit
import WKRUIKit

class WKRSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: WKRUIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = WKRUIWindow(windowScene: windowScene)
        let controller = MenuViewController()
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let code = items.first(where: { $0.name == "Code" })?.value else {
            return
        }
        GKHelper.shared.acceptedInvite(code: code)
        PlayerFirebaseAnalytics.log(event: .raceCodeLinkOpened)
    }
}

