//
//  PurchaseErrorHandling.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

/// PurchaseError types
///
/// - unknown: client is not allowed to issue the request, etc.
/// - clientInvalid: invalid client data (payment method, not enough funds, etc).
/// - paymentCancelled: user cancelled the request, etc.
/// - paymentInvalid: purchase identifier was invalid, etc.
/// - paymentNotAllowed: this device is not allowed to make the payment
/// - storeProductNotAvailable: product is not available in the current storefront
/// - cloudServicePermissionDenied: user has not allowed to access cloud service information
/// - cloudServiceNetworkConnectionFailed: the device could not connect to the nework
/// - cloudServiceRevoked: user has revoked permission to use this cloud service
/// - noLocalProduct: product wasn't retrieved
/// - networkError: operation failed due to network error
/// - noReceiptData: no receipt data, try to validate local receipt
/// - noRemoteData: no remote data received
/// - requestBodyEncodeError: error when encoding HTTP body into JSON
/// - receiptJsonDecodeError: error when decoding response
/// - receiptInvalid: receive invalid - bad status returned
/// - noActiveSubscription: no active subscription after validation or all expired
/// - restoreFailed: restoreFailed : check retrieved products

public enum PurchaseError: Int {
    case unknown
    case clientInvalid
    case paymentCancelled
    case paymentInvalid
    case paymentNotAllowed
    case storeProductNotAvailable
    case cloudServicePermissionDenied
    case cloudServiceNetworkConnectionFailed
    case cloudServiceRevoked
    case noLocalProduct
    case networkError
    case noReceiptData
    case noRemoteData
    case requestBodyEncodeError
    case receiptJsonDecodeError
    case receiptInvalid
    case noActiveSubscription
    case restoreFailed
}

public extension Error {
    /// Error convert function
    ///
    /// - Returns: converted self to PurchaseError
    func asPurchaseError() -> PurchaseError {
        if (self as NSError).code == NSURLErrorNotConnectedToInternet {
            return .networkError
        }
        return .unknown
    }
}

public extension SKError {
    /// Error convert function
    ///
    /// - Returns: converted self to PurchaseError
    func asPurchaseError() -> PurchaseError {
        switch (self as SKError).code {
        case .unknown: return .unknown
        case .clientInvalid: return .clientInvalid
        case .paymentCancelled: return .paymentCancelled
        case .paymentInvalid: return .paymentInvalid
        case .paymentNotAllowed: return .paymentNotAllowed
        case .storeProductNotAvailable: return .storeProductNotAvailable
        case .cloudServicePermissionDenied: return .cloudServicePermissionDenied
        case .cloudServiceNetworkConnectionFailed: return .cloudServiceNetworkConnectionFailed
        case .cloudServiceRevoked: return .cloudServiceRevoked
        }
    }
}

public extension ReceiptError {
    /// Error convert function
    ///
    /// - Returns: converted self to PurchaseError
    func asPurchaseError() -> PurchaseError {
        switch self {
        case .noReceiptData: return .noReceiptData
        case .noRemoteData: return .noRemoteData
        case .requestBodyEncodeError(_): return .requestBodyEncodeError
        case .networkError(_): return .networkError
        case .jsonDecodeError(_): return .receiptJsonDecodeError
        case .receiptInvalid(_): return .receiptInvalid
        }
    }
}
