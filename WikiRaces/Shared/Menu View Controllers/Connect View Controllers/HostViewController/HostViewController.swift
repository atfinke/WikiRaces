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


final internal class HostViewController: VisualEffectViewController {
    
    // MARK: - Types -
    

    enum ListenerUpdate {
        case start(match: GKMatch, settings: WKRGameSettings)
        case startSolo(settings: WKRGameSettings)
        case cancel
    }
    
    // MARK: - Properties -
    
    private let raceCodeGenerator = RaceCodeGenerator()
    private let advertiser = NearbyRaceAdvertiser()

    var match: GKMatch?
    var isQuitting = false
     
    var gameSettings = WKRGameSettings()
    
    lazy var model = PrivateRaceContentViewModel(settings: gameSettings)
    lazy var contentViewHosting = UIHostingController(
        rootView: PrivateRaceContentView(model: model))
    
    
    private let activityView = UIActivityIndicatorView(style: .medium)
    let listenerUpdate: (ListenerUpdate) -> Void
    
    // MARK: - Initalization -
    
    init(listenerUpdate: @escaping ((ListenerUpdate) -> Void)) {
        self.listenerUpdate = listenerUpdate
        super.init(nibName: nil, bundle: nil)
        
        let date = Date()
        raceCodeGenerator.new { [weak self] code in
            print(date.timeIntervalSinceNow)
            
            guard let self = self else { return }
          
            DispatchQueue.main.async {
                self.model.raceCode = code
                self.startNearbyAdvertising()
                self.startMatchmaking()
            }
        }
        
       
        title = "PRIVATE RACE"
        navigationItem.leftBarButtonItem = WKRUIBarButtonItem(systemName: "xmark",
                                                              target: self,
                                                              action: #selector(cancelMatch))

        let startButton = WKRUIBarButtonItem(systemName: "play.fill",
                                             target: self,
                                             action: #selector(startMatch))
        navigationItem.rightBarButtonItem = startButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(hostingView: contentViewHosting.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions -
    
    func sendMiniMessage(info: ConnectViewController.MiniMessage.Info) {
        let message = ConnectViewController.MiniMessage(info: info, uuid: UUID())
        guard let data = try? JSONEncoder().encode(message) else {
            fatalError()
        }
        try? match?.sendData(toAllPlayers: data, with: .reliable)
    }

    @objc
    func cancelMatch() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .hostCancelledPreMatch)

        isQuitting = true
        GKMatchmaker.shared().cancel()
        
        advertiser.stop()
        match?.delegate = nil
        sendMiniMessage(info: .cancelled)
        match?.disconnect()
        
        listenerUpdate(.cancel)
    }

    @objc
    func startMatch() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        advertiser.stop()
//        tableView.isUserInteractionEnabled = false

        activityView.sizeToFit()
        activityView.startAnimating()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        func sendStartMessage() {
            guard let match = match else { fatalError("match is nil") }
            GKMatchmaker.shared().finishMatchmaking(for: match)
            
            let message = ConnectViewController.StartMessage(hostName: GKLocalPlayer.local.alias, gameSettings: gameSettings)
            do {
                let data = try JSONEncoder().encode(message)
                try match.sendData(toAllPlayers: data, with: .reliable)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    self.listenerUpdate(.start(match: match, settings: self.gameSettings))
                }
            } catch {
                self.cancelMatch()
            }
        }
        
        if match == nil || match?.players.count == 0 {
            if Defaults.promptedSoloRacesStats {
                listenerUpdate(.startSolo(settings: gameSettings))
            } else {
                let controller = UIAlertController(title: "Solo Race", message: "Solo races will not count towards your stats.", preferredStyle: .alert)
                let startAction = UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
                    guard let self = self else { return }
                    self.listenerUpdate(.startSolo(settings: self.gameSettings))
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
    
    private func startNearbyAdvertising() {
        guard Defaults.isAutoInviteOn, let code = model.raceCode else {
            advertiser.stop()
            return
        }
        advertiser.start(hostName: GKLocalPlayer.local.alias, raceCode: code)
    }
    
}

