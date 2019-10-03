//
//  PurchaseErrorHandling.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import StoreKit

// MARK: - Error Domains
extension PurchaseControllerImpl {
    enum ErrorDomain: String {
        case storeKit = "SKErrorDomain"
        case purchase = "PurchaseErrorDomain"
        case receipt = "ReceiptErrorDomain"
    }
}

/// PurchaseError types
///
/// - noLocalProduct: product wasn't retrieved
/// - networkError: operation failed due to network error
/// - noOriginalTransactionData: no original transaction to process
/// - noActiveSubscription: no active subscription after validation or all expired
/// - restoreFailed: restoreFailed : check retrieved products
/// - receiptSerializationError: Notifies handler if a receipt can not serialization
/// - transactionPaymentNotFound: Corresponding payment for the transaction not found.
/// - unauthorizedReceiptSet: Notifies if Storage.sessionReceipt was set from an unauthorized place
public enum PurchaseError: Int, Error {
    case noLocalProduct
    case networkError
    case noOriginalTransactionData
    case noActiveSubscription
    case restoreFailed
    case receiptSerializationError
    case purchaseSynchronizationError
    case transactionPaymentNotFound
    case unauthorizedReceiptSet
}

// MARK: - CustomDebugStringConvertible
extension PurchaseError: CustomDebugStringConvertible {
    fileprivate var description: String {
        switch self {
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
        case .transactionPaymentNotFound:
            return "Corresponding payment for the transaction not found."
        case .unauthorizedReceiptSet:
            return "Trying to set Storage.sessionReceipt from an unauthorized place. This operation can only be performed from PurchaseController instance."
        }
    }
    
    public var localizedDescription: String {
        return description
    }
    
    public var debugDescription: String {
        return "\(PurchaseControllerImpl.ErrorDomain.purchase.rawValue): \(description)"
    }
}

// MARK: - CustomNSError

extension PurchaseError: CustomNSError {
    public static var errorDomain: String {
        return PurchaseControllerImpl.ErrorDomain.purchase.rawValue
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}

/* Errors that may occur during local receipt validation
*
* - noReceiptData: IAP receipt data not found at `Bundle.main.appStoreReceiptURL`.
* - malformedReceipt: The extracted receipt contents do not match ASN.1 Set structure defined by Apple.
* - emptyReceiptContents: Failed to extract the receipt contents from its PKCS #7 container.
* - receiptNotSigned: The receipt that was extracted is not signed at all.
* - appleRootCertificateNotFound: The application bundle doesn't have a copy of Apple’s root certificate to validate the signature with.
* - receiptSignatureInvalid: The signature on the receipt is invalid because it doesn’t match against Apple’s root certificate.
* - malformedInAppPurchaseReceipt: The extracted receipt is not an ASN1 Set.
* - incorrectHash: The extracted SHA1 hash is not identical to the receipt hash.
* - noRemoteData: No data received during server validation.
* - unknown: Not decodable status
* - none: No status returned
* - valid: valid status
* - jsonNotReadable: The App Store could not read the JSON object you provided.
* - receiptCouldNotBeAuthenticated: The receipt could not be authenticated.
* - secretNotMatching: The receipt server is not currently available.
* - receiptServerUnavailable: This receipt is valid but the subscription has expired.
* - subscriptionExpired: The receipt server is not currently available.
* - testReceipt: This receipt is from the test environment, but it was sent to the production environment for verification.
* - productionEnvironment: This receipt is from the production environment, but it was sent to the test environment for verification.
*/
public enum ReceiptError: Int, Error {
    //General
    case noReceiptData
    case malformedReceipt
    // Local
    case emptyReceiptContents
    case receiptNotSigned
    case appleRootCertificateNotFound
    case receiptSignatureInvalid
    case malformedInAppPurchaseReceipt
    case incorrectHash
    //Server
    case noRemoteData
    case unknown
    case noStatus
    case jsonNotReadable
    case receiptCouldNotBeAuthenticated
    case secretNotMatching
    case receiptServerUnavailable
    case subscriptionExpired
    case testReceipt
    case productionEnvironment
    
    // Status code returned by remote server
    // see Table 2-1  Status codes
    /** Status code returned by remote server
    *   see Table 2-1  Status codes
    * - unknown: Not decodable status was returned.
    * - noStatus: Server did not return any status.
    * - jsonNotReadable: The App Store could not read the JSON object you provided.
    * - malformedOrMissingData: The data in the receipt-data property was malformed or missing.
    * - receiptCouldNotBeAuthenticated: The receipt could not be authenticated.
    * - secretNotMatching: The receipt sharedSecret is invalid.
    * - receiptServerUnavailable: This receipt is valid but the subscription has expired.
    * - subscriptionExpired: The receipt server is not currently available.
    * - testReceipt: This receipt is from the test environment, but it was sent to the production environment for verification.
    * - productionEnvironment: This receipt is from the production environment, but it was sent to the test environment for verification.
 */
    private enum ReceiptStatus: Int {
        case unknown = -2
        case none = -1
        case valid = 0
        case jsonNotReadable = 21000
        case malformedOrMissingData = 21002
        case receiptCouldNotBeAuthenticated = 21003
        case secretNotMatching = 21004
        case receiptServerUnavailable = 21005
        case subscriptionExpired = 21006
        case testReceipt = 21007
        case productionEnvironment = 21008
    }
    
    init?(with status: Int) {
        guard let statusObj = ReceiptStatus(rawValue: status) else { self = .unknown; return }
        switch statusObj {
        case .unknown, .valid:
            self = .unknown
        case .none:
            self = .noStatus
        case .jsonNotReadable:
            self = .jsonNotReadable
        case .malformedOrMissingData:
            self = .malformedReceipt
        case .receiptCouldNotBeAuthenticated:
            self = .receiptCouldNotBeAuthenticated
        case .secretNotMatching:
            self = .secretNotMatching
        case .receiptServerUnavailable:
            self = .receiptServerUnavailable
        case .testReceipt:
            self = .testReceipt
        case .productionEnvironment:
            self = .productionEnvironment
        case .subscriptionExpired:
            self = .subscriptionExpired
        }
    }

}

// MARK: - CustomDebugStringConvertible
extension ReceiptError: CustomDebugStringConvertible {
    fileprivate var description: String {
        switch self {
        case .noReceiptData:
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
        case .noRemoteData:
            return "No data received during server validation."
        case .unknown:
            return "Not decodable status."
        case .noStatus:
            return "No status returned."
        case .jsonNotReadable:
            return "The App Store could not read the JSON object you provided."
        case .receiptCouldNotBeAuthenticated:
            return "The receipt could not be authenticated."
        case .secretNotMatching:
            return "The receipt sharedSecret is invalid."
        case .receiptServerUnavailable:
            return "The receipt server is not currently available."
        case .subscriptionExpired:
            return "This receipt is valid but the subscription has expired."
        case .testReceipt:
            return "This receipt is from the test environment, but it was sent to the production environment for verification."
        case .productionEnvironment:
            return "This receipt is from the production environment, but it was sent to the test environment for verification."
        }
    }
    
    public var localizedDescription: String {
        return description
    }
    
    public var debugDescription: String {
        return "\(PurchaseControllerImpl.ErrorDomain.receipt.rawValue): \(description)"
    }
}

// MARK: - CustomNSError
extension ReceiptError: CustomNSError {
    public static var errorDomain: String {
        return PurchaseControllerImpl.ErrorDomain.receipt.rawValue
    }
    
    public var errorCode: Int {
        return rawValue
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: description]
    }
}


public extension Error {
    /// self converted to PurchaseError.
    func purchaseErrorIfApplies() -> Error {
        switch (self as NSError).code {
        case NSURLErrorNotConnectedToInternet:
            return PurchaseError.networkError
        default:
            return self
        }
    }
}

public extension PurchaseError {
    /// self converted to NSError.
    var nsError: NSError {
        return self as NSError
    }
}
