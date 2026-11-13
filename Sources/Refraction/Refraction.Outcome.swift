extension Refraction {
    /// What becomes of light that meets a boundary: it crosses, bent, or, beyond the critical angle on
    /// the way out of the denser side, none crosses and all of it is reflected.
    public enum Outcome<Value> {
        /// The light crosses into the other medium along this value.
        case transmitted(Value)

        /// No light crosses: it is all reflected, along this value.
        case totalInternalReflection(Value)
    }
}

extension Refraction.Outcome {
    /// The value the light crosses along, or nil where it is all reflected.
    @inlinable
    public var transmission: Value? {
        guard case .transmitted(let value) = self else { return nil }
        return value
    }

    /// The value the light goes on along, crossed or reflected.
    @inlinable
    public var value: Value {
        switch self {
        case .transmitted(let value), .totalInternalReflection(let value): value
        }
    }
}

extension Refraction.Outcome: Sendable where Value: Sendable {}

extension Refraction.Outcome: Equatable where Value: Equatable {}

extension Refraction.Outcome: Hashable where Value: Hashable {}
