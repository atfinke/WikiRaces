//
//  PreRaceContentViewModel.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import Foundation
import CoreGraphics
import Foundation
import WKRKit

class PreRaceContentViewModel: ObservableObject {
    
    enum ProgressDisplayState {
        case none, spinner, progress
    }
    
    @Published var title: String = ""
    
    @Published var progress: CGFloat = 0.0
    @Published var progressDisplayState: ProgressDisplayState = .spinner
    
    @Published var disclaimerButtonTitle: String = " "
    @Published var disclaimerButtonOpacity: Double = 0
    
    private var timer: Timer?
    func startedConnectionTest() {
        startTimer(maxTime: CGFloat(WKRKitConstants.current.connectionTestTimeout),
                   percentChunk: 0.95,
                   startProgress: 0,
                   invalidateTimerProgress: 0.95)
    }
    
    func finishedConnectionTest() {
        timer?.invalidate()
        progress = 1
    }
    
    func startedFindingHostBasedOnConnection(attempt: Int) {
        startTimer(maxTime: CGFloat(WKRKitConstants.current.maxChooseHostTimeBasedOnConnection),
                   percentChunk: attempt == 1 ? 0.65 : 0.05,
                   startProgress: attempt == 1 ? 0 : 0.7,
                   invalidateTimerProgress: attempt == 1 ? 0.7 : 0.75)
    }
    
    func preparingToStartRace(estimatedTime: CGFloat) {
        startTimer(maxTime: estimatedTime / 2,
                   percentChunk: 0.25,
                   startProgress: 0.75,
                   invalidateTimerProgress: 1)
    }
    
    private func startTimer(maxTime: CGFloat, percentChunk: CGFloat, startProgress: CGFloat, invalidateTimerProgress: CGFloat) {
        timer?.invalidate()
        let start = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: { timer in
            self.progress = (CGFloat(-start.timeIntervalSinceNow) / maxTime) * percentChunk + startProgress
            if self.progress > invalidateTimerProgress || self.progress >= 1 {
                timer.invalidate()
            }
        })
    }
}
