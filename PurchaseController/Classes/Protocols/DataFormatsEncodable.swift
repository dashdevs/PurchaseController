//
//  DataFormatsEncodable.swift
//  PurchaseController
//
//  Created by Igor Kulik on 6/24/19.
//

import Foundation

protocol DataFormatsEncodable: Encodable {
    func asJsonObject() throws -> Any
    func asBase64String() throws -> String
}

extension DataFormatsEncodable {
    func asJsonObject() throws -> Any {
        let data = try JSONEncoder.receiptEncoder.encode(self)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
    
    func asBase64String() throws -> String {
        let data = try JSONEncoder.receiptEncoder.encode(self)
        return data.base64EncodedString()
    }
}
