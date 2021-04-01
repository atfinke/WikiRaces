//
//  PreRaceJoinStandardViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import WKRUIKit
import os.log

class PreRaceJoinStandardViewController: PreRaceViewController, GKMatchmakerViewControllerDelegate {
    
    // MARK: - Properties -
    
    var isMatchmaking = false
    
    // MARK: - Initalization -
    
    override init(destination: PreRaceViewController.Destination) {
        os_log("%{public}s: (PreRaceJoinStandardViewController)", log: .gameKit, type: .info, #function)
        super.init(destination: destination)
        view.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("%{public}s: (PreRaceJoinStandardViewController)", log: .gameKit, type: .info, #function)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         
        guard !isMatchmaking else {
            return
        }
        isMatchmaking = true
        
        switch destination {
        case .hostCustom:
            fatalError()
        case .joinCustom(let raceCode):
            joinPrivate(raceCode: raceCode)
        case .joinStandard(let invite):
            let matchmaker: GKMatchmakerViewController?
            if let invite = invite {
                matchmaker = GKMatchmakerViewController(invite: invite)
            } else {
                matchmaker = GKMatchmakerViewController(matchRequest: GKMatchRequest.joinRequest(raceCode: nil))
            }
            guard let controller = matchmaker else {
                GKNotificationBanner.show(withTitle: "Game Center Issue", message: "Please try again later.", completionHandler: nil)
                model.title = "GAME CENTER ISSUE"
                model.progressDisplayState = .none
                return
            }
            controller.matchmakingMode = .default
            controller.matchmakerDelegate = self
            present(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: - GKMatchmakerViewControllerDelegate -
    
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        viewController.dismiss(animated: true, completion: {
            self.navigationController?.popToRootViewController(animated: false)
        })
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        os_log("%{public}s:\n %{public}s\n %{public}s\n %{public}s", log: .gameKit, type: .error, #function, error.localizedDescription, (error as? GKError)?.localizedDescription ?? "-", (error as? GKError)?._nsError.description ?? "-")
        view.alpha = 1
        DispatchQueue.main.async {
            GKNotificationBanner.show(withTitle: "Game Center Issue", message: "Please try again later.", completionHandler: nil)
            self.model.title = "GAME CENTER ISSUE"
            self.model.progressDisplayState = .none
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        os_log("%{public}s: expectedPlayerCount: %{public}ld", log: .gameKit, type: .info, #function, match.expectedPlayerCount)
        
        DispatchQueue.global().async {
            while match.expectedPlayerCount != 0 {
                sleep(1)
            }
            DispatchQueue.main.async {
                self.connected(to: match, from: viewController)
            }
        }
    }
    
    // MARK: - Helpers -
    
    func joinPrivate(raceCode: String) {
        os_log("%{public}s: race code: %{public}s", log: .gameKit, type: .info, #function, raceCode)
        
        model.title = "joining race"
        model.progressDisplayState = .spinner
        
        UIView.animate(withDuration: 0.5) {
            self.view.alpha = 1.0
        }
        
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.joinRequest(raceCode: raceCode)) { [weak self] match, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error != nil || match == nil {
                    os_log("%{public}s: error: %{public}s", log: .gameKit, type: .error, #function, error?.localizedDescription ?? "-")
                    self.model.title = "UNABLE TO JOIN"
                    self.model.progressDisplayState = .none
                    GKNotificationBanner.show(withTitle: "Game Center Issue", message: "Please try again later.", completionHandler: nil)
                } else if let match = match {
                    os_log("%{public}s: found match", log: .gameKit, type: .info, #function)
                    self.connected(to: match, from: nil)
                }
            }
        }
    }
    
    func connected(to match: GKMatch, from controller: GKMatchmakerViewController?) {
        assert(Thread.isMainThread)
        let hostSelectionController = PreRaceHostSelectionViewController(match: match, destination: destination)
        if let controller = controller {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                controller.dismiss(animated: true) { [weak self] in
                    self?.navigationController?.pushViewController(hostSelectionController, animated: false)
                }
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.view.alpha = 0
            } completion: { [weak self] _ in
                self?.navigationController?.pushViewController(hostSelectionController, animated: false)
            }
        }
        WKRUIPlayerImageManager.shared.connected(to: match.players)
    }
}
