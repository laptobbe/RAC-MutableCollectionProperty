//
//  MutableCollectionProperty.swift
//  MutableCollectionProperty
//
//  Created by Pedro Pinera Buendia on 14/10/15.
//  Copyright © 2015 com.gitdo. All rights reserved.
//

import Foundation
import ReactiveCocoa

enum CollectionChange<T> {
    case Insertion
    case Deletion
    case Update
    case Addition
}

public final class MutableCollectionProperty<T>: PropertyType {
    
    public typealias Value = T
    
    private let _valueObserver: Signal<[Value], NoError>.Observer
    private let _changesObserver: Signal<CollectionChange<Value>, NoError>.Observer
    private var _value: [Value]

    var producer: SignalProducer<[Value], NoError>
    var changes: SignalProducer<CollectionChange<Value>, NoError>
    
    
    public init(_ initialValue: [Value]) {
        _value = initialValue
        (producer, _valueObserver) = SignalProducer<[Value], NoError>.buffer(1)
        (changes, _changesObserver) = SignalProducer<CollectionChange<Value>, NoError>.buffer(1)
    }
    
    deinit {
        sendCompleted(_valueObserver)
        sendCompleted(_changesObserver)
    }
}