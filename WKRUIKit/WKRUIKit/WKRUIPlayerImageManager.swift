//
//  WKRUIPlayerImageManager.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 7/2/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import GameKit
import SwiftUI
import os.log

public class WKRUIPlayerImageManager {

    // MARK: - Types -

    public struct Container: Codable {
        let items: [String: Data]

        init(connectedPlayerImages: [String: UIImage], localPlayerImage: UIImage) {
            var mapped = [String: Data]()
            func add(image: UIImage, for playerID: String) {
                mapped[playerID] = image.jpegData(compressionQuality: 0.7)
            }
            connectedPlayerImages.forEach { add(image: $0.value, for: $0.key) }
            add(image: localPlayerImage, for: GKLocalPlayer.local.alias)
            self.items = mapped
        }
    }

    // MARK: - Properties -

    public static var shared = WKRUIPlayerImageManager()

    private var connectedPlayerImages = [String: UIImage]()
    private var localPlayerImage: UIImage?

    public private(set) var isLocalPlayerImageFromGameCenter = false

    // MARK: - Initalization -

    private init() {}

    // MARK: - Helpers -

    public func connected(to player: GKPlayer, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            let placeholder = WKRUIPlayerPlaceholderImageRenderer.render(name: player.displayName)
            os_log("%{public}s: generated placeholder for %{public}s", log: .imageManager, type: .info, #function, player.alias)

            self.update(image: placeholder, for: player.alias)

            player.loadPhoto(for: .small) { photo, _ in
                guard let photo = photo else {
                    os_log("%{public}s: load photo failed for %{public}s", log: .imageManager, type: .error, #function, player.alias)
                    completion?()
                    return
                }
                os_log("%{public}s: load photo success for %{public}s", log: .imageManager, type: .info, #function, player.alias)

                if player == GKLocalPlayer.local {
                    self.isLocalPlayerImageFromGameCenter = true
                }

                self.update(image: photo, for: player.alias)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    completion?()
                }
            }
        }
    }
    
    @discardableResult
    private func generatePlaceholder(for player: String) -> UIImage {
        let placeholder = WKRUIPlayerPlaceholderImageRenderer.render(name: player)
        os_log("%{public}s: generated placeholder for %{public}s", log: .imageManager, type: .info, #function, player)
        update(image: placeholder, for: player)
        return placeholder
    }

    private func update(image: UIImage, for playerID: String) {
        if playerID == GKLocalPlayer.local.alias {
            localPlayerImage = image
        } else {
            connectedPlayerImages[playerID] = image
        }
    }

    public func image(for player: String) -> UIImage {
        if player == GKLocalPlayer.local.displayName, let image = localPlayerImage {
            return image
        } else if let image = connectedPlayerImages[player] {
            return image
        } else {
            return generatePlaceholder(for: player)
        }
    }

    public func clearConnectedPlayers() {
        connectedPlayerImages.removeAll()
    }

    public func container() -> Container {
        guard let image = localPlayerImage else { fatalError() }
        return Container(connectedPlayerImages: connectedPlayerImages, localPlayerImage: image)
    }
}
