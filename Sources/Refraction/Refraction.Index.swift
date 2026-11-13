extension Refraction {
    /// The refractive index of a medium: how many times slower light travels through it than through
    /// vacuum, so vacuum's is 1, air's about 1.0003, water's 1.33 and window glass's about 1.5.
    ///
    /// An index is a positive number; nothing here checks it. A medium's index varies with the
    /// wavelength (see `Refraction.Cauchy`): an index alone is the index at one wavelength.
    public struct Index<Scalar: BinaryFloatingPoint> {
        /// The ratio of the speed of light in vacuum to its speed in the medium.
        public var value: Scalar

        /// The index whose value is `value`.
        @inlinable
        public init(_ value: Scalar) {
            self.value = value
        }
    }
}

extension Refraction.Index {
    /// The index of vacuum, 1.
    @inlinable
    public static var vacuum: Self { Self(1) }
}

extension Refraction.Index: Sendable where Scalar: Sendable {}

extension Refraction.Index: Equatable {}

extension Refraction.Index: Hashable {}

extension Refraction.Index: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }
}

extension Refraction.Index: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Scalar.FloatLiteralType) {
        self.init(Scalar(floatLiteral: value))
    }
}

extension Refraction.Index: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Scalar.IntegerLiteralType) {
        self.init(Scalar(integerLiteral: value))
    }
}
