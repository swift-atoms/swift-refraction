extension Refraction.Ball {
    /// A ball's focal lengths.
    public struct Focal {
        /// The effective focal length, from the centre: `n r / (2 (n − 1))`, with `n` the ball's index over
        /// the surroundings'. Infinite at an index ratio of 1.
        public let length: Scalar

        /// The back focal length: how far behind the ball's surface its focal point lies, `length − radius`.
        /// It is negative, inside the ball, for an index ratio above 2.
        public let back: Scalar

        @inlinable
        public init(_ ball: Refraction.Ball<Scalar>) {
            let n = ball.index.value / ball.surroundings.value
            self.length = n * ball.radius / (2 * (n - 1))
            self.back = self.length - ball.radius
        }
    }
}

extension Refraction.Ball.Focal: Sendable where Scalar: Sendable {}
