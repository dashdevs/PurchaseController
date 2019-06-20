//
//  ReceiptValidator.swift
//  Pods-PurchaseController_Example
//
//

import Foundation
import StoreKit
import openssl
import SwiftyStoreKit

#if os(macOS)
import IOKit
#endif

// MARK: Output
enum ReceiptValidationResult {
    case success(ParsedReceipt)
    case error(ReceiptValidationError)
}

public enum ReceiptValidationError: Error {
    case couldNotFindReceipt
    case emptyReceiptContents
    case receiptNotSigned
    case appleRootCertificateNotFound
    case receiptSignatureInvalid
    case malformedReceipt
    case malformedInAppPurchaseReceipt
    case incorrectHash
}

public struct ParsedReceipt {
    let bundleIdentifier: String?
    let bundleIdData: NSData?
    let appVersion: String?
    let opaqueValue: NSData?
    let sha1Hash: NSData?
    let inAppPurchaseReceipts: [ParsedInAppPurchaseReceipt]?
    let originalAppVersion: String?
    let receiptCreationDate: Date?
    let expirationDate: Date?
}


public struct ParsedInAppPurchaseReceipt {
    let quantity: Int?
    let productIdentifier: String?
    let transactionIdentifier: String?
    let originalTransactionIdentifier: String?
    let purchaseDate: Date?
    let originalPurchaseDate: Date?
    let subscriptionExpirationDate: Date?
    let subscriptionIntroductoryPricePeriod: Bool?
    let cancellationDate: Date?
    let webOrderLineItemId: Int?
}

// MARK: Receipt Validator and supporting Types

extension LocalReceiptValidator: ReceiptValidatorProtocol {
    public func validate(completion: @escaping (PCReceiptValidationResult) -> Void) {
        switch validateReceipt() {
        case .success(let receipt):
            print(receipt)
//            completion(.success(receipt: receipt))
        case .error(let error):
            completion(.error(error: error))
        }
    }
}

public struct LocalReceiptValidator {
    let receiptLoader = ReceiptLoader()
    let receiptExtractor = ReceiptExtractor()
    let receiptSignatureValidator = ReceiptSignatureValidator()
    let receiptParser = ReceiptParser()
    
    public init() {}
    
    func validateReceipt() -> ReceiptValidationResult {
        do {
            let receiptData = try receiptLoader.loadReceipt()
            let receiptContainer = try receiptExtractor.extractPKCS7Container(receiptData)
            
            try receiptSignatureValidator.checkSignaturePresence(receiptContainer)
            try receiptSignatureValidator.checkSignatureAuthenticity(receiptContainer)
            
            let parsedReceipt = try receiptParser.parse(receiptContainer)
            try validateHash(receipt: parsedReceipt)
            
            return .success(parsedReceipt)
        } catch {
            return .error(error as! ReceiptValidationError)
        }
    }
    
    
    // Returns a NSData object, containing the device's GUID.
    private func deviceIdentifierData() -> NSData? {
        #if os(macOS)
        
        var master_port = mach_port_t()
        var kernResult = IOMasterPort(mach_port_t(MACH_PORT_NULL), &master_port)
        
        guard kernResult == KERN_SUCCESS else {
            return nil
        }
        
        guard let matchingDict = IOBSDNameMatching(master_port, 0, "en0") else {
            return nil
        }
        
        var iterator = io_iterator_t()
        kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator)
        guard kernResult == KERN_SUCCESS else {
            return nil
        }
        
        var macAddress: NSData?
        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            
            var parentService = io_object_t()
            kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService)
            
            if kernResult == KERN_SUCCESS {
                macAddress = IORegistryEntryCreateCFProperty(parentService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? NSData
                IOObjectRelease(parentService)
            }
            
            IOObjectRelease(service)
        }
        
        IOObjectRelease(iterator)
        return macAddress
        
        #else // iOS, watchOS, tvOS
        
        var deviceIdentifier = UIDevice.current.identifierForVendor?.uuid
        
        let rawDeviceIdentifierPointer = withUnsafePointer(to: &deviceIdentifier, {
            (unsafeDeviceIdentifierPointer: UnsafePointer<uuid_t?>) -> UnsafeRawPointer in
            return UnsafeRawPointer(unsafeDeviceIdentifierPointer)
        })
        
        return NSData(bytes: rawDeviceIdentifierPointer, length: 16)
        
        #endif
    }
    
    fileprivate func validateHash(receipt: ParsedReceipt) throws {
        // Make sure that the ParsedReceipt instances has non-nil values needed for hash comparison
        guard let receiptOpaqueValueData = receipt.opaqueValue else { throw ReceiptValidationError.incorrectHash }
        guard let receiptBundleIdData = receipt.bundleIdData else { throw ReceiptValidationError.incorrectHash }
        guard let receiptHashData = receipt.sha1Hash else { throw ReceiptValidationError.incorrectHash }
        
        guard let deviceIdentifierData = self.deviceIdentifierData() else {
            throw ReceiptValidationError.malformedReceipt
        }
        
        // Compute the hash for your app & device
        
        // Set up the hasing context
        var computedHash = Array<UInt8>(repeating: 0, count: 20)
        var sha1Context = SHA_CTX()
        
        SHA1_Init(&sha1Context)
        SHA1_Update(&sha1Context, deviceIdentifierData.bytes, deviceIdentifierData.length)
        SHA1_Update(&sha1Context, receiptOpaqueValueData.bytes, receiptOpaqueValueData.length)
        SHA1_Update(&sha1Context, receiptBundleIdData.bytes, receiptBundleIdData.length)
        SHA1_Final(&computedHash, &sha1Context)
        
        let computedHashData = NSData(bytes: &computedHash, length: 20)
        
        // Compare the computed hash with the receipt's hash
        guard computedHashData.isEqual(to: receiptHashData as Data) else { throw ReceiptValidationError.incorrectHash }
    }
}

struct ReceiptLoader {
    let receiptUrl = Bundle.main.appStoreReceiptURL
    
    func loadReceipt() throws -> Data {
        if(receiptFound()) {
            let receiptData = try? Data(contentsOf: receiptUrl!)
            if let receiptData = receiptData {
                return receiptData
            }
        }
        
        throw ReceiptValidationError.couldNotFindReceipt
    }
    
    fileprivate func receiptFound() -> Bool {
        do {
            if let isReachable = try receiptUrl?.checkResourceIsReachable() {
                return isReachable
            }
        } catch _ {
            return false
        }
        
        return false
    }
}

struct ReceiptExtractor {
    func extractPKCS7Container(_ receiptData: Data) throws -> UnsafeMutablePointer<PKCS7> {
        let receiptBIO = BIO_new(BIO_s_mem())
        BIO_write(receiptBIO, (receiptData as NSData).bytes, Int32(receiptData.count))
        
        guard let receiptPKCS7Container = d2i_PKCS7_bio(receiptBIO, nil) else {
            throw ReceiptValidationError.emptyReceiptContents
        }
        
//        let pkcs7DataTypeCode = OBJ_obj2nid(pkcs7_d_sign(receiptPKCS7Container).pointee.contents.pointee.type)
        let dSign = receiptPKCS7Container.pointee.d.sign // это тоже самое что было в функции pkcs7_d_sign(receiptPKCS7Container) -> return ptr->d.sign;
        let pkcs7DataTypeCode = OBJ_obj2nid(dSign?.pointee.contents.pointee.type)
        
        guard pkcs7DataTypeCode == NID_pkcs7_data else {
            throw ReceiptValidationError.emptyReceiptContents
        }
        
        return receiptPKCS7Container
    }
}

struct ReceiptSignatureValidator {
    func checkSignaturePresence(_ PKCS7Container: UnsafeMutablePointer<PKCS7>) throws {
        let pkcs7SignedTypeCode = OBJ_obj2nid(PKCS7Container.pointee.type)
        
        guard pkcs7SignedTypeCode == NID_pkcs7_signed else {
            throw ReceiptValidationError.receiptNotSigned
        }
    }
    
    func checkSignatureAuthenticity(_ PKCS7Container: UnsafeMutablePointer<PKCS7>) throws {
        let appleRootCertificateX509 = try loadAppleRootCertificate()
        
        try verifyAuthenticity(appleRootCertificateX509, PKCS7Container: PKCS7Container)
    }
    
    fileprivate func loadAppleRootCertificate() throws -> UnsafeMutablePointer<X509> {
        guard
            let appleRootCertificateURL = Bundle.main.url(forResource: "AppleIncRootCertificate", withExtension: "cer"),
            let appleRootCertificateData = try? Data(contentsOf: appleRootCertificateURL)
            else {
                throw ReceiptValidationError.appleRootCertificateNotFound
        }
        
        let appleRootCertificateBIO = BIO_new(BIO_s_mem())
        BIO_write(appleRootCertificateBIO, (appleRootCertificateData as NSData).bytes, Int32(appleRootCertificateData.count))
        let appleRootCertificateX509 = d2i_X509_bio(appleRootCertificateBIO, nil)
        
        return appleRootCertificateX509!
    }
    
    fileprivate func verifyAuthenticity(_ x509Certificate: UnsafeMutablePointer<X509>, PKCS7Container: UnsafeMutablePointer<PKCS7>) throws {
        let x509CertificateStore = X509_STORE_new()
        X509_STORE_add_cert(x509CertificateStore, x509Certificate)
        
        OpenSSL_add_all_digests()
        
        let result = PKCS7_verify(PKCS7Container, nil, x509CertificateStore, nil, nil, 0)
        
        if result != 1 {
            throw ReceiptValidationError.receiptSignatureInvalid
        }
    }
}

struct ReceiptParser {
    func parse(_ PKCS7Container: UnsafeMutablePointer<PKCS7>) throws -> ParsedReceipt {
        var bundleIdentifier: String?
        var bundleIdData: NSData?
        var appVersion: String?
        var opaqueValue: NSData?
        var sha1Hash: NSData?
        var inAppPurchaseReceipts = [ParsedInAppPurchaseReceipt]()
        var originalAppVersion: String?
        var receiptCreationDate: Date?
        var expirationDate: Date?
        
        guard let contents = PKCS7Container.pointee.d.sign.pointee.contents, let octets = contents.pointee.d.data else {
            throw ReceiptValidationError.malformedReceipt
        }
        
        var currentASN1PayloadLocation = UnsafePointer(octets.pointee.data)
        let endOfPayload = currentASN1PayloadLocation!.advanced(by: Int(octets.pointee.length))
        
        var type = Int32(0)
        var xclass = Int32(0)
        var length = 0
        
        ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass,Int(octets.pointee.length))
        
        // Payload must be an ASN1 Set
        guard type == V_ASN1_SET else {
            throw ReceiptValidationError.malformedReceipt
        }
        
        // Decode Payload
        // Step through payload (ASN1 Set) and parse each ASN1 Sequence within (ASN1 Sets contain one or more ASN1 Sequences)
        while currentASN1PayloadLocation! < endOfPayload {
            
            // Get next ASN1 Sequence
            ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, currentASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Object type must be an ASN1 Sequence
            guard type == V_ASN1_SEQUENCE else {
                throw ReceiptValidationError.malformedReceipt
            }
            
            // Attribute type of ASN1 Sequence must be an Integer
            guard let attributeType = DecodeASN1Integer(startOfInt: &currentASN1PayloadLocation, length: currentASN1PayloadLocation!.distance(to: endOfPayload)) else {
                throw ReceiptValidationError.malformedReceipt
            }
            
            // Attribute version of ASN1 Sequence must be an Integer
            guard DecodeASN1Integer(startOfInt: &currentASN1PayloadLocation, length: currentASN1PayloadLocation!.distance(to: endOfPayload)) != nil else {
                throw ReceiptValidationError.malformedReceipt
            }
            
            // Get ASN1 Sequence value
            ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, currentASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Sequence value must be an ASN1 Octet String
            guard type == V_ASN1_OCTET_STRING else {
                throw ReceiptValidationError.malformedReceipt
            }
            
            // Decode attributes
            switch attributeType {
            case 2:
                var startOfBundleId = currentASN1PayloadLocation
                bundleIdData = NSData(bytes: startOfBundleId, length: length)
                bundleIdentifier = DecodeASN1String(startOfString: &startOfBundleId, length: length)
            case 3:
                var startOfAppVersion = currentASN1PayloadLocation
                appVersion = DecodeASN1String(startOfString: &startOfAppVersion, length: length)
            case 4:
                let startOfOpaqueValue = currentASN1PayloadLocation
                opaqueValue = NSData(bytes: startOfOpaqueValue, length: length)
            case 5:
                let startOfSha1Hash = currentASN1PayloadLocation
                sha1Hash = NSData(bytes: startOfSha1Hash, length: length)
            case 17:
                var startOfInAppPurchaseReceipt = currentASN1PayloadLocation
                let iapReceipt = try parseInAppPurchaseReceipt(currentInAppPurchaseASN1PayloadLocation: &startOfInAppPurchaseReceipt, payloadLength: length)
                inAppPurchaseReceipts.append(iapReceipt)
            case 12:
                var startOfReceiptCreationDate = currentASN1PayloadLocation
                receiptCreationDate = DecodeASN1Date(startOfDate: &startOfReceiptCreationDate, length: length)
            case 19:
                var startOfOriginalAppVersion = currentASN1PayloadLocation
                originalAppVersion = DecodeASN1String(startOfString: &startOfOriginalAppVersion, length: length)
            case 21:
                var startOfExpirationDate = currentASN1PayloadLocation
                expirationDate = DecodeASN1Date(startOfDate: &startOfExpirationDate, length: length)
            default:
                break
            }
            
            currentASN1PayloadLocation = currentASN1PayloadLocation?.advanced(by: length)
        }
        
        return ParsedReceipt(bundleIdentifier: bundleIdentifier,
                             bundleIdData: bundleIdData,
                             appVersion: appVersion,
                             opaqueValue: opaqueValue,
                             sha1Hash: sha1Hash,
                             inAppPurchaseReceipts: inAppPurchaseReceipts,
                             originalAppVersion: originalAppVersion,
                             receiptCreationDate: receiptCreationDate,
                             expirationDate: expirationDate)
    }
    
    func parseInAppPurchaseReceipt(currentInAppPurchaseASN1PayloadLocation: inout UnsafePointer<UInt8>?, payloadLength: Int) throws -> ParsedInAppPurchaseReceipt {
        var quantity: Int?
        var productIdentifier: String?
        var transactionIdentifier: String?
        var originalTransactionIdentifier: String?
        var purchaseDate: Date?
        var originalPurchaseDate: Date?
        var subscriptionExpirationDate: Date?
        var subscriptionIntroductoryPricePeriod: Bool?
        var cancellationDate: Date?
        var webOrderLineItemId: Int?
        
        let endOfPayload = currentInAppPurchaseASN1PayloadLocation!.advanced(by: payloadLength)
        var type = Int32(0)
        var xclass = Int32(0)
        var length = 0
        
        ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, payloadLength)
        
        // Payload must be an ASN1 Set
        guard type == V_ASN1_SET else {
            throw ReceiptValidationError.malformedInAppPurchaseReceipt
        }
        
        // Decode Payload
        // Step through payload (ASN1 Set) and parse each ASN1 Sequence within (ASN1 Sets contain one or more ASN1 Sequences)
        while currentInAppPurchaseASN1PayloadLocation! < endOfPayload {
            
            // Get next ASN1 Sequence
            ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Object type must be an ASN1 Sequence
            guard type == V_ASN1_SEQUENCE else {
                throw ReceiptValidationError.malformedInAppPurchaseReceipt
            }
            
            // Attribute type of ASN1 Sequence must be an Integer
            guard let attributeType = DecodeASN1Integer(startOfInt: &currentInAppPurchaseASN1PayloadLocation, length: currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload)) else {
                throw ReceiptValidationError.malformedInAppPurchaseReceipt
            }
            
            // Attribute version of ASN1 Sequence must be an Integer
            guard DecodeASN1Integer(startOfInt: &currentInAppPurchaseASN1PayloadLocation, length: currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload)) != nil else {
                throw ReceiptValidationError.malformedInAppPurchaseReceipt
            }
            
            // Get ASN1 Sequence value
            ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Sequence value must be an ASN1 Octet String
            guard type == V_ASN1_OCTET_STRING else {
                throw ReceiptValidationError.malformedInAppPurchaseReceipt
            }
            
            // Decode attributes
            switch attributeType {
            case PurchaseReceiptFields.quantity.asn1Type:
                var startOfQuantity = currentInAppPurchaseASN1PayloadLocation
                quantity = DecodeASN1Integer(startOfInt: &startOfQuantity , length: length)
            case PurchaseReceiptFields.productIdentifier.asn1Type:
                var startOfProductIdentifier = currentInAppPurchaseASN1PayloadLocation
                productIdentifier = DecodeASN1String(startOfString: &startOfProductIdentifier, length: length)
            case PurchaseReceiptFields.transactionIdentifier.asn1Type:
                var startOfTransactionIdentifier = currentInAppPurchaseASN1PayloadLocation
                transactionIdentifier = DecodeASN1String(startOfString: &startOfTransactionIdentifier, length: length)
            case PurchaseReceiptFields.originalTransactionIdentifier.asn1Type:
                var startOfOriginalTransactionIdentifier = currentInAppPurchaseASN1PayloadLocation
                originalTransactionIdentifier = DecodeASN1String(startOfString: &startOfOriginalTransactionIdentifier, length: length)
            case PurchaseReceiptFields.purchaseDate.asn1Type:
                var startOfPurchaseDate = currentInAppPurchaseASN1PayloadLocation
                purchaseDate = DecodeASN1Date(startOfDate: &startOfPurchaseDate, length: length)
            case PurchaseReceiptFields.originalPurchaseDate.asn1Type:
                var startOfOriginalPurchaseDate = currentInAppPurchaseASN1PayloadLocation
                originalPurchaseDate = DecodeASN1Date(startOfDate: &startOfOriginalPurchaseDate, length: length)
            case PurchaseReceiptFields.subscriptionExpirationDate.asn1Type:
                var startOfSubscriptionExpirationDate = currentInAppPurchaseASN1PayloadLocation
                subscriptionExpirationDate = DecodeASN1Date(startOfDate: &startOfSubscriptionExpirationDate, length: length)
            case PurchaseReceiptFields.subscriptionIntroductoryPricePeriod.asn1Type: // TODO
                var startOfSubscriptionIntroductoryPricePeriod = currentInAppPurchaseASN1PayloadLocation
                let intValue = DecodeASN1Integer(startOfInt: &startOfSubscriptionIntroductoryPricePeriod, length: length)
                subscriptionIntroductoryPricePeriod = intValue == 1 ? true : false
            case PurchaseReceiptFields.cancellationDate.asn1Type:
                var startOfCancellationDate = currentInAppPurchaseASN1PayloadLocation
                cancellationDate = DecodeASN1Date(startOfDate: &startOfCancellationDate, length: length)
            case PurchaseReceiptFields.webOrderLineItemId.asn1Type:
                var startOfWebOrderLineItemId = currentInAppPurchaseASN1PayloadLocation
                webOrderLineItemId = DecodeASN1Integer(startOfInt: &startOfWebOrderLineItemId, length: length)
            default:
                break
            }
            
            currentInAppPurchaseASN1PayloadLocation = currentInAppPurchaseASN1PayloadLocation!.advanced(by: length)
        }
        
        return ParsedInAppPurchaseReceipt(quantity: quantity,
                                          productIdentifier: productIdentifier,
                                          transactionIdentifier: transactionIdentifier,
                                          originalTransactionIdentifier: originalTransactionIdentifier,
                                          purchaseDate: purchaseDate,
                                          originalPurchaseDate: originalPurchaseDate,
                                          subscriptionExpirationDate: subscriptionExpirationDate,
                                          subscriptionIntroductoryPricePeriod: subscriptionIntroductoryPricePeriod,
                                          cancellationDate: cancellationDate,
                                          webOrderLineItemId: webOrderLineItemId)
    }
    
    func DecodeASN1Integer(startOfInt intPointer: inout UnsafePointer<UInt8>?, length: Int) -> Int? {
        // These will be set by ASN1_get_object
        var type = Int32(0)
        var xclass = Int32(0)
        var intLength = 0
        
        ASN1_get_object(&intPointer, &intLength, &type, &xclass, length)
        
        guard type == V_ASN1_INTEGER else {
            return nil
        }
        
        let integer = c2i_ASN1_INTEGER(nil, &intPointer, intLength)
        let result = ASN1_INTEGER_get(integer)
        ASN1_INTEGER_free(integer)
        
        return result
    }
    
    func DecodeASN1String(startOfString stringPointer: inout UnsafePointer<UInt8>?, length: Int) -> String? {
        // These will be set by ASN1_get_object
        var type = Int32(0)
        var xclass = Int32(0)
        var stringLength = 0
        
        ASN1_get_object(&stringPointer, &stringLength, &type, &xclass, length)
        
        if type == V_ASN1_UTF8STRING {
            let mutableStringPointer = UnsafeMutableRawPointer(mutating: stringPointer!)
            return String(bytesNoCopy: mutableStringPointer, length: stringLength, encoding: String.Encoding.utf8, freeWhenDone: false)
        }
        
        if type == V_ASN1_IA5STRING {
            let mutableStringPointer = UnsafeMutableRawPointer(mutating: stringPointer!)
            return String(bytesNoCopy: mutableStringPointer, length: stringLength, encoding: String.Encoding.ascii, freeWhenDone: false)
        }
        
        return nil
    }
    
    func DecodeASN1Date(startOfDate datePointer: inout UnsafePointer<UInt8>?, length: Int) -> Date? {
        // Date formatter code from https://www.objc.io/issues/17-security/receipt-validation/#parsing-the-receipt
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let dateString = DecodeASN1String(startOfString: &datePointer, length:length) {
            return dateFormatter.date(from: dateString)
        }
        
        return nil
    }
}

/// Refer to https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
/// "In-App Purchase Receipt Fields" section.
struct PurchaseReceiptFields {
    
    /// The number of items purchased.
    ///
    /// This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property.
    static let quantity = ReceiptField(asn1Type: 1701, codingKey: .quantity)
    
    /// The number of items purchased.
    ///
    /// This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
    static let productIdentifier = ReceiptField(asn1Type: 1702, codingKey: .productId)

    /// The transaction identifier of the item that was purchased.
    ///
    /// This value corresponds to the transaction’s transactionIdentifier property.
    static let transactionIdentifier = ReceiptField(asn1Type: 1703, codingKey: .transactionId)
    
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    ///
    /// This value corresponds to the original transaction’s transactionIdentifier property.
    static let originalTransactionIdentifier = ReceiptField(asn1Type: 1705, codingKey: .originalTransactionId)
    
    /// The date and time that the item was purchased.
    ///
    /// This value corresponds to the transaction’s transactionDate property.
    static let purchaseDate = ReceiptField(asn1Type: 1704, codingKey: .purchaseDate)
    
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    ///
    /// This value corresponds to the original transaction’s transactionDate property.
    static let originalPurchaseDate = ReceiptField(asn1Type: 1706, codingKey: .originaPurchaseDate)

    /// The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT.
    ///
    /// This key is only present for auto-renewable subscription receipts. Use this value to identify the date when the subscription will renew or expire,
    /// to determine if a customer should have access to content or service. After validating the latest receipt,
    /// if the subscription expiration date for the latest renewal transaction is a past date, it is safe to assume that the subscription has expired.
    static let subscriptionExpirationDate = ReceiptField(asn1Type: 1708, codingKey: .expiresDate)

    /// For an expired subscription, the reason for the subscription expiration.
    ///
    /// This key is only present for a receipt containing an expired auto-renewable subscription. You can use this value to decide whether to display appropriate messaging in your app for customers to resubscribe.
    static let subscriptionExpirationIntent = ReceiptField(asn1Type: nil, codingKey: .subscriptionExpirationIntent)

    /// For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts. If the customer’s subscription failed to renew because the App Store was unable to complete the transaction,
    /// this value will reflect whether or not the App Store is still trying to renew the subscription.
    static let subscriptionRetryFlag = ReceiptField(asn1Type: nil, codingKey: .subscriptionRetryFlag)

    /// For a subscription, whether or not it is in the free trial period.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in the free trial period, or "false" if not.
    static let subscriptionTrialPeriod = ReceiptField(asn1Type: nil, codingKey: .isTrialPeriod)

    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in an introductory price period, or "false" if not.
    static let subscriptionIntroductoryPricePeriod = ReceiptField(asn1Type: 1719, codingKey: .isInIntroOfferPeriod)

    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    ///
    /// Treat a canceled receipt the same as if no purchase had ever been made.
    static let cancellationDate = ReceiptField(asn1Type: 1712, codingKey: .cancellationDate)

    /// For a transaction that was canceled, the reason for cancellation.
    ///
    /// Use this value along with the cancellation date to identify possible issues in your app that may lead customers to contact Apple customer support.
    static let cancellationReason = ReceiptField(asn1Type: nil, codingKey: .cancellationReason)

    /// A string that the App Store uses to uniquely identify the application that created the transaction.
    ///
    /// If your server supports multiple applications, you can use this value to differentiate between them.
    /// Apps are assigned an identifier only in the production environment, so this key is not present for receipts created in the test environment.
    static let appItemId = ReceiptField(asn1Type: nil, codingKey: .appItemId)

    /// An arbitrary number that uniquely identifies a revision of your application.
    ///
    /// This key is not present for receipts created in the test environment. Use this value to identify the version of the app that the customer bought.
    static let externalVersionIdentifier = ReceiptField(asn1Type: nil, codingKey: .externalVersionIdentifier)

    /// The primary key for identifying subscription purchases.
    ///
    /// This value is a unique ID that identifies purchase events across devices, including subscription renewal purchase events.
    static let webOrderLineItemId = ReceiptField(asn1Type: 1711, codingKey: .webOrderLineItemId)

    /// The current renewal status for the auto-renewable subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts, for active or expired subscriptions. The value for this key should not be interpreted as the customer’s subscription status.
    /// You can use this value to display an alternative subscription product in your app, for example, a lower level subscription plan that the customer can downgrade to from their current plan.
    static let subscriptionAutoRenewStatus = ReceiptField(asn1Type: nil, codingKey: .subscriptionAutoRenewStatus)

    /// The current renewal preference for the auto-renewable subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key corresponds to the productIdentifier property of the product that the customer’s subscription renews.
    /// You can use this value to present an alternative service level to the customer before the current subscription period ends.
    static let subscriptionAutoRenewPreference = ReceiptField(asn1Type: nil, codingKey: .subscriptionAutoRenewPreference)

    /// The current price consent status for a subscription price increase.
    ///
    /// This key is only present for auto-renewable subscription receipts if the subscription price was increased without keeping the existing price for active subscribers.
    /// You can use this value to track customer adoption of the new price and take appropriate action.
    static let subscriptionPriceConsentStatus = ReceiptField(asn1Type: nil, codingKey: .subscriptionPriceConsentStatus)
}

struct ReceiptField {
    
    let asn1Type: Int?
    let jsonKey: String
    
    init(asn1Type: Int?, codingKey: InAppPurchase.CodingKeys) {
        self.asn1Type = asn1Type
        self.jsonKey = codingKey.rawValue
    }
    
    init(asn1Type: Int?, jsonKey: String) {
        self.asn1Type = asn1Type
        self.jsonKey = jsonKey
    }
}
