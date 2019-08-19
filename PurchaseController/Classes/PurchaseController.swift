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
 *
 * - loading: Notifies handler if any action was started
 * - finish: Notifies handler if action was finished
 * - none: Notifies handler if no current actions presents
 */
public enum PurchaseActionState {
    case loading
    case finish(PurchaseActionResult)
    case none
}

/** Defines action result state
 *
 * - error: Notifies handler if any error presents
 * - subscriptionValidationSuccess: Notifies handler if any subscription plan is valid
 * - retrieveSuccess: Notifies handler if more than one products retrieved
 * - retrieveSuccessInvalidProducts: Notifies handler of any retrieved invalid products
 * - purchaseSuccess: Notifies handler if purchase was successfull
 * - restoreSuccess: Notifies handler if restoring was successfull
 * - restoreRequested: Notifies handler when restore request was added
 * - completionSuccess: Notifies handler if transaction completion was successfull
 * - receiptValidationSuccess: Notifies handler if receipt validation was successfull
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
     * Protocol method to notify of purchase actions state changing
     *
     * - Parameters:
     *   - newState: state, that becomes current
     *   - state: last current state to compare with
     */
    func update(newState: PurchaseActionState, from state: PurchaseActionState)
}

/**
 - note: receipt vailadble ONLY after validateReceipt(using validator:) call.
 */
public protocol PurchaseControllerInterface {
    init(stateHandler: PurchaseStateHandler?,
         persistor: PurchasePersistor?,
         productIds: Set<String>,
         subscriptionProductIds: Set<String> )
    func localPurschasedProducts() -> [InAppPurchase]
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
}

public class PurchaseController {
    private static let globalStorage: Storage = Storage(persistor: PurchasePersistorImplementation())
    private static let globalPaymentQueueController = PaymentQueueController(storage: globalStorage)

    private let implementation: PurchaseControllerImpl
    
    /** Initializer with non-sequre persistor by default
     *
     * - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
     * - Parameter persistor: Any object for persisting transactions and products, should implement PurchasePersistor protocol
     * - Parameter subscriptionProductIds: Set of identificators to validate subscriptions
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
    
    /** Function, used to set product identificators
    *
    * - Parameter productIds: set of product identificators
    */
    public func set(productIds: Set<String>) {
        implementation.productIds = productIds
    }
    
    /** Function, used to set subscription product identificators
     *
     * - Parameter productIds: set of subscription product identificators
     */
    public func set(subscription productIds: Set<String>) {
        implementation.subscriptionProductIds = productIds
    }
}

extension PurchaseController: PurchaseControllerInterface {
    /** Function used to access all local purchased products.
     *
     * - Returns: array of InAppPurchase.
     */
    public func localPurschasedProducts() -> [InAppPurchase] {
        return self.implementation.localPurschasedProducts()
    }
    
    /** Filter function, used to access to local purchased products
     *
     * - Parameter filter: filter closure used for comparing InAppPurchase objects
     * - Returns: array of InAppPurchase after filter applying
     */
    public func localPurschasedProducts(by filter: (InAppPurchase) throws -> Bool) throws -> [InAppPurchase] {
        return try implementation.localPurschasedProducts(by: filter)
    }
    
    /** Function used to access all local products available for purchase.
     *
     * - Returns: array of SKProduct.
     */
    public func localAvailableProducts() -> [SKProduct] {
        return implementation.localAvailableProducts()
    }
    
    /** Filter function used to access to local products available for purchase.
     *
     * - Parameter filter: filter closure, used to comparing to SKProduct objects.
     * - Returns: array of SKProduct after filter applying.
     */
    public func localAvailableProducts(by filter: ProductFilter) throws -> [SKProduct] {
        return try implementation.localAvailableProducts(by: filter)
    }
    
    /** Function used to retrieve available products from StoreKit.
     * Result items are storing using persistor object.
     *
     * Notifies handler with .retrieveSuccess state if no error or invalid products retrieved
     *
     * Notifies handler with .retrieveSuccessInvalidProducts state if any invalid products retrieved,
     * along with storing valid products to persistor
     *
     * Notifies handler with .error state if any error retrieved
     */
    public func retrieve() {
        implementation.retrieve()
    }
    
    /** Function, used to restore available products from Apple side.
     * Result items are stored using persistor object.
     *
     * Notifies handler with .restoreFailed if no restored items presents
     *
     * Notifies handler with .finish(items) if success
     *
     * Notifies handler with .restoreFailed if any error presents
     */
    public func restore() {
        implementation.restore()
    }
    
    /** Function used to add product to purchase queue.
     * Result items are stored using persistor object.
     *
     * Notifies handler with .noLocalProduct state if no local product with given identifier exists
     *
     * Notifies handler with .purchaseSuccess state if items purchased
     *
     * Notifies handler with .error if any error occured
     *
     * - Parameters:
     *   - identifier: identifier of product to purchase.
     *   - atomically: defines if the transaction should be completed immediately.
     */
    public func purchase(with identifier: String, atomically: Bool = true) {
        implementation.purchase(with: identifier, atomically: atomically)
    }
    
    /** Function used to verify receipt using validator object.
     *
     * Receipt is stored on appStoreReceiptURL path.
     * Validated receipt model is stored in Storage.sessionReceipt.
     *
     * Notifies handler with .receiptSerializationError if a receipt can not serialization
     *
     * Notifies handler with .receiptValidationSuccess state if no error occured
     *
     * Notifies handler with .error if any error occured
     *
     * - Parameter validator: Receipt validator.
     */
    public func validateReceipt(using validator: ReceiptValidatorProtocol) {
        implementation.validateReceipt(using: validator)
    }
    
    /** Function used to fetch receipt in local storage.
     *
     * Notifies handler with appropriate error state if cannot fetch receipt
     *
     * Notifies handler with .fetchReceiptSuccess state with receipt data if presents receipt
     * - Parameter forceReceipt: if true, refreshes the receipt even if local one already exists.
     */
    public func fetchReceipt(forceReceipt: Bool = false) {
        implementation.fetchReceipt(forceReceipt: forceReceipt)
    }
    
    /** Function used to validate subscription using validator object.
     *
     * Notifies handler with .noActiveSubscription state if no subscription exists for given ids
     *
     * Notifies handler with .subscriptionValidationSuccess state if presents active subscription for given id
     *
     * - Parameters:
     *   - filter: filter closure, used for predict subscription objects
     */
    public func validateSubscription(filter: InAppPurchaseFilter?) {
        implementation.validateSubscription(filter: filter)
    }
    
    /**
     Function used to complete a transaction for particular `PurcahseItem`.
     
     Notifies handler with .completionSuccess state when complete.
     
     - Parameter purchaseItem: A purchased item that needs its corresponding transaction to be finished.
     */
    public func completeTransaction(for purchaseItem: InAppPurchase) {
        implementation.completeTransaction(for: purchaseItem)
    }
    
    /**
     Function used to complete all previous unfinished transactions.
     
     Notifies handler with .completionSuccess state when complete.
     */
    public func completeTransactions() {
        implementation.completeTransactions()
    }
}
