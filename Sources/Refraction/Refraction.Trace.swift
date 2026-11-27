extension Refraction {
    /// The paths of light through a body: at each surface a ray meets, the share Fresnel's equations reflect goes one
    /// way and the rest, by Snell's law, the other, each followed to the next surface in turn.
    public struct Trace<Scalar: BinaryFloatingPoint> {
        /// How many surfaces a ray meets before it is taken as it is.
        public var interfaces: Int32

        /// The least share of the light a ray carries: lighter ones are dropped.
        public var least: Scalar

        /// The least share of a reflected ray that is followed: lighter ones are taken as they are.
        public var branch: Scalar

        /// A trace of rays that carry at least 1/512, branch at 1/16 and meet eight surfaces.
        @inlinable
        public init(interfaces: Int32 = 8, least: Scalar = 1 / 512, branch: Scalar = 1 / 16) {
            self.interfaces = interfaces
            self.least = least
            self.branch = branch
        }
    }
}

extension Refraction.Trace {
    /// Follows a ray that meets a body of an index, at least a vacuum's, at its origin, where the surface has a normal.
    /// `next` gives the surface a ray meets next, and `leaving` takes the rays that meet none.
    @inlinable
    @inline(always)
    public func run(
        entering ray: Refraction.Trace<Scalar>.Ray,
        normal: Vector<3, Scalar>,
        index: Refraction.Index<Scalar>,
        next: (Refraction.Trace<Scalar>.Ray) -> Refraction.Trace<Scalar>.Surface?,
        leaving: (Refraction.Trace<Scalar>.Ray) -> Void
    ) {
        run(entering: ray, normal: normal, index: index, keeping: Refraction.Trace<Scalar>.Rays.self, next: next, leaving: leaving)
    }

    /// `run(entering:normal:index:next:leaving:)` with the rays that wait kept where `Kept` keeps them.
    @inlinable
    @inline(always)
    public func run<Kept: Refraction.Waiting>(
        entering ray: Refraction.Trace<Scalar>.Ray,
        normal: Vector<3, Scalar>,
        index: Refraction.Index<Scalar>,
        keeping: Kept.Type,
        next: (Refraction.Trace<Scalar>.Ray) -> Refraction.Trace<Scalar>.Surface?,
        leaving: (Refraction.Trace<Scalar>.Ray) -> Void
    ) where Kept.Scalar == Scalar {
        let index = Swift.max(index, .vacuum)
        var pending = Refraction.Trace<Scalar>.Pending<Kept>()
        var ray = ray
        var surface = Refraction.Trace<Scalar>.Surface(distance: 0, normal: normal, number: ray.from)
        while true {
            let against = Refraction.dot(ray.direction, surface.normal) > 0 ? surface.normal.scaled(by: -1) : surface.normal
            let cosine = Swift.min(Swift.max(-Refraction.dot(ray.direction, against), 0), 1)
            let interface =
                ray.inside ? Refraction.Interface(from: index, into: .vacuum) : Refraction.Interface(from: .vacuum, into: index)
            let mirrored = interface.reflectance(cosine: cosine)
            let through = ray.weight * (1 - mirrored)
            let kept = ray.weight * mirrored
            var on = ray
            on.length = ray.length + (ray.inside ? surface.distance : 0)
            on.depth = ray.depth + 1
            if through >= least {
                let crossed = interface.refracted(ray.direction, at: against).transmission
                if crossed != nil || !ray.inside {
                    var across = on
                    across.weight = through
                    across.inside = !ray.inside
                    across.direction = crossed ?? ray.direction
                    pending.append(across)
                }
            }
            if kept >= least {
                on.weight = kept
                on.direction = Refraction.reflected(ray.direction, at: against)
                if kept >= branch { pending.append(on) } else { leaving(on) }
            }
            var met = false
            while !met {
                guard pending.count > 0 else { return }
                pending.count &-= 1
                ray = pending.rays[pending.count]
                if ray.depth < interfaces, let found = next(ray) {
                    ray.origin += ray.direction.scaled(by: found.distance)
                    ray.from = found.number
                    surface = found
                    met = true
                } else {
                    leaving(ray)
                }
            }
        }
    }
}
