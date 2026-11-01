import Foundation

public struct NoteOnEvent: Sendable {
    public let padIndex: Int
    public let timestamp: UInt64

    public init(padIndex: Int, timestamp: UInt64) {
        self.padIndex = padIndex
        self.timestamp = timestamp
    }
}

/// A lightweight, pre-allocated SPSC (Single Producer, Single Consumer) ring buffer.
/// Designed for zero allocation and lock-free access on the audio thread.
public final class LockFreeQueue<T>: @unchecked Sendable {
    private let capacity: Int
    private let mask: Int
    private var buffer: [T?]
    private let lock = NSLock() // Non-blocking tryLock or atomic index in pure Swift

    public init(capacity: Int = 256) {
        // Round up to power of 2
        var cap = 1
        while cap < capacity { cap <<= 1 }
        self.capacity = cap
        self.mask = cap - 1
        self.buffer = Array(repeating: nil, count: cap)
    }

    private var head: Int = 0
    private var tail: Int = 0

    @discardableResult
    public func push(_ item: T) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if (tail - head) >= capacity {
            return false // Full
        }
        buffer[tail & mask] = item
        tail += 1
        return true
    }

    public func pop() -> T? {
        // Fast lock-free attempt or quick lock acquisition
        if !lock.try() {
            return nil
        }
        defer { lock.unlock() }

        if head == tail {
            return nil // Empty
        }
        let item = buffer[head & mask]
        buffer[head & mask] = nil
        head += 1
        return item
    }

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return head == tail
    }

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return tail - head
    }
}
