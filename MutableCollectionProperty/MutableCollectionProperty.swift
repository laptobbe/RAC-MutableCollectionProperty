import Foundation
import ReactiveCocoa

public enum CollectionChange<T> {
    case Deletion(Int, T)
    case Replacement([T])
    case Addition(Int, T)
    case Insertion(Int, T)
    case StartChange
    case EndChange
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
            let value = _value
            return value
        }
        set {
            _value = newValue
            sendNext(_valueObserver, newValue)
            sendNext(_changesObserver, .StartChange)
            sendNext(_changesObserver, .Replacement(_value))
            sendNext(_changesObserver, .EndChange)
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
        _lock.lock()
        let deletedElement = _value.removeFirst()
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, CollectionChange.Deletion(0, deletedElement))
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }

    public func removeLast() {
        _lock.lock()
        if (_value.count == 0) { return }
        let index = _value.count - 1
        let deletedElement = _value.removeLast()
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, .Deletion(index, deletedElement))
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func removeAll() {
        _lock.lock()
        sendNext(_changesObserver, .StartChange)
        for i in (0...(_value.count-1)).reverse() {
            let object = _value[i]
            _value.removeAtIndex(i)
            sendNext(_changesObserver, CollectionChange.Deletion(_value.count, object))
        }
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }

    public func removeAtIndex(index: Int) {
        _lock.lock()
        let deletedElement = _value.removeAtIndex(index)
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, CollectionChange.Deletion(index, deletedElement))
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func append(element: T) {
        _lock.lock()
        _value.append(element)
        sendNext(_changesObserver, .StartChange)
        sendNext(_changesObserver, CollectionChange.Addition(_value.count - 1, element))
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func appendContentsOf(elements: [T]) {
        _lock.lock()
        sendNext(_changesObserver, .StartChange)
        for element in elements {
            _value.append(element)
            sendNext(_changesObserver, CollectionChange.Addition(_value.count - 1, element))
        }
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func insert(newElement: T, atIndex index: Int) {
        _lock.lock()
        sendNext(_changesObserver, .StartChange)
        _value.insert(newElement, atIndex: index)
        sendNext(_changesObserver, CollectionChange.Insertion(index, newElement))
        sendNext(_changesObserver, .EndChange)
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
}