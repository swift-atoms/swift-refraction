extension Refraction {
    /// A thick lens: a medium between two spherical surfaces on one axis, in a surrounding medium.
    ///
    /// A radius is positive where the surface's centre lies beyond it in the direction light travels and
    /// negative where it lies before it, so a lens that bulges on both sides has a positive front and a
    /// negative back radius. An infinite radius is a flat surface.
    public struct Lens<Scalar: BinaryFloatingPoint> {
        /// The index of the lens's medium.
        public var index: Refraction.Index<Scalar>

        /// The radius of the surface light meets first.
        public var front: Scalar

        /// The radius of the surface light leaves by.
        public var back: Scalar

        /// The distance between the two surfaces on the axis.
        public var thickness: Scalar

        /// The index of the medium around the lens.
        public var surroundings: Refraction.Index<Scalar>

        /// The lens of index `index` with surfaces of radii `front` and `back`, `thickness` apart on the
        /// axis, in a medium of index `surroundings`.
        @inlinable
        public init(
            index: Refraction.Index<Scalar>,
            front: Scalar,
            back: Scalar,
            thickness: Scalar,
            surroundings: Refraction.Index<Scalar> = .vacuum
        ) {
            self.index = index
            self.front = front
            self.back = back
            self.thickness = thickness
            self.surroundings = surroundings
        }
    }
}

extension Refraction.Lens {
    /// One over the effective focal length, by the lensmaker's equation for a thick lens:
    /// `(n − 1)(1 / R₁ − 1 / R₂ + (n − 1) d / (n R₁ R₂))`, with `n` the lens's index over the
    /// surroundings'. Positive for a converging lens, negative for a diverging one, 0 for none.
    @inlinable
    public var power: Scalar {
        let n = index.value / surroundings.value
        return (n - 1) * (1 / front - 1 / back + (n - 1) * thickness / (n * front * back))
    }

    /// The effective focal length: the distance from each principal plane to its focal point.
    @inlinable
    public var focalLength: Scalar { 1 / power }
}

extension Refraction.Lens: Sendable where Scalar: Sendable {}

extension Refraction.Lens: Equatable {}

extension Refraction.Lens: Hashable {}
