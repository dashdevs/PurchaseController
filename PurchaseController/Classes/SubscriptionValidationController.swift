//
//  SubscriptionValidationController.swift
//  Pods
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import Foundation

final class SubscriptionValidationController: NSObject {
    private let storage: Storage
    private let productIds: Set<String>
    
    fileprivate var accessibleSubscriptions: [InAppPurchase]? {
        return storage.fetchPurchasedProducts().filter({
            return productIds.contains($0.productId)
        })
    }
    
    init(with storage: Storage, subscription productIds: Set<String>) {
        self.storage = storage
        self.productIds = productIds
    }
}

// MARK: - Public

extension SubscriptionValidationController {
    
    /** Method used to validate available subs by filter
     *
     * - Parameter filter: closure used to determine what object should be included in result
     * - Returns: Array of `InAppPurchase` describing filtered subscriptions
     * - Throws: general filter(using: ) throw
     */
    func validate(by filter: InAppPurchaseFilter?) throws -> [InAppPurchase] {
        guard let subscriptions = accessibleSubscriptions else { return [] }
        guard let filter = filter else { return subscriptions }
        return try subscriptions.filter(filter)
    }
}
