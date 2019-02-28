//
//  PurchasePersistance.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

public protocol PurchasePersistor {
    /// Func that store SKProduct to persistor (should be used for retrieved objects)
    ///
    /// - Parameter products: Array of retrieved SKProduct
    func persist(products: [SKProduct])
    /// Func that extract SKProduct from persistor (should be used for retrieved objects)
    ///
    /// - Parameter products: products: Array of retrieved SKProduct to extract
    func extract(products: [SKProduct])
    /// Func that fetch SKProducts from persistor (should be used for retrieved objects)
    ///
    /// - Returns: array of SKProducts, stored in persistor
    func fetchProducts() -> [SKProduct]
    
    /// Func that store PurchaseItem to persistor (should be used for purchased objects)
    ///
    /// - Parameter products: Array of retrieved PurchaseItem
    func persistPurchased(products: [PurchaseItem])
    /// Func that extract PurchaseItem from persistor (should be used for purchased objects)
    ///
    /// - Parameter products: Array of retrieved PurchaseItem to extract
    func extractPurchased(products: [PurchaseItem])
    /// Func that fetch PurchaseItem from persistor (should be used for purchased objects)
    ///
    /// - Returns: array of PurchaseItem, stored in persistor
    func fetchPurchasedProducts() -> [PurchaseItem]
}

 final class PurchasePersistorImplementation: PurchasePersistor {
    
    // MARK: - Private
    
    private var purchasedProducts: [PurchaseItem] = []
    private var localProducts: [SKProduct] = []
    
    // MARK: - Public
    
    public func persist(products: [SKProduct]) {
        localProducts.append(contentsOf: products)
    }
    
    public func extract(products: [SKProduct]) {
        localProducts = Array(Set(localProducts).subtracting(products))
    }
    
    public func fetchProducts() -> [SKProduct] {
        return localProducts
    }
    
    public func persistPurchased(products: [PurchaseItem]) {
        purchasedProducts.append(contentsOf: products)
    }
    
    public func extractPurchased(products: [PurchaseItem]) {
        purchasedProducts = Array(Set<PurchaseItem>(purchasedProducts).subtracting(products))
    }
    
    public func fetchPurchasedProducts() -> [PurchaseItem] {
        return purchasedProducts
    }
    
}
