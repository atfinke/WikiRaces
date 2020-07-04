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

final internal class GKHostViewController: GKConnectViewController {
    
    // MARK: - Properties -
    
    let raceCodeGenerator = RaceCodeGenerator()
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
        super.init(isPlayerHost: true)
        startMatchmaking()
        WKRSeenFinalArticlesStore.resetRemotePlayersSeenFinalArticles()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sourceView.alpha = 0
        contentView.addSubview(sourceView)
        contentViewHosting.view.alpha = 0
        configure(hostingView: contentViewHosting.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.contentViewHosting.view.alpha = 1
        }
        
        guard !Defaults.promptedAutoInvite else {
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
        sourceView.center = CGPoint(x: contentView.center.x, y: contentView.center.y - 150)
    }
    
    // MARK: - Actions -
    
    func startMatch() {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        
        model.state = .raceStarting
        raceCodeGenerator.cancel()
        
        advertiser.stop()
        contentViewHosting.view.isUserInteractionEnabled = false
        
        func sendStartMessage() {
            guard let match = match else { fatalError("match is nil") }
            GKMatchmaker.shared().finishMatchmaking(for: match)
            os_log("%{public}s: sending start message", log: .gameKit, type: .info, #function)
            
            let message = GKConnectViewController.StartMessage(
                hostName: GKLocalPlayer.local.alias,
                gameSettings: model.settings)
            do {
                let data = try JSONEncoder().encode(message)
                try match.sendData(toAllPlayers: data, with: .reliable)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.transitionToGame(
                        for: .gameKitPrivate(match: match, isHost: true),
                        settings: self.model.settings)
                }
            } catch {
                self.cancelMatch()
            }
        }
        
        func startSolo() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.transitionToGame(for:
                    .solo(name: GKLocalPlayer.local.alias),
                                      settings: self.model.settings)
            }
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
        } else {
            sendStartMessage()
        }
        
        PlayerCloudKitLiveRaceManager.shared.savePlayerImages()
    }
    
    // MARK: - Other -
    
    private func presentModal(modal: HostContentView.Modal) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, "\(modal)")
        
        let controller: UIViewController
        switch modal {
        case .activity:
            guard  let code = model.raceCode, let url = URL(string: "WikiRaces://Invite?Code=\(code)") else {
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
