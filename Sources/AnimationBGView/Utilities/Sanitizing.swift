import Foundation

extension Double {
    /// The value limited to a range, with non-finite values replaced by a fallback.
    ///
    /// Configuration values come straight from callers and from sliders, so every value that
    /// reaches drawing code passes through here first. No input may produce non-finite geometry.
    func sanitized(in range: ClosedRange<Double>, fallback: Double) -> Double {
        guard isFinite else { return fallback }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
