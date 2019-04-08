//
//  PendingRenewalInfo.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

struct PendingRenewalInfo: Codable {
    let expirationIntent: String
    let autoRenewProductId: String
    let originalTransactionId: String
    let isInBillingRetryPeriod: String
    let productId: String
    let autoRenewStatus: String
    
    enum CodingKeys: String, CodingKey {
        case expirationIntent = "expiration_intent"
        case autoRenewProductId = "auto_renew_product_id"
        case originalTransactionId = "original_transaction_id"
        case isInBillingRetryPeriod = "is_in_billing_retry_period"
        case productId = "product_id"
        case autoRenewStatus = "auto_renew_status"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        expirationIntent = try values.decode(String.self, forKey: .expirationIntent)
        autoRenewProductId = try values.decode(String.self, forKey: .autoRenewProductId)
        originalTransactionId = try values.decode(String.self, forKey: .originalTransactionId)
        isInBillingRetryPeriod = try values.decode(String.self, forKey: .isInBillingRetryPeriod)
        productId = try values.decode(String.self, forKey: .productId)
        autoRenewStatus = try values.decode(String.self, forKey: .autoRenewStatus)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expirationIntent, forKey: .expirationIntent)
        try container.encode(autoRenewProductId, forKey: .autoRenewProductId)
        try container.encode(originalTransactionId, forKey: .originalTransactionId)
        try container.encode(isInBillingRetryPeriod, forKey: .isInBillingRetryPeriod)
        try container.encode(productId, forKey: .productId)
        try container.encode(autoRenewStatus, forKey: .autoRenewStatus)

    }
    
}
