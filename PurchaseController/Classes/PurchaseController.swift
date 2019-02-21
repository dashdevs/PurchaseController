//
//  PurchaseController.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

public enum PurchaseActionState {
    case loading
    case finish(PurchaseActionResult)
    case none
}

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
    var state: PurchaseActionState { get set }
    func update(newState: PurchaseActionState)
}

public final class PurchaseController {
    private(set) var sessionReceipt: ReceiptInfo?
    private var persistor: PurchasePersistor
    private var stateHandler: PurchaseStateHandler?
    public static var defaultPersistor: PurchasePersistor = {
        return PurchasePersistorImplementation()
    }()
    
    public init(stateHandler: PurchaseStateHandler?, persistor: PurchasePersistor = defaultPersistor) {
        self.persistor = persistor
        self.stateHandler = stateHandler
    }
    
    // MARK: - Public
    
    public func localPurschasedProducts(by filter: (PurchaseItem) throws -> Bool) throws -> [PurchaseItem] {
        return try persistor.fetchPurchasedProducts().filter(filter)
    }
    
    public func localProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
        return try persistor.fetchProducts().filter(filter)
    }
    
    public func retrieve(products: Set<String>) {
        stateHandler?.state = .loading
        SwiftyStoreKit.retrieveProductsInfo(products) { [unowned self] (results) in
            if let error = results.error {
                self.stateHandler?.state = .finish(PurchaseActionResult.error(error.asPurchaseError()))
                return
            }
            self.persistor.persist(products: Array(results.retrievedProducts))
            if results.invalidProductIDs.count > 0 {
                self.stateHandler?.state = .finish(PurchaseActionResult.retrieveSuccessInvalidProducts)
                return
            }
            self.stateHandler?.state = .finish(PurchaseActionResult.retrieveSuccess)
        }
    }
    
    public func restore() {
        stateHandler?.state = .loading
        SwiftyStoreKit.restorePurchases { [unowned self] (results) in
            let items = results.restoredPurchases.makeItems(with: self.persistor)
            if items.isEmpty {
                self.stateHandler?.state = .finish(PurchaseActionResult.error(.restoreFailed))
                return
            }
            self.persistor.persistPurchased(products: items)
            if let error = results.restoreFailedPurchases.first?.0 {
                self.stateHandler?.state = .finish(PurchaseActionResult.error(error.asPurchaseError()))
                return
            }
            self.stateHandler?.state = .finish(PurchaseActionResult.restoreSuccess)
        }
    }
    
    public func purchase(with identifier: String) {
        stateHandler?.state = .loading
        guard let localСompared = try? localProducts(by: { $0.productIdentifier == identifier }),
            let product = localСompared.first else {
            self.stateHandler?.state = .finish(PurchaseActionResult.error(.noLocalProduct))
            return 
        }
        SwiftyStoreKit.purchaseProduct(product) { [unowned self] (results) in
            switch results {
            case .success(let purchase):
                let item = PurchaseItem(purchaseDeatils: purchase)
                self.persistor.persistPurchased(products: [item])
                self.stateHandler?.state = .finish(PurchaseActionResult.purchaseSuccess)
            case .error(let error):
                self.stateHandler?.state = .finish(PurchaseActionResult.error(error.asPurchaseError()))
            }
        }
        
    }
    
    public func verifyReceipt(sharedSecret: String, isSandbox: Bool = true) {
        stateHandler?.state = .loading
        let appleValidator = AppleReceiptValidator(service: isSandbox ? .sandbox : .production,
                                                   sharedSecret: sharedSecret)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { [unowned self] result in
            switch result {
            case .success(let receipt):
                self.sessionReceipt = receipt
                self.stateHandler?.state = .finish(PurchaseActionResult.receiptValidationSuccess)
            case .error(let error):
                self.stateHandler?.state = .finish(PurchaseActionResult.error(error.asPurchaseError()))
            }
        }
    }
    
    public func validateSubscription(productID: String, type: SubscriptionType) {
        stateHandler?.state = .loading
        guard let receipt = self.sessionReceipt else {
            self.stateHandler?.state = .finish(PurchaseActionResult.error(PurchaseError.noReceiptData))
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
                self.stateHandler?.state = .finish(PurchaseActionResult.error(.noActiveSubscription))
                return
            }
            self.stateHandler?.state = .finish(PurchaseActionResult.subscriptionValidationSucess(latestActualSubscription))
        case .notPurchased, .expired(_, _):
            self.stateHandler?.state = .finish(PurchaseActionResult.error(.noActiveSubscription))
        }
    }
    
    public func completeTransactions() {
        SwiftyStoreKit.completeTransactions(completion: { [unowned self] (_) in
             self.stateHandler?.state = .finish(PurchaseActionResult.completionSuccess)
        })
    }
}
