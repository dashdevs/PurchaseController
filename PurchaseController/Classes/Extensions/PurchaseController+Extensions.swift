//
//  PurchaseController+Extensions.swift
//  ReceiptValidationHelper
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

extension Data {
    /// Function used to create readable representation of receipt
    ///
    /// - Returns: readable representation of data
    public func createReceiptValidation() -> ReceiptValidationResponse? {
        do {
            return try self.createReceiptResponse()
        } catch {
            return nil
        }
    }
    
    /// Function used to create receipt object
    ///
    /// - Returns: readable representation of data
    /// - Throws: an error if any value throws an error during decoding
    public func createReceiptResponse() throws -> ReceiptValidationResponse? {
        let response = try JSONDecoder.receiptDecoder.decode(ReceiptValidationResponse.self, from: self)
        return response
    }
}

extension JSONDecoder {
    static let receiptDecoder: JSONDecoder = {
       let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let seconds = TimeInterval(millisecondsString: dateString) {
                return Date(timeIntervalSince1970: seconds)
            }
            
            if let formattedDate = DateFormatter.appleValidator.date(from: dateString) {
                return formattedDate
            }
            
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Cannot decode date string \(dateString)")
        })

    return decoder
    }()
}

extension JSONEncoder {
    static let receiptEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.appleValidator)
        return encoder
    }()
}

extension DateFormatter {
    /** Date formatter code from [objc.io tutorial](https://www.objc.io/issues/17-security/receipt-validation/#parsing-the-receipt)*/
    static let RFC3339: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
    
    static let appleValidator: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
}

extension TimeInterval {
    /** Use to convert TimeInterval to seconds*/
    private struct Constants {
        static let thousand: Double = 1000
    }
    
    init?(millisecondsString: String) {
        guard let milliseconds = TimeInterval(millisecondsString) else {
            return nil
        }
        self = milliseconds / Constants.thousand
    }
}
