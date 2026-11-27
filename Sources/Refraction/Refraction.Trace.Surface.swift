extension Refraction.Trace {
    /// A surface a ray meets: how far along it, the unit normal there, on either side, and which surface it is.
    public struct Surface {
        public var distance: Scalar
        public var normal: Vector<3, Scalar>
        public var number: Int32

        @inlinable
        public init(distance: Scalar, normal: Vector<3, Scalar>, number: Int32 = -1) {
            self.distance = distance
            self.normal = normal
            self.number = number
        }
    }
}
