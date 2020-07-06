//
//  MagicSubscription.swift
//  Magic
//
//  Created by Andrew Finke on 1/19/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import StoreKit

struct MagicSubscription {

    // MARK: - Types -

    enum Duration: String {
        case week, month, year

        var displayString: String {
            return rawValue.capitalized
        }
    }

    // MARK: - Properties -

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    let price: String
    let duration: Duration
    let raw: SKProduct
    let displayString: String

    // MARK: - Initalization -

    init?(_ product: SKProduct?) {
        guard let product = product else { return nil }

        MagicSubscription.priceFormatter.locale = product.priceLocale
        guard let price = MagicSubscription.priceFormatter.string(from: product.price),
              let subscriptionPeriod = product.subscriptionPeriod else { return nil }

        self.price = price
        switch subscriptionPeriod.unit {
        case .day, .week:
            duration = .week
        case .month:
            duration = .month
        case .year:
            duration = .year
        @unknown default:
            duration = .year
        }
        raw = product
        displayString = price + "\n" + duration.displayString
    }
}
