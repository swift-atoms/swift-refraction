extension Refraction {
    /// A ball lens: a sphere of one medium in another. Both its principal planes pass through its
    /// centre, so every distance it images from is measured from there.
    public struct Ball<Scalar: BinaryFloatingPoint> {
        /// The index of the ball's medium.
        public var index: Refraction.Index<Scalar>

        /// The ball's radius.
        public var radius: Scalar

        /// The index of the medium around the ball.
        public var surroundings: Refraction.Index<Scalar>

        /// The ball of index `index` and radius `radius` in a medium of index `surroundings`.
        @inlinable
        public init(
            index: Refraction.Index<Scalar>,
            radius: Scalar,
            surroundings: Refraction.Index<Scalar> = .vacuum
        ) {
            self.index = index
            self.radius = radius
            self.surroundings = surroundings
        }
    }
}

extension Refraction.Ball {
    /// The ball as a thick lens: front radius `radius`, back radius `-radius`, `2 · radius` thick.
    @inlinable
    public var lens: Refraction.Lens<Scalar> {
        Refraction.Lens(index: index, front: radius, back: -radius, thickness: 2 * radius, surroundings: surroundings)
    }

    /// The effective focal length, from the centre: `n r / (2 (n − 1))`, with `n` the ball's index over
    /// the surroundings'. Infinite at an index ratio of 1.
    @inlinable
    public var focalLength: Scalar {
        let n = index.value / surroundings.value
        return n * radius / (2 * (n - 1))
    }

    /// The back focal length: how far behind the ball's surface its focal point lies, `focalLength − radius`.
    /// It is negative, inside the ball, for an index ratio above 2.
    @inlinable
    public var backFocalLength: Scalar { focalLength - radius }

    /// The lateral magnification of an object `distance` behind the ball's surface, seen through the ball
    /// from far in front: `f / (f − (r + distance))`. Above 1 is enlarged and upright, as a glass ball held
    /// over a page enlarges it; at the back focal point it is infinite; beyond, negative, turned over. At
    /// contact it is `n / (2 − n)`.
    @inlinable
    public func enlargement(at distance: Scalar) -> Scalar {
        let f = focalLength
        return f / (f - (radius + distance))
    }
}

extension Refraction.Ball: Sendable where Scalar: Sendable {}

extension Refraction.Ball: Equatable {}

extension Refraction.Ball: Hashable {}
