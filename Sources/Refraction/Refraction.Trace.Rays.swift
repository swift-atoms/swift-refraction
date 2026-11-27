extension Refraction.Trace {
    /// Sixteen rays kept in place.
    public struct Rays: Refraction.Waiting {
        @usableFromInline
        internal var rays: InlineArray<16, Refraction.Trace<Scalar>.Ray>

        @inlinable
        public init() {
            rays = InlineArray(repeating: Refraction.Trace<Scalar>.Ray(origin: .zero, direction: .zero, weight: 0))
        }
    }
}

extension Refraction.Trace.Rays {
    @inlinable
    public subscript(index: Int32) -> Refraction.Trace<Scalar>.Ray {
        get { rays[Int(index)] }
        set { rays[Int(index)] = newValue }
    }
}
