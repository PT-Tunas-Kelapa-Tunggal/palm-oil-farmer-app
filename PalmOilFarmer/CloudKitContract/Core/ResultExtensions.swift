import Foundation

extension Result {
    /// Returns the success value or a caller-chosen fallback.
    public func or(_ fallback: Success) -> Success {
        (try? get()) ?? fallback
    }

    /// Returns the success value or `nil` on failure.
    public var orNil: Success? {
        try? get()
    }
}

