//
//  PurchaseController.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit

@available(iOS 10.0, *)

public typealias InAppPurchaseFilter = (InAppPurchase) throws -> Bool
public typealias ProductFilter = (SKProduct) throws -> Bool

/**  Defines action state

 - loading: Notifies handler if any action was started
 - finish: Notifies handler if action was finished
 - none: Notifies handler if no current actions presents
 */
public enum PurchaseActionState {
    case loading
    case finish(PurchaseActionResult)
    case none
}

/** Defines action result state

 - error: Notifies handler if any error presents
 - subscriptionValidationSuccess: Notifies handler if any subscription plan is valid
 - retrieveSuccess: Notifies handler if more than one products retrieved
 - retrieveSuccessInvalidProducts: Notifies handler of any retrieved invalid products
 - purchaseSuccess: Notifies handler if purchase was successfull
 - restoreSuccess: Notifies handler if restoring was successfull
 - restoreRequested: Notifies handler when restore request was added
 - completionSuccess: Notifies handler if transaction completion was successfull
 - receiptValidationSuccess: Notifies handler if receipt validation was successfull
 */
public enum PurchaseActionResult {
    case error(Error)
    case subscriptionValidationSuccess([InAppPurchase])
    case retrieveSuccess
    case retrieveSuccessInvalidProducts([String])
    case purchaseSuccess([InAppPurchase])
    case restoreSuccess
    case restoreRequested
    case completionSuccess
    case receiptValidationSuccess
    case fetchReceiptSuccess(Data)
    case purchaseSyncronizationSuccess
}

public protocol PurchaseStateHandler: class {
    /**
     Protocol method to notify of purchase actions state changing

     - Parameters:
     - newState: state, that becomes current
     - state: last current state to compare with
     */
    func update(newState: PurchaseActionState, from state: PurchaseActionState)
}

/**
 - note: Decrypted receipt is accessible ONLY after validateReceipt(using validator:) call.
 */
public protocol PurchaseControllerInterface {
    init(stateHandler: PurchaseStateHandler?,
         persistor: PurchasePersistor?,
         productIds: Set<String>,
         subscriptionProductIds: Set<String> )
    func localPurchasedProducts() -> [InAppPurchase]
    func localPurschasedProducts(by filter: InAppPurchaseFilter) throws -> [InAppPurchase]
    func localAvailableProducts() -> [SKProduct]
    func localAvailableProducts(by filter: ProductFilter) throws -> [SKProduct]
    func retrieve()
    func restore()
    func purchase(with identifier: String, atomically: Bool)
    func validateReceipt(using validator: ReceiptValidatorProtocol)
    func fetchReceipt(forceReceipt: Bool)
    func validateSubscription(filter: InAppPurchaseFilter?)
    func completeTransaction(for purchaseItem: InAppPurchase)
    func completeTransactions()
    func fetchEncryptedReceipt() -> Data?
    func openSubscriptionSettings()
}

public class PurchaseController {
    private static let globalStorage: Storage = Storage(persistor: PurchasePersistorImplementation())
    private static let globalPaymentQueueController = PaymentQueueController(storage: globalStorage)

    private let implementation: PurchaseControllerImpl
    
    /**
     Initializer with non-secure persistor by default.

     - Parameter stateHandler: Any object for state handling, conforming to `PurchaseStateHandler` protocol.
     - Parameter persistor: Any object for persisting transactions and products, conforming to `PurchasePersistor` protocol.
     - Parameter subscriptionProductIds: Set of identificators to validate subscriptions.
     */
    required public init(stateHandler: PurchaseStateHandler?,
                         persistor: PurchasePersistor? = nil,
                         productIds: Set<String> = [],
                         subscriptionProductIds: Set<String> = []) {
        var storage = PurchaseController.globalStorage
        if let persistor = persistor {
            storage = Storage(persistor: persistor)
        }
        self.implementation = PurchaseControllerImpl(stateHandler: stateHandler,
                                                     persistor: storage,
                                                     productIds: productIds,
                                                     subscriptionProductIds: subscriptionProductIds)
        PurchaseController.globalPaymentQueueController.storage = storage
        implementation.paymentQueueController = PurchaseController.globalPaymentQueueController
    }
    
    deinit {
        self.implementation.removeBroadcasters()
    }
    
    /**
     Function, used to set product identifiers.

     - Parameter productIds: Set of product identifiers.
     */
    public func set(productIds: Set<String>) {
        implementation.productIds = productIds
    }
    
    /**
     Function, used to set subscription product identifiers.

     - Parameter productIds: Set of subscription product identifiers.
     */
    public func set(subscription productIds: Set<String>) {
        implementation.subscriptionProductIds = productIds
    }
}

extension PurchaseController: PurchaseControllerInterface {
    /**
     Function used to access all local purchased products.

     - Returns: An array of `InAppPurchase` objects.
     */
    public func localPurchasedProducts() -> [InAppPurchase] {
        return self.implementation.localPurchasedProducts()
    }
    
    /**
     Filter function, used to access local purchased products.

     - Parameter filter: Filter closure used for comparing `InAppPurchase` objects.
     - Returns: An array of `InAppPurchase` after filter applying.
     */
    public func localPurschasedProducts(by filter: (InAppPurchase) throws -> Bool) throws -> [InAppPurchase] {
        return try implementation.localPurschasedProducts(by: filter)
    }
    
    /**
     Function used to access all local products available for purchase.

     - Returns: An Array of `SKProduct` objects.
     */
    public func localAvailableProducts() -> [SKProduct] {
        return implementation.localAvailableProducts()
    }
    
    /**
     Filter function used to access to local products available for purchase.

     - Parameter filter: filter closure, used to comparing to SKProduct objects.
     - Returns: An array of `SKProduct` objects after filter applying.
     */
    public func localAvailableProducts(by filter: ProductFilter) throws -> [SKProduct] {
        return try implementation.localAvailableProducts(by: filter)
    }
    
    /**
     Function used to retrieve available products from StoreKit.
     Result items are stored using persistor object.

     Notifies handler with `.retrieveSuccess` state if no error or invalid products retrieved.

     Notifies handler with `.retrieveSuccessInvalidProducts` state if any invalid products retrieved,
     along with storing valid products to persistor.

     Notifies handler with `.error` state if any error occured.
     */
    public func retrieve() {
        implementation.retrieve()
    }
    
    /**
     Function, used to restore available products from App Store.
     Result items are stored using persistor object.

     Notifies handler with `.restoreFailed` if none items were restored.

     Notifies handler with `.finish(items)` in case of success.

     Notifies handler with `.restoreFailed` if any error occured.
     */
    public func restore() {
        implementation.restore()
    }
    
    /**
     Function used to add product to purchase queue.
     Result items are stored using persistor object.

     Notifies handler with `.noLocalProduct` state if no local product with given identifier exists.

     Notifies handler with `.purchaseSuccess` state if item is successfully purchased.

     Notifies handler with `.error` if any error occured.

     - Parameter identifier: Identifier of product to be purchased.
     - Parameter atomically: Defines if the transaction should be completed immediately.
     */
    public func purchase(with identifier: String, atomically: Bool = true) {
        implementation.purchase(with: identifier, atomically: atomically)
    }
    
    /**
     Function used to verify receipt using validator object.

     Receipt is stored on `appStoreReceiptURL` path.
     Validated receipt model is stored in `Storage.sessionReceipt`.

     Notifies handler with `.receiptSerializationError` if receipt can't be serialized.

     Notifies handler with `.receiptValidationSuccess` state if receipt is valid.

     Notifies handler with `.error` if any error occured.

     - Parameter validator: Receipt validator.
     */
    public func validateReceipt(using validator: ReceiptValidatorProtocol) {
        implementation.validateReceipt(using: validator)
    }
    
    /**
     Function used to fetch receipt into local storage.

     Notifies handler with appropriate error state if failed to fetch receipt.

     Notifies handler with `.fetchReceiptSuccess` state with receipt data if receipt is fetched.

     - Parameter forceReceipt: if true, refreshes the receipt even if a local one already exists.
     */
    public func fetchReceipt(forceReceipt: Bool = false) {
        implementation.fetchReceipt(forceReceipt: forceReceipt)
    }
    
    /**
     Function used to validate a subscription using validator object.

     Notifies handler with `.noActiveSubscription` state if no subscription exists for given id.

     Notifies handler with `.subscriptionValidationSuccess` state if the given id corresponds to an active subscription.

     - Parameter filter: Closure, used for filtering subscription objects.
     */
    public func validateSubscription(filter: InAppPurchaseFilter?) {
        implementation.validateSubscription(filter: filter)
    }
    
    /**
     Function used to complete a transaction for particular `PurcahseItem`.
     
     Notifies handler with `.completionSuccess` state when completed.
     
     - Parameter purchaseItem: A purchased item that needs its corresponding transaction to be finished.
     */
    public func completeTransaction(for purchaseItem: InAppPurchase) {
        implementation.completeTransaction(for: purchaseItem)
    }
    
    /**
     Function used to complete all previous unfinished transactions.
     
     Notifies handler with `.completionSuccess` state when completed.
     */
    public func completeTransactions() {
        implementation.completeTransactions()
    }

    /**
     Function used to fetch encrypted receipt data from application bundle.

     - Returns: Data containing encrypted IAP receipt.
     */
    public func fetchEncryptedReceipt() -> Data? {
        return implementation.fetchEncryptedReceipt()
    }

    public func openSubscriptionSettings() {
        implementation.openSubscriptionSettings()
    }
}
