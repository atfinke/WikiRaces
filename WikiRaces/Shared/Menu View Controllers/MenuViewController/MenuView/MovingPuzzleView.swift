//
//  MovingPuzzleView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

class MovingPuzzleView: UIView, UIScrollViewDelegate {

    private var puzzleTimer: Timer?
    /// The puzzle piece view
    private let innerPuzzleView = UIScrollView()

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.wkrMenuPuzzleViewColor
        translatesAutoresizingMaskIntoConstraints = false

        innerPuzzleView.delegate = self
        innerPuzzleView.decelerationRate = .fast
        innerPuzzleView.showsHorizontalScrollIndicator = false
        innerPuzzleView.contentSize = CGSize(width: 12000, height: 30)
        innerPuzzleView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "MenuBackgroundPuzzle"))
        innerPuzzleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(innerPuzzleView)

        let constraints = [
            innerPuzzleView.leftAnchor.constraint(equalTo: leftAnchor),
            innerPuzzleView.rightAnchor.constraint(equalTo: rightAnchor),
            innerPuzzleView.topAnchor.constraint(equalTo: topAnchor, constant: 22.5),
            innerPuzzleView.heightAnchor.constraint(equalToConstant: 30)
        ]
        NSLayoutConstraint.activate(constraints)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(stop),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(start),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let contentOffset = innerPuzzleView.contentOffset.x
        if contentOffset > innerPuzzleView.contentSize.width * 0.8 {
            animateContentOffsetReset()
        }
    }

    private func animateContentOffsetReset() {
        UIView.animate(withDuration: 0.25,
                       animations: {
                        self.innerPuzzleView.alpha = 0.0
        }, completion: { _ in
            self.stop()
            self.start()
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.innerPuzzleView.alpha = 1.0
            })
        })
    }

    @objc
    func start() {
        innerPuzzleView.contentOffset = .zero

        let duration = TimeInterval(60)
        let offset = CGFloat(40 * duration)

        func animateScroll() {
            let contentOffset = innerPuzzleView.contentOffset.x
            if contentOffset > innerPuzzleView.contentSize.width * 0.8 {
                animateContentOffsetReset()
                return
            }
            let xOffset = innerPuzzleView.contentOffset.x + offset
            let options: UIView.AnimationOptions = [
                .curveLinear,
                .allowUserInteraction
            ]
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: options,
                           animations: {
                            self.innerPuzzleView.contentOffset = CGPoint(x: xOffset, y: 0)
            }, completion: nil)
        }

        puzzleTimer?.invalidate()
        puzzleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
            animateScroll()
        }
        puzzleTimer?.fire()
    }

    @objc
    func stop() {
        puzzleTimer?.invalidate()
        innerPuzzleView.layer.removeAllAnimations()
    }
}
