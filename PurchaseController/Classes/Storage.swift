//
//  Storage.swift
//  Pods
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import Foundation

/** Class to store all data, that should be accessible from one point */
class Storage {
    
    private var persistor: PurchasePersistor
    public private(set) var sessionReceipt: Receipt?
    
    /** Defult init with persistor object
     *
     * - Parameter persistor: object conforms PurchasePersistor protocol
     */
    init(persistor: PurchasePersistor) {
        self.persistor = PurchasePersistorImplementation()
    }
}

// MARK: - Access

extension Storage {
    /** Method to set session receipt instance
     *
     * - Parameters:
     *   - receipt: Receipt instance available after validation
     *   - file: default full path of the file from which method was accessed
     */
    func set(receipt: Receipt, file: String = #file) throws {
        if file.contains(String(describing: PurchaseController.self)) {
            self.sessionReceipt = receipt
        } else {
            throw PurchaseError.unauthorizedReceiptSet
        }
    }
}

// MARK: - PurchasePersistor

extension Storage: PurchasePersistor {
    public func persist(products: Set<SKProduct>) {
        self.persistor.persist(products: products)
    }
    
    public func extract(products: Set<SKProduct>) {
        self.persistor.extract(products: products)
    }
    
    public func fetchProducts() -> [SKProduct] {
        return self.persistor.fetchProducts()
    }
    
    public func persistPurchased(products: [PurchaseItem]) {
        self.persistor.persistPurchased(products: products)
    }
    
    public func extractPurchased(products: [PurchaseItem]) {
        self.persistor.extractPurchased(products: products)
    }
    
    public func fetchPurchasedProducts() -> [PurchaseItem] {
        return self.persistor.fetchPurchasedProducts()
    }
}
