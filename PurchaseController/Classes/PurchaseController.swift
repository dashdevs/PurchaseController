//
//  PurchaseController.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

///  Defines action state
///
/// - loading: Notifies handler if any action was started
/// - finish: Notifies handler if action was finished
/// - none: Notifies handler if no current actions presents
public enum PurchaseActionState {
    case loading
    case finish(PurchaseActionResult)
    case none
}

/// Defines action result state
///
/// - error: Notifies handler if any error presents
/// - subscriptionValidationSucess: Notifies handler if any subscription plan is valid
/// - retrieveSuccess: Notifies handler if more than one products retrieved
/// - retrieveSuccessInvalidProducts: Notifies handler of any retrieved invalid products
/// - purchaseSuccess: Notifies handler if purchase was successfull
/// - restoreSuccess: Notifies handler if restoring was successfull
/// - completionSuccess: Notifies handler if transaction completion was successfull
/// - receiptValidationSuccess: Notifies handler if receipt validation was successfull
/// - receiptSerializationError: Notifies handler if a receipt can not serialization
public enum PurchaseActionResult {
    case error(PurchaseError)
    case subscriptionValidationSucess(ReceiptItem)
    case retrieveSuccess
    case retrieveSuccessInvalidProducts
    case purchaseSuccess
    case restoreSuccess
    case completionSuccess
    case receiptValidationSuccess
    case receiptSerializationError
}

public protocol PurchaseStateHandler {
    /// Protocol method to notify of purchase actions state changing
    ///
    /// - Parameters:
    ///   - newState: state, that becomes current
    ///   - state: last current state to compare with
    func update(newState: PurchaseActionState, from state: PurchaseActionState)
}

@available(iOS 10.0, *)
public final class PurchaseController {
    
    /// receipt dictionary. Availadble ONLY after verifyReceipt(sharedSecret: isSandbox:) call.
    private(set) var sessionReceipt: ReceiptInfo?
    private var persistor: PurchasePersistor
    private var stateHandler: PurchaseStateHandler?
    private var purchaseActionState: PurchaseActionState {
        willSet {
            stateHandler?.update(newState: newValue, from: purchaseActionState)
        }
    }
    private var receiptValidationResponse: ReceiptValidationResponse?
    
    /// Initializer with default non-secure persistor
    ///
    /// - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
    public init(stateHandler: PurchaseStateHandler?)  {
        self.persistor = PurchasePersistorImplementation()
        self.stateHandler = stateHandler
        self.purchaseActionState = .none
    }
    
    /// Initializer with user's persistor
    ///
    /// - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
    /// - Parameter persistor: Any object for persisting transactions and products, should implement PurchasePersistor protocol
    public init(stateHandler: PurchaseStateHandler?, persistor: PurchasePersistor)  {
        self.persistor = persistor
        self.stateHandler = stateHandler
        self.purchaseActionState = .none
    }
    
    // MARK: - Public
    
    /// Filter function, used to access to local purchased products
    ///
    /// - Parameter filter: filter closure used for comparing PurchaseItem objects
    /// - Returns: array of PurchaseItem after filter applying
    public func localPurschasedProducts(by filter: (PurchaseItem) throws -> Bool) throws -> [PurchaseItem] {
        return try persistor.fetchPurchasedProducts().filter(filter)
    }
    
    /// Filter function used to access to local products
    ///
    /// - Parameter filter: filter closure, used to comparing to SKProduct objects
    /// - Returns: array of SKProduct after filter applying
    public func localProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
        return try persistor.fetchProducts().filter(filter)
    }
    
    /// Function used to retrieve available products from StoreKit.
    /// Result items are storing using persistor object.
    ///
    /// Notifies handler with .retrieveSuccess state if no error or invalid products retrieved
    ///
    /// Notifies handler with .retrieveSuccessInvalidProducts state if any invalid products retrieved,
    /// along with storing valid products to persistor
    ///
    /// Notifies handler with .error state if any error retrieved
    ///
    /// - Parameter products: Set of products identifiers, whose needs to be retrieved
    public func retrieve(products: Set<String>) {
        self.purchaseActionState = .loading
        SwiftyStoreKit.retrieveProductsInfo(products) { [unowned self] (results) in
            if let error = results.error {
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.asPurchaseError()))
                return
            }
            self.persistor.persist(products: Array(results.retrievedProducts))
            if results.invalidProductIDs.count > 0 {
                self.purchaseActionState = .finish(PurchaseActionResult.retrieveSuccessInvalidProducts)
                return
            }
            self.purchaseActionState = .finish(PurchaseActionResult.retrieveSuccess)
        }
    }
    
    /// Function, used to restore available products from Apple side.
    /// Result items are stored using persistor object.
    ///
    /// Notifies handler with .restoreFailed if no restored items presents
    ///
    /// Notifies handler with .finish(items) if success
    ///
    /// Notifies handler with .restoreFailed if any error presents
    public func restore() {
        self.purchaseActionState = .loading
        SwiftyStoreKit.restorePurchases { [unowned self] (results) in
            let items = results.restoredPurchases.makeItems(with: self.persistor)
            if items.isEmpty {
                self.purchaseActionState = .finish(PurchaseActionResult.error(.restoreFailed))
                return
            }
            self.persistor.persistPurchased(products: items)
            if let error = results.restoreFailedPurchases.first?.0 {
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.asPurchaseError()))
                return
            }
            self.purchaseActionState = .finish(PurchaseActionResult.restoreSuccess)
        }
    }
    
    /// Function used to add product to purchase queue.
    /// Result items are stored using persistor object.
    ///
    /// Notifies handler with .noLocalProduct state if no local product with given identifier exists
    ///
    /// Notifies handler with .purchaseSuccess state if items purchased
    ///
    /// Notifies handler with .error if any error occured
    ///
    /// - Parameter identifier: identifier of product to purchase
    public func purchase(with identifier: String) {
        self.purchaseActionState = .loading
        guard let localСompared = try? localProducts(by: { $0.productIdentifier == identifier }),
            let product = localСompared.first else {
            self.purchaseActionState = .finish(PurchaseActionResult.error(.noLocalProduct))
            return 
        }
        SwiftyStoreKit.purchaseProduct(product) { [unowned self] (results) in
            switch results {
            case .success(let purchase):
                let item = PurchaseItem(purchaseDeatils: purchase)
                self.persistor.persistPurchased(products: [item])
                self.purchaseActionState = .finish(PurchaseActionResult.purchaseSuccess)
            case .error(let error):
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.asPurchaseError()))
            }
        }
    }
    
    /// Function used to verify receipt using validator object.
    /// Receipt is stored on appStoreReceiptURL path.
    /// Validated receipt dict is stored in sessionReceipt.
    /// More info here: https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt.
    ///
    /// Notifies handler with .receiptSerializationError if a receipt can not serialization
    ///
    /// Notifies handler with .receiptValidationSuccess state if no error occured
    ///
    /// Notifies handler with .error if any error occured
    ///
    /// - Parameters:
    ///   - sharedSecret: shared secret from Appstore Connect.
    ///     More info here: https://www.appypie.com/faqs/how-can-i-get-shared-secret-key-for-in-app-purchase
    ///   - isSandbox: defines is there sandbox environment or not
    public func verifyReceipt(sharedSecret: String, isSandbox: Bool = true) {
        self.purchaseActionState = .loading
        let appleValidator = AppleReceiptValidator(service: isSandbox ? .sandbox : .production,
                                                   sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { [unowned self] result in
            switch result {
            case .success(let receipt):
                self.sessionReceipt = receipt
                guard let data = try? JSONSerialization.data(withJSONObject: receipt) else {
                    self.purchaseActionState = .finish(PurchaseActionResult.receiptSerializationError)
                    return
                }
                self.receiptValidationResponse = RecipientValidationHelper.createRecipientValidation(from: data)
                self.purchaseActionState = .finish(PurchaseActionResult.receiptValidationSuccess)
            case .error(let error):
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.asPurchaseError()))
            }
        }
    }
    
    /// Function used to validate subscription using validatoro object.
    ///
    /// Notifies handler with .noActiveSubscription state if no active subscription exists for given id (did not purchased or expired)
    ///
    /// Notifies handler with .subscriptionValidationSucess state if presents active subscription for given id
    ///
    /// - Parameters:
    ///   - productID: product id of subscription plan
    ///   - type: SubscriptionType (autoRenewable or nonRenewing)
    public func validateSubscription(productID: String, type: SubscriptionType) {
        self.purchaseActionState = .loading
        guard let receipt = self.sessionReceipt else {
            self.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.noReceiptData))
            return
        }
        
        let purchaseResult = SwiftyStoreKit.verifySubscription(
            ofType: type,
            productId: productID,
            inReceipt: receipt)
        switch purchaseResult {
        case .purchased(_, let items):
            let sorted = items.sorted(by: { (lo, ro) -> Bool in
                return lo.purchaseDate.timeIntervalSince1970 > ro.purchaseDate.timeIntervalSince1970
            })
            guard let latestActualSubscription = sorted.first else {
                self.purchaseActionState = .finish(PurchaseActionResult.error(.noActiveSubscription))
                return
            }
            self.purchaseActionState = .finish(PurchaseActionResult.subscriptionValidationSucess(latestActualSubscription))
        case .notPurchased, .expired(_, _):
            self.purchaseActionState = .finish(PurchaseActionResult.error(.noActiveSubscription))
        }
    }
    
    /// Function used to complete previous transactions
    ///
    /// Notifies handler with .completionSuccess state when complete
    public func completeTransactions() {
        SwiftyStoreKit.completeTransactions(completion: { [unowned self] (_) in
            self.purchaseActionState = .finish(PurchaseActionResult.completionSuccess)
        })
    }
}
