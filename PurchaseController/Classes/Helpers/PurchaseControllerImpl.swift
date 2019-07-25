//
//  PurchaseControllerPrivateImplementation.swift
//  Pods-PurchaseController_Example
//
//  Created by Valeriy Efimov on 7/23/19.
//

import StoreKit

final class PurchaseControllerImpl: PaymentQueueObserver, ProductsInfoObserver, ReceiptFetcherObserver {
    var paymentQueueController: PaymentQueueController? {
        didSet {
            paymentQueueController?.addObserver(self)
        }
    }
    private lazy var productsInfoController = {
        return ProductsInfoController(observer: self)
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
    
    public var productIds: Set<String>
    public var subscriptionProductIds: Set<String>
    
    // MARK: - PaymentQueueObserver
    
    lazy var onRestoreRequested: (() -> Void)? = { [weak self] in
        guard let sSelf = self else { return }
        sSelf.purchaseActionState = .finish(PurchaseActionResult.restoreRequested)
    }
    
    lazy var onPurchase: (([String]) -> Void)? = { [weak self] items in
        guard let sSelf = self else { return }
        let purchasedItems = sSelf.storage.fetchPurchasedProducts().filter({ purchase -> Bool in
            return items.contains(purchase.transactionId)
        })
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
    
    lazy var onRetrieve: ((RetrievedProductsInfo) -> Void)? = { [weak self] (retrievedProductsInfo) in
        self?.storage.persist(products: retrievedProductsInfo.products)
        let hasInvalidProducts = !retrievedProductsInfo.invalidProductIdentifiers.isEmpty
        self?.purchaseActionState = hasInvalidProducts ?
            .finish(PurchaseActionResult.retrieveSuccessInvalidProducts) :
            .finish(PurchaseActionResult.retrieveSuccess)
    }
    
    init(stateHandler: PurchaseStateHandler?,
         persistor: PurchasePersistor?,
         productIds: Set<String> = [],
         subscriptionProductIds: Set<String> = [])  {
        if let persistor = persistor as? Storage {
            self.storage = persistor
        } else {
            self.storage = Storage(persistor: persistor!)
        }
        self.stateHandler = stateHandler
        self.productIds = productIds
        self.subscriptionProductIds = subscriptionProductIds
        self.purchaseActionState = .none
    }
    
    func removeBroadcasters() {
        paymentQueueController?.removeObserver(self)
        productsInfoController.removeObserver()
        receiptFetcher.removeObserver()
    }
}

extension PurchaseControllerImpl: PurchaseControllerInterface {
    public func localPurschasedProducts() -> [InAppPurchase] {
        return storage.fetchPurchasedProducts()
    }
    
    public func localPurschasedProducts(by filter: (InAppPurchase) throws -> Bool) throws -> [InAppPurchase] {
        return try storage.fetchPurchasedProducts().filter(filter)
    }
    
    public func localAvailableProducts() -> [SKProduct] {
        return storage.fetchProducts()
    }
    
    public func localAvailableProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
        return try storage.fetchProducts().filter(filter)
    }
    
    public func retrieve() {
        self.purchaseActionState = .loading
        let idsToRetrieve = productIds.union(subscriptionProductIds)
        productsInfoController.retrieveProductsInfo(idsToRetrieve)
    }
    
    public func restore() {
        self.purchaseActionState = .loading
        paymentQueueController?.restore()
    }
    
    public func purchase(with identifier: String, atomically: Bool = true) {
        self.purchaseActionState = .loading
        guard let localСompared = try? localAvailableProducts(by: { $0.productIdentifier == identifier }),
            let product = localСompared.first else {
                self.purchaseActionState = .finish(PurchaseActionResult.error(PurchaseError.noLocalProduct))
                return
        }
        paymentQueueController?.purchase(product: product, atomically: false)
    }
    
    public func validateReceipt(using validator: ReceiptValidatorProtocol) {
        self.purchaseActionState = .loading
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
    
    public func fetchReceipt(forceReceipt: Bool = true) {
        self.purchaseActionState = .loading
        receiptFetcher.fetchReceipt(forceRefresh: forceReceipt)
    }
    
    public func validateSubscription(filter: InAppPurchaseFilter?) {
        self.purchaseActionState = .loading
        let controller = SubscriptionValidationController(with: self.storage, subscription: productIds)
        do {
            let filtered = try controller.validate(by: filter)
            self.purchaseActionState = .finish(PurchaseActionResult.subscriptionValidationSuccess(filtered))
        } catch let error {
            self.purchaseActionState = .finish(PurchaseActionResult.error(error))
        }
    }
    
    public func completeTransaction(for purchaseItem: InAppPurchase) {
        paymentQueueController?.completeTransaction(for: purchaseItem)
    }
    
    public func completeTransactions() {
        paymentQueueController?.completeTransactions()
    }
}
