//
//  RevampHostViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import UIKit
import os.log

import WKRKit
import WKRUIKit
import SwiftUI

final internal class GKHostViewController: HostingViewController {
    
    // MARK: - Properties -
    
    let raceCodeGenerator = RaceCodeGenerator()
    var match: GKMatch?
    var messenger: PreRaceMessenger?
    private let advertiser = NearbyRaceAdvertiser()
    private let sourceView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    
    var isMatchmakingEnabled = true {
        didSet {
            if !isMatchmakingEnabled {
                advertiser.stop()
                raceCodeGenerator.cancel()
            }
        }
    }
    
    var model = HostContentViewModel()
    lazy var contentViewHosting = UIHostingController(
        rootView: HostContentView(
            model: model,
            cancelAction: { [weak self] in
                PlayerFirebaseAnalytics.log(event: .hostCancelledPreMatch)
                self?.isMatchmakingEnabled = false
                self?.cancelMatch()
            },
            startMatch: { [weak self] in
                self?.isMatchmakingEnabled = false
                self?.startMatch()
            },
            presentModal: { [weak self] modal in
                self?.presentModal(modal: modal)
        }))
    
    // MARK: - Initalization -
    
    init() {
        super.init(nibName: nil, bundle: nil)
        if Defaults.isFastlaneSnapshotInstance {
            model.raceCode = "APPLE"
            model.state = .showingRacers
            model.connectedPlayers = [
                WKRPlayerProfile(name: "C", playerID: "C"),
                WKRPlayerProfile(name: "G", playerID: "G"),
                WKRPlayerProfile(name: "M", playerID: "M"),
                WKRPlayerProfile(name: "X", playerID: "X")
            ]
        } else {
            startMatchmaking()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourceView.alpha = 0
        view.addSubview(sourceView)
        contentViewHosting.view.alpha = 0
        configure(hostingView: contentViewHosting.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.contentViewHosting.view.alpha = 1
        }
        
        guard !Defaults.promptedAutoInvite && !Defaults.isFastlaneSnapshotInstance else {
            return
        }
        Defaults.promptedAutoInvite = true
        
        let controller = UIAlertController(
            title: "Invite Nearby Racers?",
            message: "Would you like to automatically invite nearby racers? This preference can be changed later in the settings app.",
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            Defaults.isAutoInviteOn = true
            self?.startNearbyAdvertising()
            os_log("%{public}s: enabled auto invite", log: .gameKit, type: .info, #function)
        }
        controller.addAction(action)
        
        let cancelAction = UIAlertAction(title: "Not Now", style: .cancel) { _ in
            os_log("%{public}s: disabled auto invite", log: .gameKit, type: .info, #function)
        }
        controller.addAction(cancelAction)
        
        present(controller, animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sourceView.center = CGPoint(x: view.center.x, y: view.center.y - 150)
    }
    
    // MARK: - Actions -
    
    func startMatch() {
        if Defaults.isFastlaneSnapshotInstance {
            guard let code =  Locale.preferredLanguages.first?.split(separator: "-").first else { fatalError() }
            model.settings.language = WKRGameSettings.Language(code: String(code))
            let controller = GameViewController(network: .solo(name: "_"), settings: model.settings)
            let nav = WKRUINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .crossDissolve
            nav.isModalInPresentation = true
            present(nav, animated: false)
            return
        }
        
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        
        GKMatchmaker.shared().cancel()
        raceCodeGenerator.cancel()
        
        advertiser.stop()
        contentViewHosting.view.isUserInteractionEnabled = false
        
        func startSolo() {
            let controller = GameViewController(network: .solo(name: GKLocalPlayer.local.alias), settings: self.model.settings)
            let nav = WKRUINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .crossDissolve
            nav.isModalInPresentation = true
            
            self.present(nav, animated: true, completion: { [weak self] in
                self?.view.alpha = 0
            })
        }
        
        if match == nil || match?.players.count == 0 {
            if Defaults.promptedSoloRacesStats {
                startSolo()
            } else {
                let controller = UIAlertController(title: "Solo Race", message: "Solo races will not impact your leaderboard stats.", preferredStyle: .alert)
                
                let startAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    startSolo()
                }
                controller.addAction(startAction)
                
                present(controller, animated: true, completion: nil)
                Defaults.promptedSoloRacesStats = true
            }
        } else if let match = match {
            let controller = PreRaceHostSelectionViewController(match: match, destination: .hostCustom)
            controller.startCustomRaceHostDetermination(with: model.settings)
            UIView.animate(withDuration: 0.5) {
                self.contentViewHosting.view.alpha = 0
            } completion: { [weak self] _ in
                self?.navigationController?.pushViewController(controller, animated: false)
            }
        }
    }
    
    func cancelMatch() {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        messenger?.send(message: .init(info: .hostCancelled, data: nil))
        GKMatchmaker.shared().cancel()
        
        if let match = match {
            match.delegate = nil
            match.disconnect()
        }

        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            self.navigationController?.popToRootViewController(animated: false)
        })
    }
    
    // MARK: - Other -
    
    private func presentModal(modal: HostContentView.Modal) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, "\(modal)")
        
        let controller: UIViewController
        switch modal {
        case .activity:
            guard let code = model.raceCode, let url = URL(string: "WikiRaces://Invite?Code=\(code)") else {
                fatalError()
            }
            controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            PlayerFirebaseAnalytics.log(event: .raceCodeShared)
        case .settings:
            controller = CustomRaceViewController(settings: model.settings, pages: model.customPages) { pages in
                self.model.customPages = pages
            }
        }
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .phone ? .fullScreen : .formSheet
        nav.popoverPresentationController?.sourceView = sourceView
        present(nav, animated: true, completion: nil)
    }
    
    func startNearbyAdvertising() {
        guard Defaults.isAutoInviteOn, Defaults.promptedAutoInvite, let code = model.raceCode else {
            return
        }
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        advertiser.start(hostName: GKLocalPlayer.local.alias, raceCode: code)
    }
    
}
