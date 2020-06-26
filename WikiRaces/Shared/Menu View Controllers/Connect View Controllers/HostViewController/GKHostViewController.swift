//
//  RevampHostViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//


import GameKit
import UIKit

import WKRKit
import WKRUIKit
import SwiftUI

final internal class GKHostViewController: VisualEffectViewController {
    
    // MARK: - Properties -
    
    private let raceCodeGenerator = RaceCodeGenerator()
    private let advertiser = NearbyRaceAdvertiser()
    
    var match: GKMatch?
    var isMatchmakingEnabled = true {
        didSet {
            if !isMatchmakingEnabled {
                advertiser.stop()
                GKMatchmaker.shared().cancel()
            }
        }
    }
    
    var gameSettings = WKRGameSettings()
    
    lazy var model = PrivateRaceContentViewModel(settings: gameSettings)
    lazy var contentViewHosting = UIHostingController(
        rootView: PrivateRaceContentView(
            model: model,
            cancelAction: cancelMatch,
            startMatch: startMatch))
    
    // MARK: - Initalization -
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let date = Date()
        raceCodeGenerator.new { [weak self] code in
            print(date.timeIntervalSinceNow)
            
            guard let self = self, self.isMatchmakingEnabled else { return }
            DispatchQueue.main.async {
                self.model.raceCode = code
                self.startNearbyAdvertising()
                self.startMatchmaking()
            }
        }
        
        view.alpha = 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(hostingView: contentViewHosting.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.view.alpha = 1
        }
    }

    // MARK: - Actions -
    
    func cancelMatch() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .hostCancelledPreMatch)
        
        isMatchmakingEnabled = false
        
        match?.delegate = nil
        sendMiniMessage(info: .cancelled)
        match?.disconnect()
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.alpha = 0
        }, completion: { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: false)
        })
    }
    
    func startMatch() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        
        model.matchStarting = true
        
        advertiser.stop()
        contentViewHosting.view.isUserInteractionEnabled = false
        
        func showMatch(for networkConfig: WKRPeerNetworkConfig, settings: WKRGameSettings) {
            let controller = GameViewController(network: networkConfig, settings: settings)
            let nav = WKRUINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            nav.modalTransitionStyle = .crossDissolve
            nav.isModalInPresentation = true
            present(nav, animated: true) { [weak self] in
                self?.view.alpha = 0
            }
        }
        
        func sendStartMessage() {
            guard let match = match else { fatalError("match is nil") }
            GKMatchmaker.shared().finishMatchmaking(for: match)
            
            let message = ConnectViewController.StartMessage(hostName: GKLocalPlayer.local.alias, gameSettings: gameSettings)
            do {
                let data = try JSONEncoder().encode(message)
                try match.sendData(toAllPlayers: data, with: .reliable)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    showMatch(for: .gameKit(match: match, isHost: true), settings: self.gameSettings)
                }
            } catch {
                self.cancelMatch()
            }
        }
        
        func startSolo() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showMatch(for: .solo(name: GKLocalPlayer.local.alias), settings: self.gameSettings)
                           }
            
        }
        
        if match == nil || match?.players.count == 0 {
            if Defaults.promptedSoloRacesStats {
                startSolo()
            } else {
                let controller = UIAlertController(title: "Solo Race", message: "Solo races will not count towards your stats.", preferredStyle: .alert)
                let startAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    startSolo()
                }
                controller.addAction(startAction)
                controller.addCancelAction(title: "Back")
                present(controller, animated: true, completion: nil)
                Defaults.promptedSoloRacesStats = true
            }
        } else {
            sendStartMessage()
        }
    }
    
    // MARK: - Other -
    
    private func startNearbyAdvertising() {
        guard Defaults.isAutoInviteOn, let code = model.raceCode else {
            advertiser.stop()
            return
        }
        advertiser.start(hostName: GKLocalPlayer.local.alias, raceCode: code)
    }
    
    func sendMiniMessage(info: ConnectViewController.MiniMessage.Info) {
        let message = ConnectViewController.MiniMessage(info: info, uuid: UUID())
        guard let data = try? JSONEncoder().encode(message) else {
            fatalError()
        }
        try? match?.sendData(toAllPlayers: data, with: .reliable)
    }
}

