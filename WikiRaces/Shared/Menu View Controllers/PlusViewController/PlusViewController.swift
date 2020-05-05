//
//  PlusViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

class PlusViewController: UIViewController {

    // MARK: - Properties -

    private let plusView = PlusView()
    private let alphaView = UIView()
    var onCompletion: (() -> Void)?

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        alphaView.backgroundColor = UIColor.black
        alphaView.alpha = 0
        view.addSubview(alphaView)
        view.addSubview(plusView)

        view.backgroundColor = .clear

        plusView.onCompletion = { [weak self] in
            self?.done()
        }

        plusView.onError = { [weak self] controller in
            self?.present(controller, animated: true, completion: nil)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        alphaView.frame = view.bounds

        if plusView.frame == .zero {
            let width = max(min(view.bounds.width - 30, 400), 310)
            plusView.frame = CGRect(origin: .zero, size: CGSize(width: width, height: view.bounds.height))
            plusView.setNeedsLayout()
            plusView.layoutIfNeeded()

            plusView.center = CGPoint(x: view.center.x, y: view.bounds.height + plusView.frame.height / 2)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(
            withDuration: 0.7,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.4,
            options: [],
            animations: {
                if  self.view.frame.width > 340 {
                    self.plusView.center = CGPoint(x: self.view.center.x, y: self.view.center.y * 0.75)
                } else {
                    self.plusView.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
                }
                self.alphaView.alpha = 0.5
        }, completion: nil)
    }

    // MARK: - Helpers -

    func done() {
        UIView.animate(
            withDuration: 0.75,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.2,
            options: [],
            animations: {
                self.plusView.center = CGPoint(x: self.view.center.x,
                                               y: self.view.frame.height + self.plusView.bounds.height / 2)
                self.alphaView.alpha = 0
        }, completion: { _ in
            self.dismiss(animated: false, completion: {
                self.onCompletion?()
            })

        })
    }
}
