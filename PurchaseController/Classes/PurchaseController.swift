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
/// - loading: Notify handler if any action was started
/// - finish: Notify handler if action was finished
/// - none: Notify handler if no current actions presents
public enum PurchaseActionState {
    case loading
    case finish(PurchaseActionResult)
    case none
}

/// Defines action result state
///
/// - error: Notify handler if any error presents
/// - subscriptionValidationSucess: Notify handler if any subscription plan is valid
/// - retrieveSuccess: Notify handler if more than one products retrieved
/// - retrieveSuccessInvalidProducts: Notify handler of any retrieved invalid products
/// - purchaseSuccess: Notify handler if purchase was successfull
/// - restoreSuccess: Notify handler if restoring was successfull
/// - completionSuccess: Notify handler if transaction completion was successfull
/// - receiptValidationSuccess: Notify handler if receipt validation was successfull
public enum PurchaseActionResult {
    case error(PurchaseError)
    case subscriptionValidationSucess(ReceiptItem)
    case retrieveSuccess
    case retrieveSuccessInvalidProducts
    case purchaseSuccess
    case restoreSuccess
    case completionSuccess
    case receiptValidationSuccess
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
    
    /// Initializer with default non-sequre persistor
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
    ///   - persistor: Any object for persisting transactions anf products, should implement PurchasePersistor protocol
    public init(stateHandler: PurchaseStateHandler?, persistor: PurchasePersistor)  {
        self.persistor = persistor
        self.stateHandler = stateHandler
        self.purchaseActionState = .none
    }
    
    // MARK: - Public
    
    /// Filter function, used to access to local purchased products
    ///
    /// - Parameter filter: filter closure, used to comparing to PurchaseItem objects
    /// - Returns: array of PurchaseItem after filter applying
    /// - Throws: throws if no filter - compitable items exists
    public func localPurschasedProducts(by filter: (PurchaseItem) throws -> Bool) throws -> [PurchaseItem] {
        return try persistor.fetchPurchasedProducts().filter(filter)
    }
    
    /// Filter function, used to access to local products
    ///
    /// - Parameter filter: filter closure, used to comparing to SKProduct objects
    /// - Returns: array of SKProduct after filter applying
    /// - Throws: throws if no filter - compitable items exists
    public func localProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
        return try persistor.fetchProducts().filter(filter)
    }
    
    /// Function, used to retrieve available products from Apple side.
    /// Result items is storing to persistor.
    ///
    /// Notify handler with .retrieveSuccess if no error of invalid products retrieved
    ///
    /// Notify handler with .retrieveSuccessInvalidProducts if any invalid products retrieved,
    /// alog with storing valid products to persistor
    ///
    /// Notify handler with .error if any error retrieved
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
    /// Result items is storing to persistor.
    ///
    /// Notify handler with .restoreFailed if no restored items presents
    ///
    /// Notify handler with .finish(items) if success
    ///
    /// Notify handler with .restoreFailed if any error presents
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
    
    /// Function, used to add product to purchase queue
    /// Result items is storing to persistor.
    ///
    /// Notify handler with .noLocalProduct if no local product with given identifier presents
    ///
    /// Notify handler with .purchaseSuccess if items purchased
    ///
    /// Notify handler with .error if any error presents
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
    
    /// Function, used to verify receipt with validator
    /// Receipt is stored on appStoreReceiptURL path
    /// Validated Receipt dict is stroed in sessionReceipt
    /// More info here: https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt
    ///
    /// Notify handler with .receiptValidationSuccess if no error presents
    ///
    /// Notify handler with .error if any error presents
    ///
    /// - Parameters:
    ///   - sharedSecret: shared secret from Appstore Connect
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
                self.purchaseActionState = .finish(PurchaseActionResult.receiptValidationSuccess)
            case .error(let error):
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.asPurchaseError()))
            }
        }
    }
    
    /// Function, used to validate subscription with validator
    ///
    /// Notify handler with .noActiveSubscription if no aactive subscription presents for given id (did not purchased or expired)
    ///
    /// Notify handler with .subscriptionValidationSucess if presents active subscription for given id
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
    
    /// Function, used to complete previous transactions
    ///
    /// Notify handler with .completionSuccess when complete
    public func completeTransactions() {
        SwiftyStoreKit.completeTransactions(completion: { [unowned self] (_) in
             self.purchaseActionState = .finish(PurchaseActionResult.completionSuccess)
        })
    }
}
