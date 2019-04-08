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
    
}
