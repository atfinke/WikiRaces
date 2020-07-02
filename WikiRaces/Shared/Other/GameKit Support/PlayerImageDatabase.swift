//
//  PlayerImageDatabase.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import SwiftUI
import os.log

class PlayerImageDatabase {

    // MARK: - Properties -

    static var shared = PlayerImageDatabase()
    private var dict = [String: Image]()

    private(set) var hasValidLocalPlayerImage = false

    // MARK: - Initalization -

    private init() {}

    // MARK: - Helpers -

    func connected(to player: GKPlayer, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            let placeholder = PlayerPlaceholderImageRenderer.render(name: player.displayName)
            os_log("%{public}s: generated placeholder for %{public}s", log: .matchSupport, type: .info, #function, player.alias)
            self.dict[player.alias] = Image(uiImage: placeholder)

            player.loadPhoto(for: .small) { photo, _ in
                PlayerAnonymousMetrics.log(
                    event: .finishedProfilePhotoFetch,
                    attributes: [
                        "Success": photo != nil ? 1 : 0
                    ])

                guard let photo = photo else {
                    os_log("%{public}s: load photo failed for %{public}s", log: .matchSupport, type: .error, #function, player.alias)
                    completion?()
                    return
                }
                os_log("%{public}s: load photo success for %{public}s", log: .matchSupport, type: .info, #function, player.alias)
                
                if player.alias == GKLocalPlayer.local.alias {
                    self.hasValidLocalPlayerImage = true
                }
                self.dict[player.alias] = Image(uiImage: photo)
                completion?()
            }
        }
    }

    func image(for playerID: String) -> Image {
        guard let image = dict[playerID] else {
            #if MULTIWINDOWDEBUG
            let placeholder = PlayerPlaceholderImageRenderer.render(name: playerID)
            self.dict[playerID] = Image(uiImage: placeholder)
            return Image(uiImage: placeholder)
            #endif
            fatalError()
        }
        return image
    }
}
