//
//  PurchasePersistance.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

public protocol PurchasePersistor {
    func persist(products: [SKProduct])
    func extract(products: [SKProduct])
    func fetchProducts() -> [SKProduct]
    
    func persistPurchased(products: [PurchaseItem])
    func extractPurchased(products: [PurchaseItem])
    func fetchPurchasedProducts() -> [PurchaseItem]
}

public final class PurchasePersistorImplementation: PurchasePersistor {
    
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
