//
//  ProductsInfoController.swift
//  PurchaseController
//
//  Created by Igor Kulik on 7/15/19.
//

import Foundation
import StoreKit

typealias RetrievedProductsInfo = (products: Set<SKProduct>, invalidProductIdentifiers: [String])

protocol ProductsInfoObserver: class {
    var onRetrieve: ((_ productsInfo: RetrievedProductsInfo) -> Void)? { get set }
    var onError: ((_ error: Error) -> Void)? { get set }
}

final class PCProductsInfoController: NSObject {
    
    // MARK: - Properties

    private weak var observer: ProductsInfoObserver?
    private var productsRequest: SKProductsRequest?
    
    // MARK: - Lifecycle
    
    init(observer: ProductsInfoObserver) {
        self.observer = observer
        super.init()
    }

    deinit {
        productsRequest?.cancel()
        productsRequest = nil
    }
    
    // MARK: - Public methods
    
    func retrieveProductsInfo(_ productIdentifiers: Set<String>) {
            productsRequest?.cancel()
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsRequest?.delegate = self
            productsRequest?.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension PCProductsInfoController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsRequest = nil
        observer?.onRetrieve?((Set(response.products), response.invalidProductIdentifiers))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequest = nil
        observer?.onError?(error)
    }
}
