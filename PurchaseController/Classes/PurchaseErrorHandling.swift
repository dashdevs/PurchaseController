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
/// - privacyAcknowledgementRequired: user needs to acknowledge Apple's privacy policy
/// - unauthorizedRequestData: app is attempting to use SKPayment's requestData property, but does not have the appropriate entitlement
/// - invalidOfferIdentifier: specified subscription offer identifier is not valid
/// - invalidSignature: cryptographic signature provided is not valid
/// - missingOfferParams: one or more parameters from SKPaymentDiscount is missing
/// - invalidOfferPrice: price of the selected offer is not valid (e.g. lower than the current base subscription price)
/// - noLocalProduct: product wasn't retrieved
/// - networkError: operation failed due to network error
/// - noReceiptData: no receipt data, try to validate local receipt
/// - noOriginalTransactionData: no original transaction to process
/// - noRemoteData: no remote data received
/// - requestBodyEncodeError: error when encoding HTTP body into JSON
/// - receiptJsonDecodeError: error when decoding response
/// - receiptInvalid: receive invalid - bad status returned
/// - noActiveSubscription: no active subscription after validation or all expired
/// - restoreFailed: restoreFailed : check retrieved products
/// - receiptSerializationError: Notifies handler if a receipt can not serialization
public enum PurchaseError: Int, Error {
    case unknown
    case clientInvalid
    case paymentCancelled
    case paymentInvalid
    case paymentNotAllowed
    case storeProductNotAvailable
    case cloudServicePermissionDenied
    case cloudServiceNetworkConnectionFailed
    case cloudServiceRevoked
    case privacyAcknowledgementRequired
    case unauthorizedRequestData
    case invalidOfferIdentifier
    case invalidSignature
    case missingOfferParams
    case invalidOfferPrice
    case noLocalProduct
    case networkError
    case noReceiptData
    case noOriginalTransactionData
    case noRemoteData
    case requestBodyEncodeError
    case receiptJsonDecodeError
    case receiptInvalid
    case noActiveSubscription
    case restoreFailed
    case receiptSerializationError
    case purchaseSynchronizationError
}

extension PurchaseError: CustomDebugStringConvertible {
    fileprivate var description: String {
        switch self {
        case .unknown:
            return "Client is not allowed to issue the request, etc."
        case .clientInvalid:
            return "Invalid client data (payment method, not enough funds, etc)."
        case .paymentCancelled:
            return "User cancelled the request, etc."
        case .paymentInvalid:
            return "Purchase identifier was invalid, etc."
        case .paymentNotAllowed:
            return "This device is not allowed to make the payment."
        case .storeProductNotAvailable:
            return "Product is not available in the current storefront."
        case .cloudServicePermissionDenied:
            return "User has not allowed to access cloud service information."
        case .cloudServiceNetworkConnectionFailed:
            return "The device could not connect to the network."
        case .cloudServiceRevoked:
            return "User has revoked permission to use this cloud service."
        case .privacyAcknowledgementRequired:
            return "User needs to acknowledge Apple's privacy policy."
        case .unauthorizedRequestData:
            return "App is attempting to use SKPayment's requestData property, but does not have the appropriate entitlement."
        case .invalidOfferIdentifier:
            return "Specified subscription offer identifier is not valid."
        case .invalidSignature:
            return "Cryptographic signature provided is not valid."
        case .missingOfferParams:
            return "One or more parameters from SKPaymentDiscount is missing."
        case .invalidOfferPrice:
            return "Price of the selected offer is not valid (e.g. lower than the current base subscription price)."
        case .noLocalProduct:
            return "Product wasn't retrieved."
        case .networkError:
            return "Operation failed due to network error."
        case .noReceiptData:
            return "No receipt data, try to validate local receipt."
        case .noOriginalTransactionData:
            return "No original transaction to process."
        case .noRemoteData:
            return "No remote data received."
        case .requestBodyEncodeError:
            return "Error when encoding HTTP body into JSON."
        case .receiptJsonDecodeError:
            return "Error when decoding response."
        case .receiptInvalid:
            return "Receive invalid - bad status returned."
        case .noActiveSubscription:
            return "No active subscription after validation or all expired."
        case .restoreFailed:
            return "restoreFailed: check retrieved products."
        case .receiptSerializationError:
            return "The receipt can not be serialized."
        case .purchaseSynchronizationError:
            return "Local validated receipt not found."
        }
    }
    
    public var localizedDescription: String {
        return description
    }
    
    public var debugDescription: String {
        return "\(Constants.domain): \(description)"
    }
    
    init(code: Int) {
        self = PurchaseError(rawValue: code) ?? .unknown
    }
}

// MARK: - Constants
extension PurchaseError {
    struct Constants {
        static let domain = "PurchaseError"
    }
}

// MARK: - CustomNSError
extension PurchaseError: CustomNSError {
    public static var errorDomain: String {
        return Constants.domain
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

public extension Error {
    /// Error convert function
    ///
    /// - Returns: converted self to PurchaseError
    func asPurchaseError() -> PurchaseError {
        switch (self as NSError).code {
        case NSURLErrorNotConnectedToInternet:
            return .networkError
        default:
            return .unknown
        }
    }
}

public extension SKError {
    /// Error convert function
    ///
    /// - Returns: converted self to PurchaseError
    func asPurchaseError() -> PurchaseError {
        return PurchaseError(code: code.rawValue)
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

public extension PurchaseError {
    /// PurchaseError convert function
    ///
    /// - Returns: converted self to NSError
    func asNSError() -> NSError {
        return self as NSError
    }
}
