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
    case success(Receipt)
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

private struct ReceiptValidationData {
    let bundleIdData: NSData
    let opaqueValue: NSData
    let sha1Hash: NSData
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
    private let receiptParser = ReceiptParser()
    
    public init() {}
    
    func validateReceipt() -> ReceiptValidationResult {
        do {
            let receiptData = try receiptLoader.loadReceipt()
            let receiptContainer = try receiptExtractor.extractPKCS7Container(receiptData)
            
            try receiptSignatureValidator.checkSignaturePresence(receiptContainer)
            try receiptSignatureValidator.checkSignatureAuthenticity(receiptContainer)
            
            let parsedReceipt = try receiptParser.parse(receiptContainer)
            try validateHash(receipt: parsedReceipt.0)
            
            return .success(parsedReceipt.1)
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
    
    fileprivate func validateHash(receipt: ReceiptValidationData) throws {
        // Make sure that the ParsedReceipt instances has non-nil values needed for hash comparison
        let receiptOpaqueValueData = receipt.opaqueValue
        let receiptBundleIdData = receipt.bundleIdData
        let receiptHashData = receipt.sha1Hash
        
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

fileprivate struct ReceiptParser {
    func parse(_ PKCS7Container: UnsafeMutablePointer<PKCS7>) throws -> (ReceiptValidationData, Receipt) {
        var bundleIdentifier: String?
        var bundleIdData: NSData?
        var appVersion: String?
        var opaqueValueData: NSData?
        var sha1HashData: NSData?
        var inAppPurchaseReceipts = [InAppPurchase]()
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
            case AppReceiptFields.bundleIdentifier.asn1Type:
                var startOfBundleId = currentASN1PayloadLocation
                bundleIdData = NSData(bytes: startOfBundleId, length: length)
                bundleIdentifier = DecodeASN1String(startOfString: &startOfBundleId, length: length)
            case AppReceiptFields.appVersion.asn1Type:
                var startOfAppVersion = currentASN1PayloadLocation
                appVersion = DecodeASN1String(startOfString: &startOfAppVersion, length: length)
            case AppReceiptFields.opaqueValue.asn1Type:
                let startOfOpaqueValue = currentASN1PayloadLocation
                opaqueValueData = NSData(bytes: startOfOpaqueValue, length: length)
            case AppReceiptFields.sha1Hash.asn1Type:
                let startOfSha1Hash = currentASN1PayloadLocation
                sha1HashData = NSData(bytes: startOfSha1Hash, length: length)
            case AppReceiptFields.inAppPurchaseReceipt.asn1Type:
                var startOfInAppPurchaseReceipt = currentASN1PayloadLocation
                let iapReceipt = try parseInAppPurchaseReceipt(currentInAppPurchaseASN1PayloadLocation: &startOfInAppPurchaseReceipt, payloadLength: length)
                inAppPurchaseReceipts.append(iapReceipt)
            case AppReceiptFields.originalApplicationVersion.asn1Type:
                var startOfOriginalAppVersion = currentASN1PayloadLocation
                originalAppVersion = DecodeASN1String(startOfString: &startOfOriginalAppVersion, length: length)
            case AppReceiptFields.receiptCreationDate.asn1Type:
                var startOfReceiptCreationDate = currentASN1PayloadLocation
                receiptCreationDate = DecodeASN1Date(startOfDate: &startOfReceiptCreationDate, length: length)
            case AppReceiptFields.receiptExpirationDate.asn1Type:
                var startOfExpirationDate = currentASN1PayloadLocation
                expirationDate = DecodeASN1Date(startOfDate: &startOfExpirationDate, length: length)
            default:
                break
            }
            
            currentASN1PayloadLocation = currentASN1PayloadLocation?.advanced(by: length)
        }
        
        guard let bundleId = bundleIdData,
            let opaqueValue = opaqueValueData,
            let sha1Hash = sha1HashData else {
                throw ReceiptValidationError.incorrectHash
        }
        let validationData = ReceiptValidationData(bundleIdData: bundleId, opaqueValue: opaqueValue, sha1Hash: sha1Hash)

        guard let receipt = Receipt(bundleIdentifier: bundleIdentifier,
                                    appVersion: appVersion,
                                    originalAppVersion: originalAppVersion,
                                    inAppPurchaseReceipts: inAppPurchaseReceipts,
                                    receiptCreationDate: receiptCreationDate,
                                    expirationDate: expirationDate) else {
            throw ReceiptValidationError.malformedReceipt
        }
        
        
        return (validationData, receipt)
    }
    
    func parseInAppPurchaseReceipt(currentInAppPurchaseASN1PayloadLocation: inout UnsafePointer<UInt8>?, payloadLength: Int) throws -> InAppPurchase {
        var quantity: Int?
        var productIdentifier: String?
        var transactionIdentifier: String?
        var originalTransactionIdentifier: String?
        var purchaseDate: Date?
        var originalPurchaseDate: Date?
        var subscriptionExpirationDate: Date?
        var subscriptionIntroductoryPricePeriod: Bool?
        var cancellationDate: Date?
        var webOrderLineItemId: String?
        
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
            case PurchaseReceiptFields.subscriptionIntroductoryPricePeriod.asn1Type:
                var startOfSubscriptionIntroductoryPricePeriod = currentInAppPurchaseASN1PayloadLocation
                let strValue = DecodeASN1String(startOfString: &startOfSubscriptionIntroductoryPricePeriod, length: length) ?? "false"
                subscriptionIntroductoryPricePeriod = Bool(strValue)
            case PurchaseReceiptFields.cancellationDate.asn1Type:
                var startOfCancellationDate = currentInAppPurchaseASN1PayloadLocation
                cancellationDate = DecodeASN1Date(startOfDate: &startOfCancellationDate, length: length)
            case PurchaseReceiptFields.webOrderLineItemId.asn1Type:
                var startOfWebOrderLineItemId = currentInAppPurchaseASN1PayloadLocation
                webOrderLineItemId = DecodeASN1String(startOfString: &startOfWebOrderLineItemId, length: length)
            default:
                break
            }
            
            currentInAppPurchaseASN1PayloadLocation = currentInAppPurchaseASN1PayloadLocation!.advanced(by: length)
        }
        
        guard let purchase =  InAppPurchase(quantity: quantity,
                                            productIdentifier: productIdentifier,
                                            transactionIdentifier: transactionIdentifier,
                                            originalTransactionIdentifier: originalTransactionIdentifier,
                                            purchaseDate: purchaseDate,
                                            originalPurchaseDate: originalPurchaseDate,
                                            subscriptionExpirationDate: subscriptionExpirationDate,
                                            subscriptionIntroductoryPricePeriod: subscriptionIntroductoryPricePeriod,
                                            cancellationDate: cancellationDate,
                                            webOrderLineItemId: webOrderLineItemId) else {
                                                throw ReceiptValidationError.malformedInAppPurchaseReceipt
        }
        return purchase
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
        if let dateString = DecodeASN1String(startOfString: &datePointer, length:length) {
            return DateFormatter.RFC3339.date(from: dateString)
        }
        return nil
    }
}

/// Refer to https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
/// "App Receipt Fields" section.
struct AppReceiptFields {
    private typealias CodingKeys = Receipt.CodingKeys

    /// The app’s bundle identifier.
    ///
    /// This corresponds to the value of CFBundleIdentifier in the Info.plist file. Use this value to validate if the receipt was indeed generated for your app.
    static let bundleIdentifier = ReceiptField(asn1Type: 2, jsonKey: CodingKeys.bundleId.rawValue)
    
    /// The app’s version number.
    ///
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist.
    static let appVersion = ReceiptField(asn1Type: 3, jsonKey: CodingKeys.applicationVersion.rawValue)

    /// An opaque value used, with other data, to compute the SHA-1 hash during validation.
    static let opaqueValue = ReceiptField(asn1Type: 4, jsonKey: nil)
    
    /// A SHA-1 hash, used to validate the receipt.
    static let sha1Hash = ReceiptField(asn1Type: 5, jsonKey: nil)

    /// The receipt for an in-app purchase.
    ///
    /// In the JSON file, the value of this key is an array containing all in-app purchase receipts based on the in-app purchase transactions present in the input base-64 receipt-data.
    /// For receipts containing auto-renewable subscriptions, check the value of the latest_receipt_info key to get the status of the most recent renewal.
    ///
    /// In the ASN.1 file, there are multiple fields that all have type 17, each of which contains a single in-app purchase receipt.
    ///
    /// Note: An empty array is a valid receipt.
    /// The in-app purchase receipt for a consumable product is added to the receipt when the purchase is made. It is kept in the receipt until your app finishes that transaction.
    /// After that point, it is removed from the receipt the next time the receipt is updated - for example, when the user makes another purchase or if your app explicitly refreshes the receipt.
    static let inAppPurchaseReceipt = ReceiptField(asn1Type: 17, jsonKey: CodingKeys.inApp.rawValue)

    /// The version of the app that was originally purchased.
    ///
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    ///
    /// In the sandbox environment, the value of this field is always “1.0”.
    static let originalApplicationVersion = ReceiptField(asn1Type: 19, jsonKey: CodingKeys.originalApplicationVersion.rawValue)

    /// The date when the app receipt was created.
    ///
    /// When validating a receipt, use this date to validate the receipt’s signature.
    ///
    /// Note: Many cryptographic libraries default to using the device’s current time and date when validating a PKCS7 package, but this may not produce the correct results when validating a receipt’s signature.
    /// For example, if the receipt was signed with a valid certificate, but the certificate has since expired, using the device’s current date incorrectly returns an invalid result.
    ///
    /// Therefore, make sure your app always uses the date from the Receipt Creation Date field to validate the receipt’s signature.
    static let receiptCreationDate = ReceiptField(asn1Type: 12, jsonKey: CodingKeys.receiptCreationDate.rawValue)

    /// The date that the app receipt expires.
    ///
    /// This key is present only for apps purchased through the Volume Purchase Program. If this key is not present, the receipt does not expire.
    ///
    /// When validating a receipt, compare this date to the current date to determine whether the receipt is expired. Do not try to use this date to calculate any other information, such as the time remaining before expiration.
    static let receiptExpirationDate = ReceiptField(asn1Type: 21, jsonKey: CodingKeys.receiptExpirationDate.rawValue)
}

/// Refer to https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
/// "In-App Purchase Receipt Fields" section.
struct PurchaseReceiptFields {
    
    private typealias CodingKeys = InAppPurchase.CodingKeys
    
    /// The number of items purchased.
    ///
    /// This value corresponds to the quantity property of the SKPayment object stored in the transaction’s payment property.
    static let quantity = ReceiptField(asn1Type: 1701, jsonKey: CodingKeys.quantity.rawValue)
    
    /// The number of items purchased.
    ///
    /// This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
    static let productIdentifier = ReceiptField(asn1Type: 1702, jsonKey: CodingKeys.productId.rawValue)

    /// The transaction identifier of the item that was purchased.
    ///
    /// This value corresponds to the transaction’s transactionIdentifier property.
    static let transactionIdentifier = ReceiptField(asn1Type: 1703, jsonKey: CodingKeys.transactionId.rawValue)
    
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    ///
    /// This value corresponds to the original transaction’s transactionIdentifier property.
    static let originalTransactionIdentifier = ReceiptField(asn1Type: 1705, jsonKey: CodingKeys.originalTransactionId.rawValue)
    
    /// The date and time that the item was purchased.
    ///
    /// This value corresponds to the transaction’s transactionDate property.
    static let purchaseDate = ReceiptField(asn1Type: 1704, jsonKey: CodingKeys.purchaseDate.rawValue)
    
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    ///
    /// This value corresponds to the original transaction’s transactionDate property.
    static let originalPurchaseDate = ReceiptField(asn1Type: 1706, jsonKey: CodingKeys.originalPurchaseDate.rawValue)

    /// The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT.
    ///
    /// This key is only present for auto-renewable subscription receipts. Use this value to identify the date when the subscription will renew or expire,
    /// to determine if a customer should have access to content or service. After validating the latest receipt,
    /// if the subscription expiration date for the latest renewal transaction is a past date, it is safe to assume that the subscription has expired.
    static let subscriptionExpirationDate = ReceiptField(asn1Type: 1708, jsonKey: CodingKeys.expiresDate.rawValue)

    /// For an expired subscription, the reason for the subscription expiration.
    ///
    /// This key is only present for a receipt containing an expired auto-renewable subscription. You can use this value to decide whether to display appropriate messaging in your app for customers to resubscribe.
    static let subscriptionExpirationIntent = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionExpirationIntent.rawValue)

    /// For an expired subscription, whether or not Apple is still attempting to automatically renew the subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts. If the customer’s subscription failed to renew because the App Store was unable to complete the transaction,
    /// this value will reflect whether or not the App Store is still trying to renew the subscription.
    static let subscriptionRetryFlag = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionRetryFlag.rawValue)

    /// For a subscription, whether or not it is in the free trial period.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in the free trial period, or "false" if not.
    static let subscriptionTrialPeriod = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.isTrialPeriod.rawValue)

    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key is "true" if the customer’s subscription is currently in an introductory price period, or "false" if not.
    static let subscriptionIntroductoryPricePeriod = ReceiptField(asn1Type: 1719, jsonKey: CodingKeys.isInIntroOfferPeriod.rawValue)

    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    ///
    /// Treat a canceled receipt the same as if no purchase had ever been made.
    static let cancellationDate = ReceiptField(asn1Type: 1712, jsonKey: CodingKeys.cancellationDate.rawValue)

    /// For a transaction that was canceled, the reason for cancellation.
    ///
    /// Use this value along with the cancellation date to identify possible issues in your app that may lead customers to contact Apple customer support.
    static let cancellationReason = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.cancellationReason.rawValue)

    /// A string that the App Store uses to uniquely identify the application that created the transaction.
    ///
    /// If your server supports multiple applications, you can use this value to differentiate between them.
    /// Apps are assigned an identifier only in the production environment, so this key is not present for receipts created in the test environment.
    static let appItemId = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.appItemId.rawValue)

    /// An arbitrary number that uniquely identifies a revision of your application.
    ///
    /// This key is not present for receipts created in the test environment. Use this value to identify the version of the app that the customer bought.
    static let externalVersionIdentifier = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.externalVersionIdentifier.rawValue)

    /// The primary key for identifying subscription purchases.
    ///
    /// This value is a unique ID that identifies purchase events across devices, including subscription renewal purchase events.
    static let webOrderLineItemId = ReceiptField(asn1Type: 1711, jsonKey: CodingKeys.webOrderLineItemId.rawValue)

    /// The current renewal status for the auto-renewable subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts, for active or expired subscriptions. The value for this key should not be interpreted as the customer’s subscription status.
    /// You can use this value to display an alternative subscription product in your app, for example, a lower level subscription plan that the customer can downgrade to from their current plan.
    static let subscriptionAutoRenewStatus = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionAutoRenewStatus.rawValue)

    /// The current renewal preference for the auto-renewable subscription.
    ///
    /// This key is only present for auto-renewable subscription receipts. The value for this key corresponds to the productIdentifier property of the product that the customer’s subscription renews.
    /// You can use this value to present an alternative service level to the customer before the current subscription period ends.
    static let subscriptionAutoRenewPreference = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionAutoRenewPreference.rawValue)

    /// The current price consent status for a subscription price increase.
    ///
    /// This key is only present for auto-renewable subscription receipts if the subscription price was increased without keeping the existing price for active subscribers.
    /// You can use this value to track customer adoption of the new price and take appropriate action.
    static let subscriptionPriceConsentStatus = ReceiptField(asn1Type: nil, jsonKey: CodingKeys.subscriptionPriceConsentStatus.rawValue)
}

struct ReceiptField {
    
    let asn1Type: Int?
    let jsonKey: String?
    
    init(asn1Type: Int?, jsonKey: String?) {
        self.asn1Type = asn1Type
        self.jsonKey = jsonKey
    }
}
