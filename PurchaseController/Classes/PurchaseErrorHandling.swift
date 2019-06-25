//
//  PurchaseErrorHandling.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit
import SwiftyStoreKit

// MARK: - Error Domains
public extension PurchaseController {
    enum ErrorDomain: String {
        case storeKit = "SKErrorDomain"
        case purchase = "PurchaseErrorDomain"
        case receipt = "ReceiptErrorDomain"
        case localReceiptValidation = "LocalReceiptValidationErrorDomain"
    }
}

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
/// - noOriginalTransactionData: no original transaction to process
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
    case noOriginalTransactionData
    case noActiveSubscription
    case restoreFailed
    case receiptSerializationError
    case purchaseSynchronizationError
}

// MARK: - CustomDebugStringConvertible
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
        case .noOriginalTransactionData:
            return "No original transaction to process."
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
        return "\(PurchaseController.ErrorDomain.purchase.rawValue): \(description)"
    }
    
    init(code: Int) {
        self = PurchaseError(rawValue: code) ?? .unknown
    }
}

// MARK: - CustomNSError
extension PurchaseError: CustomNSError {
    public static var errorDomain: String {
        return PurchaseController.ErrorDomain.purchase.rawValue
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

/// Errors that may occur during local receipt validation
///
/// - couldNotFindReceipt: IAP receipt data not found at `Bundle.main.appStoreReceiptURL`.
/// - emptyReceiptContents: Failed to extract the receipt contents from its PKCS #7 container.
/// - receiptNotSigned: The receipt that was extracted is not signed at all.
/// - appleRootCertificateNotFound: The application bundle doesn't have a copy of Apple’s root certificate to validate the signature with.
/// - receiptSignatureInvalid: The signature on the receipt is invalid because it doesn’t match against Apple’s root certificate.
/// - malformedReceipt: The extracted receipt contents do not match ASN.1 Set structure defined by Apple.
/// - malformedInAppPurchaseReceipt: The extracted receipt is not an ASN1 Set.
/// - incorrectHash: The extracted SHA1 hash is not identical to the receipt hash.
public enum LocalReceiptValidationError: Int, Error {
    case couldNotFindReceipt
    case emptyReceiptContents
    case receiptNotSigned
    case appleRootCertificateNotFound
    case receiptSignatureInvalid
    case malformedReceipt
    case malformedInAppPurchaseReceipt
    case incorrectHash
}

// MARK: - CustomDebugStringConvertible
extension LocalReceiptValidationError: CustomDebugStringConvertible {
    fileprivate var description: String {
        switch self {
        case .couldNotFindReceipt:
            return "IAP receipt data not found at `Bundle.main.appStoreReceiptURL`."
        case .emptyReceiptContents:
            return "Failed to extract the receipt contents from its PKCS #7 container."
        case .receiptNotSigned:
            return "The receipt that was extracted is not signed at all."
        case .appleRootCertificateNotFound:
            return "The application bundle doesn't have a copy of Apple’s root certificate to validate the signature with."
        case .receiptSignatureInvalid:
            return "The signature on the receipt is invalid because it doesn’t match against Apple’s root certificate."
        case .malformedReceipt:
            return "The extracted receipt contents do not match ASN.1 Set structure defined by Apple."
        case .malformedInAppPurchaseReceipt:
            return "The extracted receipt is not an ASN1 Set."
        case .incorrectHash:
            return "The extracted SHA1 hash is not identical to the receipt hash."
        }
    }
    
    public var localizedDescription: String {
        return description
    }
    
    public var debugDescription: String {
        return "\(PurchaseController.ErrorDomain.localReceiptValidation.rawValue): \(description)"
    }
}

// MARK: - CustomNSError
extension LocalReceiptValidationError: CustomNSError {
    public static var errorDomain: String {
        return PurchaseController.ErrorDomain.localReceiptValidation.rawValue
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

// MARK: - CustomDebugStringConvertible
extension ReceiptError: CustomDebugStringConvertible {

    fileprivate var description: String {
        switch self {
        case .noReceiptData:
            return "No receipt data."
        case .noRemoteData:
            return "No data recieved."
        case .requestBodyEncodeError:
            return "Error when encoding HTTP body into JSON."
        case .networkError:
            return "Error when proceeding request."
        case .jsonDecodeError:
            return "Error when decoding response."
        case .receiptInvalid:
            return "Receive invalid - bad status returned."
        }
    }
    
    public var localizedDescription: String {
        return description
    }
    
    public var debugDescription: String {
        return "\(PurchaseController.ErrorDomain.receipt.rawValue): \(description)"
    }
}

// MARK: - CustomNSError
extension ReceiptError: CustomNSError {
    public static var errorDomain: String {
        return PurchaseController.ErrorDomain.receipt.rawValue
    }
    
    public var errorCode: Int {
        return 0
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

public extension Error {
    /// self converted to PurchaseError.
    var purchaseError: PurchaseError {
        switch (self as NSError).code {
        case NSURLErrorNotConnectedToInternet:
            return .networkError
        default:
            return .unknown
        }
    }
}

public extension SKError {
    /// self converted to PurchaseError.
    var purchaseError: PurchaseError {
        return PurchaseError(code: code.rawValue)
    }
}

public extension PurchaseError {
    /// self converted to NSError.
    var nsError: NSError {
        return self as NSError
    }
}
