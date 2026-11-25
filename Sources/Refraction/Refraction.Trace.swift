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

    /// Rays that wait to be followed, the last one first. When sixteen wait, one more takes the lightest one's place,
    /// if it carries more.
    @usableFromInline
    internal struct Pending {
        @usableFromInline
        internal var rays: InlineArray<16, Ray>
        @usableFromInline
        internal var count: Int

        @inlinable
        internal init() {
            rays = InlineArray(repeating: Ray(origin: .zero, direction: .zero, weight: 0))
            count = 0
        }
    }
}

extension Refraction.Trace.Pending {
    @inlinable
    internal mutating func append(_ ray: Refraction.Trace<Scalar>.Ray) {
        guard count == 16 else {
            rays[count] = ray
            count += 1
            return
        }
        var lightest = 0
        var place = 1
        while place < 16 {
            if rays[place].weight < rays[lightest].weight { lightest = place }
            place += 1
        }
        if ray.weight > rays[lightest].weight { rays[lightest] = ray }
    }
}

extension Refraction.Trace {
    /// Follows a ray that meets a body of an index, at least a vacuum's, at its origin, where the surface has a normal.
    /// `next` gives the surface a ray meets next, and `leaving` takes the rays that meet none.
    @inlinable
    public func run(
        entering ray: Ray,
        normal: Vector<3, Scalar>,
        index: Refraction.Index<Scalar>,
        next: (Ray) -> Surface?,
        leaving: (Ray) -> Void
    ) {
        let index = Swift.max(index, .vacuum)
        var pending = Pending()
        var ray = ray
        var surface = Surface(distance: 0, normal: normal, number: ray.from)
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
                pending.count -= 1
                ray = pending.rays[pending.count]
                if ray.depth < interfaces, let found = next(ray) {
                    ray.origin = ray.origin + ray.direction.scaled(by: found.distance)
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
