//
//  PurchasePersistance.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

public protocol PurchasePersistor {
    
    /// Function that store SKProduct to persistor (should be used for retrieved objects)
    ///
    /// - Parameter products: Set of retrieved SKProduct
    func persist(products: Set<SKProduct>)
    /// Function that extracts SKProduct from persistor (should be used for retrieved objects)
    ///
    /// - Parameter products: products: Set of retrieved SKProduct to extract
    func extract(products: Set<SKProduct>)
    /// Function that fetches SKProducts from persistor (should be used for retrieved objects)
    ///
    /// - Returns: array of SKProducts, stored in persistor
    func fetchProducts() -> [SKProduct]
    
    /// Function that stores PurchaseItem to persistor (should be used for purchased objects)
    ///
    /// - Parameter products: Array of retrieved PurchaseItem
    func persistPurchased(products: [PurchaseItem])
    /// Function that extracts PurchaseItem from persistor (should be used for purchased objects)
    ///
    /// - Parameter products: Array of retrieved PurchaseItem to extract
    func extractPurchased(products: [PurchaseItem])
    /// Function that fetches PurchaseItem from persistor (should be used for purchased objects)
    ///
    /// - Returns: array of PurchaseItem, stored in persistor
    func fetchPurchasedProducts() -> [PurchaseItem]
}

final class PurchasePersistorImplementation: PurchasePersistor {
    
    private typealias ProductsDictionary = [String: SKProduct]
    
    // MARK: - Private
    
    private var purchasedProducts: [PurchaseItem] = []
    private var localProducts = ProductsDictionary()
    
    // MARK: - Public
    
    public func persist(products: Set<SKProduct>) {
        products.forEach({ localProducts[$0.productIdentifier] = $0 })
    }
    
    public func extract(products: Set<SKProduct>) {
        products.forEach({ localProducts.removeValue(forKey: $0.productIdentifier) })
    }
    
    public func fetchProducts() -> [SKProduct] {
        return Array(localProducts.values)
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
