import Foundation
import ReactiveCocoa

public enum CollectionChange<T> {
    case Remove(Int, T)
    case Insert(Int, T)
    case Composite([CollectionChange])
    
    public func index() -> Int? {
        switch self {
        case .Remove(let index, _): return index
        case .Insert(let index, _): return index
        default: return nil
        }
    }
    
    public func element() -> T? {
        switch self {
        case .Remove(_, let element): return element
        case .Insert(_, let element): return element
        default: return nil
        }
    }
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
            sendNext(_changesObserver, .Composite(newValue.mapWithIndex{CollectionChange.Insert($0, $1)}))
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
        sendNext(_changesObserver, .Remove(0, deletedElement))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }

    public func removeLast() {
        _lock.lock()
        if (_value.count == 0) { return }
        let index = _value.count - 1
        let deletedElement = _value.removeLast()
        sendNext(_changesObserver, .Remove(index, deletedElement))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func removeAll() {
        _lock.lock()
        let copiedValue = _value
        _value.removeAll()
        sendNext(_changesObserver, .Composite(copiedValue.mapWithIndex{CollectionChange.Remove($0, $1)}))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }

    public func removeAtIndex(index: Int) {
        _lock.lock()
        let deletedElement = _value.removeAtIndex(index)
        sendNext(_changesObserver, CollectionChange.Remove(index, deletedElement))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func append(element: T) {
        _lock.lock()
        _value.append(element)
        sendNext(_changesObserver, .Insert(_value.count - 1, element))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func appendContentsOf(elements: [T]) {
        _lock.lock()
        let count = _value.count
        _value.appendContentsOf(elements)
        sendNext(_changesObserver, .Composite(elements.mapWithIndex{CollectionChange.Insert(count + $0, $1)}))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func insert(newElement: T, atIndex index: Int) {
        _lock.lock()
        _value.insert(newElement, atIndex: index)
        sendNext(_changesObserver, .Insert(index, newElement))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
    
    public func replace(subRange: Range<Int>, with elements: [T]) {
        _lock.lock()
        precondition(subRange.startIndex + subRange.count <= _value.count, "Range out of bounds")
        var insertsComposite: [CollectionChange<T>] = []
        var deletesComposite: [CollectionChange<T>] = []
        for (index, element) in elements.enumerate() {
            let replacedElement = _value[subRange.startIndex+index]
            _value.replaceRange(Range<Int>(start: subRange.startIndex+index, end: subRange.startIndex+index+1), with: [element])
            deletesComposite.append(.Remove(subRange.startIndex + index, replacedElement))
            insertsComposite.append(.Insert(subRange.startIndex + index, element))
        }
        sendNext(_changesObserver, .Composite(deletesComposite))
        sendNext(_changesObserver, .Composite(insertsComposite))
        sendNext(_valueObserver, _value)
        _lock.unlock()
    }
}

extension Array {
    
    func mapWithIndex<T>(transform: (Int, Element) -> T) -> [T] {
        var newValues: [T] = []
        for (index, element) in self.enumerate() {
            newValues.append(transform(index, element))
        }
        return newValues
    }
    
}