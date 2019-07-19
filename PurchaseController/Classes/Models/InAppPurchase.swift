//
//  InAppPurchase.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import SwiftyStoreKit

/// Representation of inapp purchase
public struct InAppPurchase: ReadableDebugStringProtocol {
    
    // MARK: - Properties
    
    /// The number of items purchased.
    public let quantity: Int
    /// The product identifier of the item that was purchased.
    public let productId: String
    /// The transaction identifier of the item that was purchased.
    public let transactionId: String
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    public let originalTransactionId: String?

    /// The date and time that the item was purchased.
    public let purchaseDate: Date?
    public let purchaseDateMs: TimeInterval?
    public let purchaseDatePst: Date?

    /// For a transaction that restores a previous transaction, the date of the original transaction.
    public let originalPurchaseDate: Date?
    public let originalPurchaseDateMs: TimeInterval?
    public let originalPurchaseDatePst: Date?
    
    /// The date that the app receipt expires.
    public let expiresDate: Date?
    public let expiresDateMs: TimeInterval?
    public let expiresDatePst: Date?

    /// For an expired subscription, the reason for the subscription expiration.
    public let subscriptionExpirationIntent: SubscriptionExpirationIntent?
    
    /// For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
    public let subscriptionRetryFlag: SubscriptionRetryFlag?

    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    public let cancellationDate: Date?

    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    public let cancellationReason: CancellationReason?
    
    /// A string that the App Store uses to uniquely identify the application that created the transaction.
    public let appItemId: String?
    
    /// This key is not present for receipts created in the test environment. Use this value to identify the version of the app that the customer bought.
    public let externalVersionIdentifier: String?
    
    /// For a subscription, whether or not it is in the free trial period.
    public let isTrialPeriod: Bool?
    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    public let isInIntroOfferPeriod: Bool?

    /// The primary key for identifying subscription purchases.
    public let webOrderLineItemId: String?
    
    /// The current renewal status for the auto-renewable subscription.
    public let subscriptionAutoRenewStatus: SubscriptionAutoRenewStatus?
    
    /// The current renewal preference for the auto-renewable subscription.
    public let subscriptionAutoRenewPreference: String?
    
    /// The current price consent status for a subscription price increase.
    public let subscriptionPriceConsentStatus: SubscriptionPriceConsentStatus?

    /// Payment transaction object
    public var purchaseTransaction: PaymentTransaction {
        let date: Date? = {
            guard let timeInterval = purchaseDateMs else { return purchaseDate}
            return Date(timeIntervalSince1970: timeInterval)
        }()
        return ReceiptTransaction(transactionDate: date,
                                  transactionState: .purchased,
                                  transactionIdentifier: transactionId,
                                  downloads: [])
    }
    
    /// Original payment transaction object
    public var originalPurchaseTransaction: PaymentTransaction {
        let date: Date? = {
            guard let timeInterval = originalPurchaseDateMs else { return originalPurchaseDate}
            return Date(timeIntervalSince1970: timeInterval)
        }()
        return ReceiptTransaction(transactionDate: date,
                                  transactionState: .purchased,
                                  transactionIdentifier: originalTransactionId,
                                  downloads: [])
    }
    
    // MARK: - Lifecycle
    
    public init?(quantity: Int?,
          productIdentifier: String?,
          transactionIdentifier: String?,
          originalTransactionIdentifier: String?,
          purchaseDate: Date?,
          originalPurchaseDate: Date?,
          subscriptionExpirationDate: Date?,
          subscriptionIntroductoryPricePeriod: Bool?,
          cancellationDate: Date?,
          webOrderLineItemId: String?) {
        guard let quantity = quantity,
            let productIdentifier = productIdentifier,
            let transactionIdentifier = transactionIdentifier else {
                return nil
        }
        
        self.quantity = quantity
        self.productId = productIdentifier
        self.transactionId = transactionIdentifier
        self.originalTransactionId = originalTransactionIdentifier
        
        self.purchaseDate = purchaseDate
        self.purchaseDatePst = purchaseDate
        self.purchaseDateMs = purchaseDate?.timeIntervalSince1970
        
        self.originalPurchaseDate = originalPurchaseDate
        self.originalPurchaseDatePst = originalPurchaseDate
        self.originalPurchaseDateMs = originalPurchaseDate?.timeIntervalSince1970

        self.expiresDate = subscriptionExpirationDate
        self.expiresDatePst = subscriptionExpirationDate
        self.expiresDateMs = subscriptionExpirationDate?.timeIntervalSince1970

        self.isInIntroOfferPeriod = subscriptionIntroductoryPricePeriod
        self.cancellationDate = cancellationDate
        self.webOrderLineItemId = webOrderLineItemId

        self.subscriptionExpirationIntent = nil
        self.subscriptionRetryFlag = nil
        self.cancellationReason = nil
        self.appItemId = nil
        self.externalVersionIdentifier = nil
        self.isTrialPeriod = nil
        self.subscriptionAutoRenewStatus = nil
        self.subscriptionAutoRenewPreference = nil
        self.subscriptionPriceConsentStatus = nil
    }
}

// MARK: - Codable
extension InAppPurchase: Codable {
    enum CodingKeys: String, CodingKey {
        case quantity
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDate = "purchase_date"
        case purchaseDateMs = "purchase_date_ms"
        case purchaseDatePst = "purchase_date_pst"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMs = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case expiresDate = "expires_date"
        case expiresDateMs = "expires_date_ms"
        case expiresDatePst = "expires_date_pst"
        
        case subscriptionExpirationIntent = "expiration_intent"
        case subscriptionRetryFlag = "is_in_billing_retry_period"
        case cancellationDate = "cancellation_date"
        case cancellationReason = "cancellation_reason"
        case appItemId = "app_item_id"
        case externalVersionIdentifier = "version_external_identifier"
        
        case isTrialPeriod = "is_trial_period"
        case isInIntroOfferPeriod = "is_in_intro_offer_period"
        
        case webOrderLineItemId = "web_order_line_item_id"
        
        case subscriptionAutoRenewStatus = "auto_renew_status"
        case subscriptionAutoRenewPreference = "auto_renew_product_id"
        case subscriptionPriceConsentStatus = "price_consent_status"
    }

   public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        quantity = Int(try values.decode(String.self, forKey: .quantity)) ?? 0
        productId = try values.decode(String.self, forKey: .productId)
        transactionId = try values.decode(String.self, forKey: .transactionId)
        originalTransactionId = try values.decode(String.self, forKey: .originalTransactionId)
        
        purchaseDate = try values.decodeIfPresent(Date.self, forKey: .purchaseDate)
        purchaseDatePst = try values.decodeIfPresent(Date.self, forKey: .purchaseDatePst)
        purchaseDateMs = {
            guard let str = try? values.decode(String.self, forKey: .purchaseDateMs) else { return nil }
            return TimeInterval(millisecondsString: str)
        }()

        originalPurchaseDate = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDate)
        originalPurchaseDatePst = try values.decodeIfPresent(Date.self, forKey: .originalPurchaseDatePst)
        originalPurchaseDateMs = {
            guard let str = try? values.decode(String.self, forKey: .originalPurchaseDateMs) else { return nil }
            return TimeInterval(millisecondsString: str)
        }()

        expiresDate = try values.decodeIfPresent(Date.self, forKey: .expiresDate)
        expiresDatePst = try values.decodeIfPresent(Date.self, forKey: .expiresDatePst)
        expiresDateMs = {
            guard let str = try? values.decode(String.self, forKey: .expiresDateMs) else { return nil }
            return TimeInterval(millisecondsString: str)
        }()
        
        subscriptionExpirationIntent = try values.decodeIfPresent(SubscriptionExpirationIntent.self, forKey: .subscriptionExpirationIntent)
        subscriptionRetryFlag = try values.decodeIfPresent(SubscriptionRetryFlag.self, forKey: .subscriptionRetryFlag)
        
        cancellationDate = try values.decodeIfPresent(Date.self, forKey: .cancellationDate)
        cancellationReason = try values.decodeIfPresent(CancellationReason.self, forKey: .cancellationReason)
        
        appItemId = try values.decodeIfPresent(String.self, forKey: .appItemId)
        externalVersionIdentifier = try values.decodeIfPresent(String.self, forKey: .externalVersionIdentifier)
        
        if let isTrialPeriodString = try values.decodeIfPresent(String.self, forKey: .isTrialPeriod) {
            isTrialPeriod = Bool(isTrialPeriodString)
        } else{
            isTrialPeriod = nil
        }
        if let isInIntroOfferPeriodString = try values.decodeIfPresent(String.self, forKey: .isInIntroOfferPeriod) {
            isInIntroOfferPeriod = Bool(isInIntroOfferPeriodString)
        } else {
            isInIntroOfferPeriod = nil
        }
        webOrderLineItemId = try values.decodeIfPresent(String.self, forKey: .webOrderLineItemId)
        
        subscriptionAutoRenewStatus = try values.decodeIfPresent(SubscriptionAutoRenewStatus.self, forKey: .subscriptionAutoRenewStatus)
        subscriptionAutoRenewPreference = try values.decodeIfPresent(String.self, forKey: .subscriptionAutoRenewPreference)
        subscriptionPriceConsentStatus = try values.decodeIfPresent(SubscriptionPriceConsentStatus.self, forKey: .subscriptionPriceConsentStatus)
    }
}

extension TimeInterval {
    /// Use to convert TimeInterval to seconds
    private struct Constants {
        static let thousand: Double = 1000
    }
    
    init?(millisecondsString: String) {
        guard let milliseconds = TimeInterval(millisecondsString) else {
            return nil
        }
        self = milliseconds / Constants.thousand
    }
}
