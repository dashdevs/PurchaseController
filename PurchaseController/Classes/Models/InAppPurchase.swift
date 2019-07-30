//
//  InAppPurchase.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit

/// Representation of inapp purchase
public struct InAppPurchase: ReadableDebugStringProtocol, DataFormatsEncodable {
    
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
    
    // MARK: - Lifecycle
    
    public init?(paymentModel: PaymentModel,
                 transaction: SKPaymentTransaction,
                 originalTransaction: SKPaymentTransaction?) {
        guard let transactionId = transaction.transactionIdentifier else { return nil }
        self.quantity = paymentModel.payment.quantity
        self.productId = paymentModel.product.productIdentifier
        self.transactionId = transactionId
        self.originalTransactionId = originalTransaction?.transactionIdentifier
        
        self.purchaseDate = transaction.transactionDate
        self.purchaseDatePst = transaction.transactionDate
        self.purchaseDateMs = transaction.transactionDate?.timeIntervalSince1970
        
        self.originalPurchaseDate = originalTransaction?.transactionDate
        self.originalPurchaseDatePst = originalTransaction?.transactionDate
        self.originalPurchaseDateMs = originalTransaction?.transactionDate?.timeIntervalSince1970
        
        if #available(iOS 11.2, *),
            let period = paymentModel.product.subscriptionPeriod,
            let purchaseDateMs = purchaseDateMs  {
            self.expiresDate = Date(timeIntervalSince1970: purchaseDateMs + period.timeInterval)
            self.expiresDatePst = nil
            self.expiresDateMs = purchaseDateMs + period.timeInterval
        } else {
            self.expiresDate = nil
            self.expiresDatePst = nil
            self.expiresDateMs = nil
        }
       
        
        self.isInIntroOfferPeriod = nil
        self.cancellationDate = nil
        self.webOrderLineItemId = nil
        
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

// MARK: - Public Static

public extension InAppPurchase {
    /// Function for purchase creation
    ///
    /// - Parameters:
    ///   - transaction: StoreKit product transaction
    ///   - persistance: Object that conforms to persistance protocol
    /// - Returns: Describes item available to read
    static func create(with transaction: SKPaymentTransaction,
                       persistance: PurchasePersistor) -> InAppPurchase? {
        guard let product = persistance.fetchProducts().first(where: { $0.productIdentifier == transaction.payment.productIdentifier}) else {
            return nil
        }
        return InAppPurchase(quantity: transaction.payment.quantity,
                             productIdentifier: product.productIdentifier,
                             transactionIdentifier: transaction.transactionIdentifier,
                             originalTransactionIdentifier: transaction.original?.transactionIdentifier,
                             purchaseDate: transaction.transactionDate,
                             originalPurchaseDate: transaction.original?.transactionDate,
                             subscriptionExpirationDate: nil,
                             subscriptionIntroductoryPricePeriod: nil,
                             cancellationDate: nil,
                             webOrderLineItemId: nil)
        
    }
    
    /// Function for retrieving transactionReceipt
    ///
    /// - NOTE: deprecated, preffer not to use it
    /// - Returns: transactionReceipt data
    func directReceipt() -> Data? {
        guard let transaction = PaymentQueueController.transaction(of: self) else { return nil }
        return DirectReceiptFetcher.directReceipt(of: transaction)
    }
    
    /// Function for retrieving transactionReceipt as .utf8 string
    ///
    /// - NOTE: deprecated, preffer not to use it
    /// - Returns: transactionReceipt as string
    func directReceiptString() -> String? {
        guard let data = self.directReceipt() else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension InAppPurchase: Hashable {}

extension Collection where Element == SKPaymentTransaction {
    internal func makeItems(with persistance: PurchasePersistor) -> [InAppPurchase] {
        return self.compactMap { transaction -> InAppPurchase? in
            return InAppPurchase.create(with: transaction, persistance: persistance)
        }
    }
}
