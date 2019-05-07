//
//  PendingRenewalInfo.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

/// Type of expiration intent
///
/// - customerCanceled: Customer canceled their subscription
/// - billingError: Billing error; for example customer’s payment information was no longer valid.
/// - priceIncrease: Customer did not agree to a recent price increase.
/// - productNotAvailable: Product was not available for purchase at the time of renewal.
/// - unknownError: Unknown error.
enum ExpirationIntentType: Int, Codable {
    case customerCanceled
    case billingError
    case priceIncrease
    case productNotAvailable
    case unknownError
}

/// Type of auto renew status
///
/// - renew: Subscription will renew at the end of the current subscription period.
/// - turnedOff: Customer has turned off automatic renewal for their subscription
/// - notSpecified: Not Specified
enum AutoRenewStatus: Int, Codable {
    case renew
    case turnedOff
    case notSpecified
}

/// Item describes avaible to purchase object
struct PendingRenewalInfo: Codable {
    
    /// Expiration Intent - For an expired subscription, the reason for the subscription expiration.
    /// This key is only present for a receipt containing an expired auto-renewable subscription.
    /// You can use this value to decide whether to display appropriate messaging in your app for customers to resubscribe.
    let expirationIntent: ExpirationIntentType
    
    /// Subscription Auto Renew Preference - This key is only present for auto-renewable subscription receipts.
    /// The value for this key corresponds to the productIdentifier property of the product that the customer’s subscription renews.
    /// You can use this value to present an alternative service level to the customer before the current subscription period ends.
    let autoRenewProductId: String
    
    /// Original Transaction Identifier - This value is the same for all receipts that have been generated for a specific subscription. This value is useful for relating together multiple iOS 6 style transaction receipts for the same individual customer’s subscription.
    let originalTransactionId: String
    
    ///Subscription Retry Flag - This key is only present for auto-renewable subscription receipts. If the customer’s subscription failed to renew because the App Store was unable to complete the transaction, this value will reflect whether or not the App Store is still trying to renew the subscription.
    let isInBillingRetryPeriod: Bool
    
    /// Purchase Identifier - unique id of purchase object from appstore connect
    let productId: String
    
    /// Auto Renew Status info
    let autoRenewStatus: AutoRenewStatus
    
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
        if let expirationIntentValue = Int(try values.decode(String.self, forKey: .expirationIntent)), let type = ExpirationIntentType(rawValue: expirationIntentValue) {
            expirationIntent = type
        } else {
            expirationIntent = ExpirationIntentType.unknownError
        }
        autoRenewProductId = try values.decode(String.self, forKey: .autoRenewProductId)
        originalTransactionId = try values.decode(String.self, forKey: .originalTransactionId)
        isInBillingRetryPeriod = try Bool(values.decode(String.self, forKey: .isInBillingRetryPeriod)) ?? false
        productId = try values.decode(String.self, forKey: .productId)
        if let autoRenewStatusValue = Int(try values.decode(String.self, forKey: .autoRenewStatus)), let type = AutoRenewStatus(rawValue: autoRenewStatusValue) {
            autoRenewStatus = type
        } else {
            autoRenewStatus = .notSpecified
        }
    }
    
}
