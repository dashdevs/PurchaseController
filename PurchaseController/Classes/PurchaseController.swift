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
    case subscriptionValidationSucess(ReceiptItem)
    case retrieveSuccess
    case retrieveSuccessInvalidProducts
    case purchaseSuccess(PurchaseItem)
    case restoreSuccess
    case completionSuccess
    case receiptValidationSuccess
    case fetchReceiptSuccess(Data)
    case purchaseSyncronizationSuccess
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
public final class PurchaseController: PaymentQueueControllerDelegate {
    
    // MARK: - PaymentQueueControllerDelegate
    
    lazy var onPurchase: (([PurchaseItem]) -> Void)? = { [weak self] items in
        self?.persistor.persistPurchased(products: items)
        self?.purchaseActionState = .finish(PurchaseActionResult.purchaseSuccess(items[0]))
        print(items)
    }
    
    lazy var onRestore: (([SKPaymentTransaction]) -> Void)? = { [weak self] transactions in
        guard let sSelf = self else { return }
        let products = sSelf.persistor.fetchProducts()
        let restoredItems = transactions.makeItems(with: sSelf.persistor)
        if restoredItems.isEmpty {
            sSelf.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.restoreFailed))
            return
        }
        sSelf.persistor.persistPurchased(products: restoredItems)
        sSelf.purchaseActionState = .finish(PurchaseActionResult.restoreSuccess)
    }
    
    lazy var onError: ((Error) -> Void)? = { [weak self] error in
        self?.purchaseActionState = .finish(PurchaseActionResult.error(error.purchaseError))
    }
    
    
    /// receipt object. Availadble ONLY after verifyReceipt() call.
    public private(set) var sessionReceipt: Receipt?
    private static let globalPersistor = PurchasePersistorImplementation()
    private static let globalPaymentQueueController = PCPaymentQueueController()
    
    private var persistor: PurchasePersistor
    private var stateHandler: PurchaseStateHandler?
    private var purchaseActionState: PurchaseActionState {
        willSet {
            stateHandler?.update(newState: newValue, from: purchaseActionState)
        }
    }
    
    /// Initializer with default non-secure persistor
    ///
    /// - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
    public init(stateHandler: PurchaseStateHandler?)  {
        self.persistor = PurchaseController.globalPersistor
        self.stateHandler = stateHandler
        self.purchaseActionState = .none
        PurchaseController.globalPaymentQueueController.addObserver(self)
        SwiftyStoreKit.completeTransactions(completion: { _ in})
        
    }
    
    /// Initializer with user's persistor
    ///
    /// - Parameter stateHandler: Any object for state handling, should implement PurchaseStateHandler protocol
    /// - Parameter persistor: Any object for persisting transactions and products, should implement PurchasePersistor protocol
    public init(stateHandler: PurchaseStateHandler?, persistor: PurchasePersistor)  {
        self.persistor = persistor
        self.stateHandler = stateHandler
        self.purchaseActionState = .none
        PurchaseController.globalPaymentQueueController.addObserver(self)
        SwiftyStoreKit.completeTransactions(completion: { _ in})
    }
    
    // MARK: - Public
    
    /// Function used to access all local purchased products.
    ///
    /// - Returns: array of PurchaseItem.
    public func localPurschasedProducts() -> [PurchaseItem] {
        return persistor.fetchPurchasedProducts()
    }
    
    /// Filter function, used to access to local purchased products
    ///
    /// - Parameter filter: filter closure used for comparing PurchaseItem objects
    /// - Returns: array of PurchaseItem after filter applying
    public func localPurschasedProducts(by filter: (PurchaseItem) throws -> Bool) throws -> [PurchaseItem] {
        return try persistor.fetchPurchasedProducts().filter(filter)
    }
    
    /// Function used to access all local products available for purchase.
    ///
    /// - Returns: array of SKProduct.
    public func localAvailableProducts() -> [SKProduct] {
        return persistor.fetchProducts()
    }
    
    /// Filter function used to access to local products available for purchase.
    ///
    /// - Parameter filter: filter closure, used to comparing to SKProduct objects.
    /// - Returns: array of SKProduct after filter applying.
    public func localAvailableProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
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
                self.purchaseActionState = .finish(PurchaseActionResult.error(error.purchaseError))
                return
            }
            self.persistor.persist(products: results.retrievedProducts)
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
    /// Validated receipt dict is stored in sessionReceipt.
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
                self.sessionReceipt = receipt
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
        SwiftyStoreKit.fetchReceipt(forceRefresh: forceReceipt, completion: { result in
            switch result {
            case .success(let receiptData):
                self.purchaseActionState = .finish(.fetchReceiptSuccess(receiptData))
            case .error(let error):
                self.purchaseActionState = .finish(.error(error.purchaseError))
            }
        })
    }
    
    
    /// Function used to synchronize decoded receipt purchases with local saved.
    ///
    /// Notifies handler with .purchaseSyncronizationSuccess if purchases synchronized
    ///
    /// Notifies handler with .purchaseSynchronizationError if no purchases in receipt or receipt do not decoded
    public func synchronizeLocalPurchasesFromReceipt() {
        self.purchaseActionState = .loading
        guard let purchases = self.sessionReceipt?.inApp else {
            self.purchaseActionState = .finish(.error(PurchaseError.purchaseSynchronizationError))
            return
        }
        
        let missingPurchases = purchases.filter { (inAppPurchase) -> Bool in
            return !self.persistor.fetchPurchasedProducts().contains(where: { (purchase) -> Bool in
                return purchase.transaction.transactionIdentifier == inAppPurchase.transactionId
            })
            }.makeItems(with: persistor)
        self.persistor.persistPurchased(products: missingPurchases)
        self.purchaseActionState = .finish(PurchaseActionResult.purchaseSyncronizationSuccess)
    }
    
    /// Function used to validate subscription using validator object.
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
        guard let receipt = self.sessionReceipt,
        let receiptJson = try? receipt.asJsonObject(),
        let receiptInfo = receiptJson as? ReceiptInfo else {
            self.purchaseActionState = .finish(PurchaseActionResult.error(ReceiptError.noReceiptData))
            return
        }
        let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: type,
                                                               productId: productID,
                                                               inReceipt: receiptInfo)
        switch purchaseResult {
        case .purchased(_, let items):
            let sorted = items.sorted(by: { (lo, ro) -> Bool in
                return lo.purchaseDate.timeIntervalSince1970 > ro.purchaseDate.timeIntervalSince1970
            })
            guard let latestActualSubscription = sorted.first else {
                self.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.noActiveSubscription))
                return
            }
            self.purchaseActionState = .finish(PurchaseActionResult.subscriptionValidationSucess(latestActualSubscription))
        case .notPurchased, .expired(_, _):
            self.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.noActiveSubscription))
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
