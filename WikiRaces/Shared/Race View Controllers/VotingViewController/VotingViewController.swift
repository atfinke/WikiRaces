//
//  VotingViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit
import SwiftUI

final internal class VotingViewController: VisualEffectViewController {

    // MARK: - Types -

    enum ListenerUpdate {
        case voted(WKRPage)
        case quit
    }
    
    private enum ViewState {
        case pre, voting, post
    }
    
    // MARK: - Properties -
    
    private(set) var model = VotingContentViewModel()
    lazy var contentViewHosting = UIHostingController(
        rootView: VotingContentView(model: model, tapped: { [weak self] item in
            self?.listenerUpdate?(.voted(item.page))
            UISelectionFeedbackGenerator().selectionChanged()
        }))

    var listenerUpdate: ((ListenerUpdate) -> Void)?
    var quitAlertController: UIAlertController?

    private var state: ViewState = .pre
    private var isFinalTextVisible = false
    var votingState: WKRVotingState? {
        didSet {
            model.update(votingState: votingState)
        }
    }

    var voteTimeRemaing = 100 {
        didSet {
            let timeString = "VOTING ENDS IN " + voteTimeRemaing.description + " S"
            switch state {
            case .pre:
                model.footerOpacity = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.model.footerTopText = "TAP ARTICLE TO VOTE"
                    self.model.footerBottomText = timeString
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.model.footerOpacity = 1
                }
                model.isVotingEnabled = true
                state = .voting
            case .voting:
                if voteTimeRemaing == 0 {
                    model.footerOpacity = 0
                } else {
                    model.footerBottomText = timeString
                }
            case .post:
                model.footerTopText = "GET READY"
                model.footerBottomText = "RACE STARTS IN " + voteTimeRemaing.description + " S"
                if !isFinalTextVisible {
                    isFinalTextVisible = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.model.footerOpacity = 1
                    }
                }
            }
        }
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "VOTING"
        
        addChild(contentViewHosting)
        configure(hostingView: contentViewHosting.view)
        contentViewHosting.didMove(toParent: self)
        
        model.footerTopText = "PREPARING"
        model.footerBottomText = "VOTING STARTS SOON"

        navigationItem.rightBarButtonItem = WKRUIBarButtonItem(
            systemName: "xmark",
            target: self,
            action: #selector(doneButtonPressed))
    }

    // MARK: - Actions -

    @objc func doneButtonPressed(_ sender: Any) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        guard let alertController = quitAlertController else {
            PlayerAnonymousMetrics.log(event: .backupQuit,
                                       attributes: ["RawGameState": WKRGameState.voting.rawValue])
            self.listenerUpdate?(.quit)
            return
        }
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Helpers -

    func finalPageSelected(_ page: WKRPage) {
        model.selected(finalPage: page)
        state = .post
    }

}
