//
//  DelegatesContainer.swift
//  PurchaseController
//
//  Created by Igor Kulik on 7/3/19.
//

import Foundation

/// Use this class when a class has multiple delegates of the same type.
final class DelegatesContainer<T: AnyObject> {
    
    // MARK: - Properties
    
    let delegates: NSHashTable<T> = NSHashTable<T>.weakObjects()
    
    // MARK: - Public methods
    
    func add(delegate: T) {
        delegates.add(delegate)
    }
    
    func remove(delegate: T) {
        delegates.remove(delegate)
    }
    
    func invokeDelegates(_ invocation: (T) -> Void) {
        for delegate in delegates.allObjects {
            invocation(delegate)
        }
    }
    
    func contains(delegate: T) -> Bool {
        return delegates.contains(delegate)
    }
}



final class WeakBox<A: AnyObject> {
    weak var unbox: A?
    init(_ value: A) {
        unbox = value
    }
}

struct WeakArray<Element: AnyObject> {
    private var items: [WeakBox<Element>] = []
    
    init(_ elements: [Element]) {
        items = elements.map { WeakBox($0) }
    }
}

