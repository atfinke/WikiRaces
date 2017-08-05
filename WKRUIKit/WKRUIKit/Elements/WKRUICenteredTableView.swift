//
//  WKRUICenteredTableView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUICenteredTableView: UITableView {

    // MARK: - View Life Cycle

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        allowsSelection = false
        alwaysBounceVertical = false
        separatorColor = UIColor.clear
        backgroundColor = UIColor.clear
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        centerContents()
    }

    // MARK: - Table View Overrides

    public override func reloadData() {
        super.reloadData()
        centerContents()
    }

    // MARK: - Helpers

    private func centerContents() {
        let totalHeight = bounds.height
        let contentHeight = contentSize.height

        let adjustedInset = UIEdgeInsets(top: ceil(totalHeight/2 - contentHeight/2 - 64), left: 0, bottom: 0, right: 0)
        contentInset = contentHeight < totalHeight ? adjustedInset : UIEdgeInsets.zero
    }
}
