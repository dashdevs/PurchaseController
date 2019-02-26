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
    func update(newState: PurchaseActionState, from state: PurchaseActionState)
}

public final class PurchaseController {
    private(set) var sessionReceipt: ReceiptInfo?
    private var persistor: PurchasePersistor
    private var stateHandler: PurchaseStateHandler?
    private var purchaseActionState: PurchaseActionState {
        willSet {
            stateHandler?.update(newState: newValue, from: purchaseActionState)
        }
    }
    
    public static var defaultPersistor: PurchasePersistor = {
        return PurchasePersistorImplementation()
    }()
    
    public init(stateHandler: PurchaseStateHandler?, persistor: PurchasePersistor = defaultPersistor) {
        self.persistor = persistor
        self.stateHandler = stateHandler
        self.purchaseActionState = .none
    }
    
    // MARK: - Public
    
    public func localPurschasedProducts(by filter: (PurchaseItem) throws -> Bool) throws -> [PurchaseItem] {
        return try persistor.fetchPurchasedProducts().filter(filter)
    }
    
    public func localProducts(by filter: (SKProduct) throws -> Bool) throws -> [SKProduct] {
        return try persistor.fetchProducts().filter(filter)
    }
    
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
    
    public func completeTransactions() {
        SwiftyStoreKit.completeTransactions(completion: { [unowned self] (_) in
             self.purchaseActionState = .finish(PurchaseActionResult.completionSuccess)
        })
    }
}
