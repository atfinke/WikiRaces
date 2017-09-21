//
//  ViewController.swift
//  WikiRaces (UI Catalog)
//
//  Created by Andrew Finke on 9/17/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //swiftlint:disable line_length function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()
        let window = UIWindow(frame: CGRect( x:0, y: 0, width: view.frame.width, height: view.frame.height))
        window.rootViewController = self.viewController()
        window.makeKeyAndVisible()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            window.rootViewController?.viewDidAppear(false)
        }
        view.backgroundColor = UIColor.purple
        view.addSubview(window)
    }

    //swiftlint:disable force_cast
    func viewController() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VotingNav")
    }

}
