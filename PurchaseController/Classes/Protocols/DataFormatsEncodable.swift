//
//  DataFormatsEncodable.swift
//  PurchaseController
//
//  Copyright © 2019 dashdevs.com. All rights reserved.
//

import Foundation

public protocol DataFormatsEncodable: Encodable {
    func asJsonObject() throws -> Any
    func asBase64String() throws -> String
    func asData() throws -> Data
}

public extension DataFormatsEncodable {
    
    func asJsonObject() throws -> Any {
        let data = try JSONEncoder.receiptEncoder.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
    
    func asBase64String() throws -> String {
        let data = try JSONEncoder.receiptEncoder.encode(self)
        return data.base64EncodedString()
    }
    
    func asData() throws -> Data {
        return try JSONEncoder.receiptEncoder.encode(self)
    }
}
