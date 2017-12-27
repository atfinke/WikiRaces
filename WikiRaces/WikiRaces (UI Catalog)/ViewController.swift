//
//  ViewController.swift
//  WikiRaces (UI Catalog)
//
//  Created by Andrew Finke on 9/17/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

@testable import WKRKit
@testable import WKRUIKit

class ViewController: UIViewController {

    //swiftlint:disable line_length function_body_length force_cast
    override func viewDidLoad() {
        super.viewDidLoad()

        let historyNav = viewController() as! UINavigationController

        let historyController = historyNav.rootViewController as! GameViewController

        present(historyNav, animated: true, completion: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
               }
            }
        }

    }

    //swiftlint:disable force_cast
    func viewController() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameNav")
    }

}
