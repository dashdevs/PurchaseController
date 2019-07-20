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
public enum PurchaseActionResult {
    case error(Error)
    case subscriptionValidationSucess([InAppPurchase])
    case retrieveSuccess
    case retrieveSuccessInvalidProducts
    case purchaseSuccess([InAppPurchase])
    case restoreSuccess
    case completionSuccess
    case receiptValidationSuccess
    case fetchReceiptSuccess(Data)
    case purchaseSyncronizationSuccess
}

public protocol PurchaseStateHandler: class {
    /// Protocol method to notify of purchase actions state changing
    ///
    /// - Parameters:
    ///   - newState: state, that becomes current
    ///   - state: last current state to compare with
    func update(newState: PurchaseActionState, from state: PurchaseActionState)
}

@available(iOS 10.0, *)

public final class PurchaseController: PaymentQueueObserver, ProductsInfoObserver, ReceiptFetcherObserver {
    
    // MARK: - PaymentQueueObserver
    
    lazy var onPurchase: (([String]) -> Void)? = { [weak self] items in
       guard let purchasedItems = self?.storage.fetchPurchasedProducts().filter({ purchase -> Bool in
           return items.contains(purchase.transactionId)
        }) else {
            self?.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.unknown))
            return
        }
        self?.purchaseActionState = .finish(PurchaseActionResult.purchaseSuccess(purchasedItems))
    }
    
    lazy var onRestore: (([SKPaymentTransaction]) -> Void)? = { [weak self] transactions in
        guard let sSelf = self else { return }
        let products = sSelf.storage.fetchProducts()
        let restoredItems = transactions.makeItems(with: sSelf.storage)
        if restoredItems.isEmpty {
            sSelf.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.restoreFailed))
            return
        }
        sSelf.storage.persistPurchased(products: restoredItems)
        sSelf.purchaseActionState = .finish(PurchaseActionResult.restoreSuccess)
    }
    
    lazy var onError: ((Error) -> Void)? = { [weak self] error in
        self?.purchaseActionState = .finish(PurchaseActionResult.error(error.purchaseError))
    }
    
    // MARK: - ReceiptFetcherObserver
    
    lazy var onReceiptFetch: ((Data) -> Void)? = { [weak self] receiptData in
        self?.purchaseActionState = .finish(.fetchReceiptSuccess(receiptData))
    }
    
    // MARK: - ProductsInfoObserver
    
    lazy var onRetrieve: ((RetrievedProductsInfo) -> Void)? = { [weak self] (retrievedProductsInfo)  in
        self?.storage.persist(products: retrievedProductsInfo.products)
        let hasInvalidProducts = !retrievedProductsInfo.invalidProductIdentifiers.isEmpty
        self?.purchaseActionState = hasInvalidProducts ? .finish(PurchaseActionResult.retrieveSuccessInvalidProducts) : .finish(PurchaseActionResult.retrieveSuccess)
    }
    
    /// receipt object. Availadble ONLY after verifyReceipt() call.
    private static let globalStorage = Storage(persistor: PurchasePersistorImplementation())
    private static let globalPaymentQueueController = PCPaymentQueueController(storage: globalStorage)
    private lazy var productsInfoController = {
        return PCProductsInfoController(observer: self)
    }()
    
    private lazy var receiptFetcher: ReceiptFetcher = {
        return ReceiptFetcher(observer: self)
    }()
    
    private var storage: Storage
    private weak var stateHandler: PurchaseStateHandler?
    private var purchaseActionState: PurchaseActionState {
        willSet {
            stateHandler?.update(newState: newValue, from: purchaseActionState)
        }
    }
    
    public let productIds: Set<String>
    public let subscriptionProductIds: Set<String>

    /// Initializer with default non-secure persistor
    ///
    /// - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
    /// - Parameter productIds: Set of identificators to retrieve
    /// - Parameter subscriptionProductIds: Set of identificators to validate subscriptions
    public init(stateHandler: PurchaseStateHandler?, productIds: Set<String> = [], subscriptionProductIds: Set<String> = [])  {
        self.storage = PurchaseController.globalStorage
        self.stateHandler = stateHandler
        self.productIds = productIds
        self.subscriptionProductIds = subscriptionProductIds
        self.purchaseActionState = .none
        PurchaseController.globalPaymentQueueController.addObserver(self)
    }
    
    /// Initializer with user's persistor
    ///
    /// - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
    /// - Parameter persistor: Any object for persisting transactions and products, should implement PurchasePersistor protocol
    /// - Parameter subscriptionProductIds: Set of identificators to validate subscriptions
    public init(stateHandler: PurchaseStateHandler?, persistor: PurchasePersistor, productIds: Set<String> = [], subscriptionProductIds: Set<String> = [])  {
        self.storage = Storage(persistor: persistor)
        PurchaseController.globalPaymentQueueController.storage = self.storage
        self.stateHandler = stateHandler
        self.productIds = productIds
        self.subscriptionProductIds = subscriptionProductIds
        self.purchaseActionState = .none
        PurchaseController.globalPaymentQueueController.addObserver(self)
    }
    
    // MARK: - Public
    
    /// Function used to access all local purchased products.
    ///
    /// - Returns: array of InAppPurchase.
    public func localPurschasedProducts() -> [InAppPurchase] {
        return storage.fetchPurchasedProducts()
    }
    
    /// Filter function, used to access to local purchased products
    ///
    /// - Parameter filter: filter closure used for comparing InAppPurchase objects
    /// - Returns: array of InAppPurchase after filter applying
    public func localPurschasedProducts(by filter: (InAppPurchase) throws -> Bool) throws -> [InAppPurchase] {
        return try storage.fetchPurchasedProducts().filter(filter)
    }
    
    /// Function used to access all local products available for purchase.
    ///
    /// - Returns: array of SKProduct.
    public func localAvailableProducts() -> [SKProduct] {
        return storage.fetchProducts()
    }
    
    /// Filter function used to access to local products available for purchase.
    ///
    /// - Parameter filter: filter closure, used to comparing to SKProduct objects.
    /// - Returns: array of SKProduct after filter applying.
    public func localAvailableProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
        return try storage.fetchProducts().filter(filter)
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
    public func retrieve() {
        self.purchaseActionState = .loading
        productsInfoController.retrieveProductsInfo(productIds)
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
        PurchaseController.globalPaymentQueueController.restore()
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
    /// - Parameters:
    ///   - identifier: identifier of product to purchase.
    ///   - atomically: defines if the transaction should be completed immediately.
    public func purchase(with identifier: String, atomically: Bool = true) {
        self.purchaseActionState = .loading
        guard let localСompared = try? localAvailableProducts(by: { $0.productIdentifier == identifier }),
            let product = localСompared.first else {
                self.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.noLocalProduct))
                return
        }
        PurchaseController.globalPaymentQueueController.purchase(product: product, atomically: false)
    }
    
    /// Function used to verify receipt using validator object.
    ///
    /// Receipt is stored on appStoreReceiptURL path.
    /// Validated receipt model is stored in Storage.sessionReceipt.
    ///
    /// Notifies handler with .receiptSerializationError if a receipt can not serialization
    ///
    /// Notifies handler with .receiptValidationSuccess state if no error occured
    ///
    /// Notifies handler with .error if any error occured
    ///
    /// - Parameter validator: Receipt validator.
    public func validateReceipt(using validator: ReceiptValidatorProtocol) {
        validator.validate { [unowned self] validationResult in
            switch validationResult {
            case let .success(receipt):
                try? self.storage.set(receipt: receipt)
                self.purchaseActionState = .finish(PurchaseActionResult.receiptValidationSuccess)
            case let .error(error):
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.purchaseError))
            }
        }
    }
    
    /// Function used to fetch receipt in local storage.
    ///
    /// Notifies handler with appropriate error state if cannot fetch receipt
    ///
    /// Notifies handler with .fetchReceiptSuccess state with receipt data if presents receipt
    /// - Parameter forceReceipt: if true, refreshes the receipt even if local one already exists.
    public func fetchReceipt(forceReceipt: Bool = true) {
        self.purchaseActionState = .loading
        receiptFetcher.fetchReceipt(forceRefresh: forceReceipt)
    }
    
    /// Function used to validate subscription using validator object.
    ///
    /// Notifies handler with .noActiveSubscription state if no subscription exists for given ids
    ///
    /// Notifies handler with .subscriptionValidationSucess state if presents active subscription for given id
    ///
    /// - Parameters:
    ///   - filter: filter closure, used for predict subscription objects
    public func validateSubscription(filter: SubscriptionFilter?) {
        self.purchaseActionState = .loading
        let controller = SubscriptionValidationController(with: self.storage, subscription: productIds)
        do {
            let filtered = try controller.validate(by: filter)
            if filtered.isEmpty {
                 self.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.noActiveSubscription))
            }
            self.purchaseActionState = .finish(PurchaseActionResult.subscriptionValidationSucess(filtered))
        } catch let error {
             self.purchaseActionState = .finish(PurchaseActionResult.error(error))
        }
    }
    
    /**
     Function used to complete a transaction for particular `PurcahseItem`.
     
     Notifies handler with .completionSuccess state when complete.
     
     - Parameter purchaseItem: A purchased item that needs its corresponding transaction to be finished.
     */
    public func completeTransaction(for purchaseItem: InAppPurchase) {
        PurchaseController.globalPaymentQueueController.completeTransaction(for: purchaseItem)
    }
    
    /**
     Function used to complete all previous unfinished transactions.
     
     Notifies handler with .completionSuccess state when complete.
     */
    public func completeTransactions() {
        PurchaseController.globalPaymentQueueController.completeTransactions()
    }
}
