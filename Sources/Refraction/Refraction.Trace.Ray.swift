extension Refraction.Trace {
    /// A ray on its way, or one that has left.
    public struct Ray {
        public var origin: Vector<3, Scalar>
        public var direction: Vector<3, Scalar>
        /// The share of the light it carries.
        public var weight: Scalar
        /// How far the light went within the body.
        public var length: Scalar
        /// How many surfaces it met.
        public var depth: Int32
        /// The surface it left last.
        public var from: Int32
        /// Whether it runs within the body.
        public var inside: Bool

        @inlinable
        public init(
            origin: Vector<3, Scalar>,
            direction: Vector<3, Scalar>,
            weight: Scalar = 1,
            length: Scalar = 0,
            depth: Int32 = 0,
            from: Int32 = -1,
            inside: Bool = false
        ) {
            self.origin = origin
            self.direction = direction
            self.weight = weight
            self.length = length
            self.depth = depth
            self.from = from
            self.inside = inside
        }
    }
}
