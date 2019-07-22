//
//  ReceiptFetcher.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation
import StoreKit

/**
 Defines required callback properties for objects
 that need to observe state changes of `ReceiptFetcher` instance.
 */
protocol ReceiptFetcherObserver: class {
    var onReceiptFetch: ((_ receiptData: Data) -> Void)? { get set }
    var onError: ((_ error: Error) -> Void)? { get set }
}

final class ReceiptFetcher: NSObject {
    
    // MARK: - Properties
    
    private let appStoreReceiptURL: URL?
    weak var observer: ReceiptFetcherObserver?
    
    private var refreshRequest: SKReceiptRefreshRequest?

    // MARK: - Lifecycle
    
    init(appStoreReceiptURL: URL? = Bundle.main.appStoreReceiptURL, observer: ReceiptFetcherObserver) {
        self.appStoreReceiptURL = appStoreReceiptURL
        self.observer = observer
    }

    deinit {
        refreshRequest?.cancel()
        refreshRequest = nil
    }

    // MARK: - Public methods
    
    /**
     Fetch application receipt. This method does two
     * If the receipt is missing, refresh it.
     * If the receipt is available or is refreshed, return it.
     - Parameter forceRefresh: If true, refreshes the receipt even if one already exists.
     */
    func fetchReceipt(forceRefresh: Bool) {
        if !forceRefresh {
            fetchReceipt()
        } else {
            refreshRequest?.cancel()
            refreshRequest = SKReceiptRefreshRequest()
            refreshRequest?.delegate = self
            refreshRequest?.start()
        }
    }
    
    // MARK: - Private methods
    
    /**
     Fetches receipt data from location
     specified with `appStoreReceiptURL`.
     */
    private func fetchReceipt() {
        if let receiptURL = appStoreReceiptURL,
            let receiptData = try? Data(contentsOf: receiptURL) {
            observer?.onReceiptFetch?(receiptData)
        } else {
            observer?.onError?(ReceiptError.noReceiptData)
        }
    }
}

// MARK: - SKRequestDelegate
extension ReceiptFetcher: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        fetchReceipt()
        refreshRequest = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        observer?.onError?(PurchaseError.networkError)
        refreshRequest = nil
    }
}
