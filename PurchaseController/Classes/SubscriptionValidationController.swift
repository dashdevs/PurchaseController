//
//  SubscriptionValidationController.swift
//  Pods
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import Foundation

public typealias SubscriptionFilter = (InAppPurchase) throws -> Bool

final class SubscriptionValidationController: NSObject {
    private let storage: Storage
    private let productIds: Set<String>
    
    fileprivate lazy var accessibleSubscriptions: [InAppPurchase]? = {
        return storage.sessionReceipt?.inApp?.filter({
            return productIds.contains($0.productId)
        })
    }()
    
    init(with storage: Storage, subscription productIds: Set<String>) {
        self.storage = storage
        self.productIds = productIds
    }
}

// MARK: - Public

extension SubscriptionValidationController {
    func validate(by filter: SubscriptionFilter?) throws -> [InAppPurchase] {
        guard let subscriptions = accessibleSubscriptions else { return [] }
        guard let filter = filter else { return subscriptions }
        return try subscriptions.filter(filter)
    }
}
