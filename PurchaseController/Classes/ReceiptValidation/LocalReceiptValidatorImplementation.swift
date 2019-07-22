//  LocalReceiptValidatorImplementation.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.

import Foundation
import StoreKit
import openssl

// MARK: - Supporting types

private struct ReceiptValidationData {
    let bundleIdData: NSData
    let opaqueValue: NSData
    let sha1Hash: NSData
}

// MARK: - ReceiptValidatorProtocol
extension LocalReceiptValidatorImplementation: ReceiptValidatorProtocol {
    public func validate(completion: @escaping (ReceiptValidationResult) -> Void) {
        switch validateReceipt() {
        case .success(let receipt):
            completion(.success(receipt: receipt))
        case .error(let error):
            completion(.error(error: error))
        }
    }
}

/// Validates receipt locally.
/// /// Local validation requires code to read and validate a PKCS #7 signature, and code to parse and validate the signed payload.
/// - important: Perform receipt validation immediately after your app is launched, before displaying any user interface or spawning any child processes.
/// Implement this check in the main function, before the NSApplicationMain function is called. For additional security, you may repeat this check periodically while your application is running.
///
/// # See also
/// [Validating Receipts Locally](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html)
public struct LocalReceiptValidatorImplementation {
    
    // MARK: - Properties
    
    private let receiptLoader = ReceiptLoader()
    private let receiptExtractor = ReceiptExtractor()
    private let receiptSignatureValidator = ReceiptSignatureValidator()
    private let receiptParser = ReceiptParser()
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - Private methods
    
    /// Performs a series of defined operations for local receipt validateion.
    ///
    /// - Returns: Validation result.
    fileprivate func validateReceipt() -> ReceiptValidationResult {
        do {
            let receiptData = try receiptLoader.loadReceipt()
            let receiptContainer = try receiptExtractor.extractPKCS7Container(receiptData)
            
            try receiptSignatureValidator.checkSignaturePresence(receiptContainer)
            try receiptSignatureValidator.checkSignatureAuthenticity(receiptContainer)
            
            let parsedReceipt = try receiptParser.parse(receiptContainer)
            try validateHash(receipt: parsedReceipt.0)
            
            return .success(receipt: parsedReceipt.1)
        } catch {
            return .error(error: error)
        }
    }
    
    /// Extracts data with device GUID.
    ///
    /// - Returns: NSData object, containing the device's GUID.
    private func deviceIdentifierData() -> NSData? {
        var deviceIdentifier = UIDevice.current.identifierForVendor?.uuid
        
        let rawDeviceIdentifierPointer = withUnsafePointer(to: &deviceIdentifier, {
            (unsafeDeviceIdentifierPointer: UnsafePointer<uuid_t?>) -> UnsafeRawPointer in
            return UnsafeRawPointer(unsafeDeviceIdentifierPointer)
        })
        
        return NSData(bytes: rawDeviceIdentifierPointer, length: 16)
    }
    
    fileprivate func validateHash(receipt: ReceiptValidationData) throws {
        // Make sure that the ParsedReceipt instances has non-nil values needed for hash comparison
        let receiptOpaqueValueData = receipt.opaqueValue
        let receiptBundleIdData = receipt.bundleIdData
        let receiptHashData = receipt.sha1Hash
        
        guard let deviceIdentifierData = self.deviceIdentifierData() else {
            throw ReceiptError.malformedReceipt
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
        guard computedHashData.isEqual(to: receiptHashData as Data) else { throw ReceiptError.incorrectHash }
    }
}

fileprivate struct ReceiptLoader {
    let receiptUrl = Bundle.main.appStoreReceiptURL
    
    func loadReceipt() throws -> Data {
        if(receiptFound()) {
            let receiptData = try? Data(contentsOf: receiptUrl!)
            if let receiptData = receiptData {
                return receiptData
            }
        }
        
        throw ReceiptError.noReceiptData
    }
    
    func receiptFound() -> Bool {
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

fileprivate struct ReceiptExtractor {
    func extractPKCS7Container(_ receiptData: Data) throws -> UnsafeMutablePointer<PKCS7> {
        let receiptBIO = BIO_new(BIO_s_mem())
        BIO_write(receiptBIO, (receiptData as NSData).bytes, Int32(receiptData.count))
        
        guard let receiptPKCS7Container = d2i_PKCS7_bio(receiptBIO, nil) else {
            throw ReceiptError.emptyReceiptContents
        }
        let dSign = receiptPKCS7Container.pointee.d.sign
        let pkcs7DataTypeCode = OBJ_obj2nid(dSign?.pointee.contents.pointee.type)
        guard pkcs7DataTypeCode == NID_pkcs7_data else {
            throw ReceiptError.emptyReceiptContents
        }
        
        return receiptPKCS7Container
    }
}

fileprivate struct ReceiptSignatureValidator {
    func checkSignaturePresence(_ PKCS7Container: UnsafeMutablePointer<PKCS7>) throws {
        let pkcs7SignedTypeCode = OBJ_obj2nid(PKCS7Container.pointee.type)
        
        guard pkcs7SignedTypeCode == NID_pkcs7_signed else {
            throw ReceiptError.receiptNotSigned
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
                throw ReceiptError.appleRootCertificateNotFound
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
            throw ReceiptError.receiptSignatureInvalid
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
            throw ReceiptError.malformedReceipt
        }
        
        var currentASN1PayloadLocation = UnsafePointer(octets.pointee.data)
        let endOfPayload = currentASN1PayloadLocation!.advanced(by: Int(octets.pointee.length))
        
        var type = Int32(0)
        var xclass = Int32(0)
        var length = 0
        
        ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass,Int(octets.pointee.length))
        
        // Payload must be an ASN1 Set
        guard type == V_ASN1_SET else {
            throw ReceiptError.malformedReceipt
        }
        
        // Decode Payload
        // Step through payload (ASN1 Set) and parse each ASN1 Sequence within (ASN1 Sets contain one or more ASN1 Sequences)
        while currentASN1PayloadLocation! < endOfPayload {
            
            // Get next ASN1 Sequence
            ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, currentASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Object type must be an ASN1 Sequence
            guard type == V_ASN1_SEQUENCE else {
                throw ReceiptError.malformedReceipt
            }
            
            // Attribute type of ASN1 Sequence must be an Integer
            guard let attributeType = DecodeASN1Integer(startOfInt: &currentASN1PayloadLocation, length: currentASN1PayloadLocation!.distance(to: endOfPayload)) else {
                throw ReceiptError.malformedReceipt
            }
            
            // Attribute version of ASN1 Sequence must be an Integer
            guard DecodeASN1Integer(startOfInt: &currentASN1PayloadLocation, length: currentASN1PayloadLocation!.distance(to: endOfPayload)) != nil else {
                throw ReceiptError.malformedReceipt
            }
            
            // Get ASN1 Sequence value
            ASN1_get_object(&currentASN1PayloadLocation, &length, &type, &xclass, currentASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Sequence value must be an ASN1 Octet String
            guard type == V_ASN1_OCTET_STRING else {
                throw ReceiptError.malformedReceipt
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
                throw ReceiptError.incorrectHash
        }
        let validationData = ReceiptValidationData(bundleIdData: bundleId, opaqueValue: opaqueValue, sha1Hash: sha1Hash)

        guard let receipt = Receipt(bundleIdentifier: bundleIdentifier,
                                    appVersion: appVersion,
                                    originalAppVersion: originalAppVersion,
                                    inAppPurchaseReceipts: inAppPurchaseReceipts,
                                    receiptCreationDate: receiptCreationDate,
                                    expirationDate: expirationDate) else {
            throw ReceiptError.malformedReceipt
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
            throw ReceiptError.malformedInAppPurchaseReceipt
        }
        
        // Decode Payload
        // Step through payload (ASN1 Set) and parse each ASN1 Sequence within (ASN1 Sets contain one or more ASN1 Sequences)
        while currentInAppPurchaseASN1PayloadLocation! < endOfPayload {
            
            // Get next ASN1 Sequence
            ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Object type must be an ASN1 Sequence
            guard type == V_ASN1_SEQUENCE else {
                throw ReceiptError.malformedInAppPurchaseReceipt
            }
            
            // Attribute type of ASN1 Sequence must be an Integer
            guard let attributeType = DecodeASN1Integer(startOfInt: &currentInAppPurchaseASN1PayloadLocation, length: currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload)) else {
                throw ReceiptError.malformedInAppPurchaseReceipt
            }
            
            // Attribute version of ASN1 Sequence must be an Integer
            guard DecodeASN1Integer(startOfInt: &currentInAppPurchaseASN1PayloadLocation, length: currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload)) != nil else {
                throw ReceiptError.malformedInAppPurchaseReceipt
            }
            
            // Get ASN1 Sequence value
            ASN1_get_object(&currentInAppPurchaseASN1PayloadLocation, &length, &type, &xclass, currentInAppPurchaseASN1PayloadLocation!.distance(to: endOfPayload))
            
            // ASN1 Sequence value must be an ASN1 Octet String
            guard type == V_ASN1_OCTET_STRING else {
                throw ReceiptError.malformedInAppPurchaseReceipt
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
                                                throw ReceiptError.malformedInAppPurchaseReceipt
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
