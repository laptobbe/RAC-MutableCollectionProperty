//
//  MutableCollectionProperty.swift
//  MutableCollectionProperty
//
//  Created by Pedro Pinera Buendia on 14/10/15.
//  Copyright © 2015 com.gitdo. All rights reserved.
//

import Foundation
import ReactiveCocoa

public enum CollectionChange<T> {
    case StartChange
    case EndChange
    case Insertion
    case Update
    case Addition
    case Deletion(Int,T)
    case Replacement([T])
}

public final class MutableCollectionProperty<T>: PropertyType {

    public typealias Value = [T]

    
    // MARK: - Private attributes

    private let _valueObserver: Signal<Value, NoError>.Observer
    private let _changesObserver: Signal<CollectionChange<Value.Element>, NoError>.Observer
    private var _value: Value
    private let _lock = NSRecursiveLock()

    // MARK: - Public Attributes

    public var producer: SignalProducer<Value, NoError>
    public var changes: SignalProducer<CollectionChange<Value.Element>, NoError>
    public var value: Value {
        get {
            _lock.lock()
            let value = _value
            _lock.unlock()
            return value
        }
        set {
            _lock.lock()
            _value = newValue
            sendNext(_valueObserver, newValue)
            sendNext(_changesObserver, .StartChange)
            sendNext(_changesObserver, .Replacement(_value))
            sendNext(_changesObserver, .EndChange)
            _lock.unlock()
        }
    }

    // MARK: - Init/Deinit

    public init(_ initialValue: Value) {
        _lock.name = "org.reactivecocoa.ReactiveCocoa.MutableCollectionProperty"
        _value = initialValue
        (producer, _valueObserver) = SignalProducer<Value, NoError>.buffer(1)
        (changes, _changesObserver) = SignalProducer<CollectionChange<Value.Element>, NoError>.buffer(1)
    }

    deinit {
        sendCompleted(_valueObserver)
        sendCompleted(_changesObserver)
    }
    
    
    // MARK: - Public

    public func removeFirst() {
        if (_value.count == 0) { return }
        let deletedElement = _value.removeFirst()
        sendNext(_valueObserver, _value)
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, CollectionChange.Deletion(0, deletedElement))
        sendNext(_changesObserver, .EndChange)
    }

    public func removeLast() {
        if (_value.count == 0) { return }
        let index = _value.count - 1
        let deletedElement = _value.removeLast()
        sendNext(_valueObserver, _value)
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, .Deletion(index, deletedElement))
        sendNext(_changesObserver, .EndChange)
    }

    public func removeAtIndex(index: Int) {
        let deletedElement = _value.removeAtIndex(index)
        sendNext(_valueObserver, _value)
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, CollectionChange.Deletion(index, deletedElement))
        sendNext(_changesObserver, .EndChange)
    }
}