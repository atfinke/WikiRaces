//
//  ViewController.swift
//  WikiRaces (UI Catalog)
//
//  Created by Andrew Finke on 9/17/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

class ViewController: UIViewController {

    //swiftlint:disable line_length function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Star Wars: Galaxy's Edge".uppercased()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "flag"), landscapeImagePhone: nil, style: .done, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
        let webView = WKRUIWebView()
        self.view = webView
        webView.load(URLRequest(url: URL(string: "https://en.m.wikipedia.org/wiki/Walt_Disney_World")!))

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            let window = UIWindow(frame: CGRect( x:0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
            window.rootViewController = self.viewController()
            window.makeKeyAndVisible()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                window.rootViewController?.viewDidAppear(false)
            }
            self.view.backgroundColor = UIColor.purple
            self.view.addSubview(window)

        }
    }

    //swiftlint:disable force_cast
    func viewController() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
    }

}
