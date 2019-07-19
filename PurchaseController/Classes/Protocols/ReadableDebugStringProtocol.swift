//
//  ReadableDebugStringProtocol.swift
//  Pods
//
//  Created by Igor Kulik on 6/21/19.
//

import Foundation

public protocol ReadableDebugStringProtocol: CustomDebugStringConvertible {}

extension ReadableDebugStringProtocol {
    public var debugDescription: String {
        var description = "\(type(of: self)):\n\t"
        let mirror = Mirror(reflecting: self)
        mirror.children.forEach({
            if let label = $0.label {
                let childDescription = "\(label): \($0.value)\n"
                description.append(childDescription.replacingOccurrences(of: "\n", with: "\n\t"))
            }
        })
        return description
    }
}
