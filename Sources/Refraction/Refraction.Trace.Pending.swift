extension Refraction.Trace {
    /// Rays that wait to be followed, the last one first. When sixteen wait, one more takes the lightest one's place,
    /// if it carries more.
    @usableFromInline
    internal struct Pending<Kept: Refraction.Waiting> where Kept.Scalar == Scalar {
        @usableFromInline
        internal var rays: Kept
        @usableFromInline
        internal var count: Int32

        @inlinable
        @inline(always)
        internal init() {
            rays = Kept()
            count = 0
        }
    }
}

extension Refraction.Trace.Pending {
    @inlinable
    @inline(always)
    internal mutating func append(_ ray: Refraction.Trace<Scalar>.Ray) {
        guard count == 16 else {
            rays[count] = ray
            count &+= 1
            return
        }
        var lightest: Int32 = 0
        var place: Int32 = 1
        while place < 16 {
            if rays[place].weight < rays[lightest].weight { lightest = place }
            place &+= 1
        }
        if ray.weight > rays[lightest].weight { rays[lightest] = ray }
    }
}
