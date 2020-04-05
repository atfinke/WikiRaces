//
//  PointerInteractionTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 3/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

class PointerInteractionTableViewCell: UITableViewCell {

    // MARK: - Initalization -

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if #available(iOS 13.4, *) {
            configurePointer()
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.4, *)
extension PointerInteractionTableViewCell: UIPointerInteractionDelegate {

    func configurePointer() {
        let interaction = UIPointerInteraction(delegate: self)
        addInteraction(interaction)
    }

    // MARK: - UIPointerInteractionDelegate -

    public func pointerInteraction(_ interaction: UIPointerInteraction,
                                   styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?
        if let interactionView = interaction.view {
            let targetedPreview = UITargetedPreview(view: interactionView)
            pointerStyle = UIPointerStyle(effect: UIPointerEffect.highlight(targetedPreview))
        }
        return pointerStyle
    }
}
