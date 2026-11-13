extension Refraction {
    /// The boundary light crosses from one medium into another.
    public struct Interface<Scalar: BinaryFloatingPoint> {
        /// The index of the medium the light comes from.
        public var incident: Refraction.Index<Scalar>

        /// The index of the medium the light goes into.
        public var transmitted: Refraction.Index<Scalar>

        /// The boundary light crosses from the medium of index `incident` into that of `transmitted`.
        @inlinable
        public init(from incident: Refraction.Index<Scalar>, into transmitted: Refraction.Index<Scalar>) {
            self.incident = incident
            self.transmitted = transmitted
        }
    }
}

extension Refraction.Interface {
    /// The incident index over the transmitted index: the factor Snell's law scales the sine by.
    @inlinable
    public var ratio: Scalar { incident.value / transmitted.value }

    /// The same boundary crossed the other way.
    @inlinable
    public var reversed: Self { Self(from: transmitted, into: incident) }
}

extension Refraction.Interface {
    /// A unit direction after it meets the boundary, by Snell's law in vector form: `normal` is the
    /// boundary's unit normal on the side the light comes from, against the direction.
    ///
    /// The transmitted direction is `r d + (r c − √(1 − r²(1 − c²))) n`, where `r` is `ratio` and `c`
    /// the cosine between the normal and the reversed direction; it is a unit vector in the plane of
    /// the direction and the normal. Where the root's argument is negative no light crosses, and the
    /// outcome is total internal reflection along the mirrored direction.
    @inlinable
    public func refracted<let N: Int>(
        _ direction: Vector<N, Scalar>,
        at normal: Vector<N, Scalar>
    ) -> Refraction.Outcome<Vector<N, Scalar>> {
        let ratio = ratio
        let cosine = -Refraction.dot(direction, normal)
        let inside = 1 - ratio * ratio * (1 - cosine * cosine)
        guard inside >= 0 else {
            return .totalInternalReflection(Refraction.reflected(direction, at: normal))
        }
        let along = ratio * cosine - inside.squareRoot()
        return .transmitted(Vector(InlineArray { ratio * direction[$0] + along * normal[$0] }))
    }
}

extension Refraction.Interface where Scalar: Trigonometry.Circular {
    /// The angle to the normal after the boundary, for light meeting it at the angle `incidence` to the
    /// normal, by Snell's law: `n₁ sin θ₁ = n₂ sin θ₂`. Where `ratio · sin θ₁` exceeds 1 in size no
    /// light crosses, and the outcome is total internal reflection at the angle of incidence.
    @inlinable
    public func refracted(incidence: Radian<Scalar>) -> Refraction.Outcome<Radian<Scalar>> {
        let sine = ratio * incidence.sin.value
        guard abs(sine) <= 1 else { return .totalInternalReflection(incidence) }
        return .transmitted(Radian<Scalar>.asin(Scale(sine)))
    }

    /// The critical angle: the angle of incidence from which on all light is reflected, `asin(n₂ / n₁)`.
    /// Nil where light goes into a medium of an index at least its own, where every angle crosses.
    @inlinable
    public var critical: Radian<Scalar>? {
        guard incident > transmitted else { return nil }
        return Radian<Scalar>.asin(Scale(transmitted.value / incident.value))
    }
}

extension Refraction.Interface {
    /// The share of unpolarised light the boundary reflects, 0 to 1, for light meeting it at an angle
    /// whose cosine to the normal is `cosine`, held to 0 through 1: the mean of Fresnel's equations for
    /// the two polarisations. Head-on it is `((n₁ − n₂) / (n₁ + n₂))²`, at a grazing angle 1, and beyond
    /// the critical angle 1. Between equal indices there is no boundary, and it is 0 at every angle.
    @inlinable
    public func reflectance(cosine: Scalar) -> Scalar {
        let incident = incident.value
        let transmitted = transmitted.value
        guard incident != transmitted else { return 0 }
        let c = Swift.min(Swift.max(cosine, 0), 1)
        let within = (1 - (1 - c * c) * (incident * incident) / (transmitted * transmitted)).squareRoot()
        let across = (incident * c - transmitted * within) / (incident * c + transmitted * within)
        let along = (transmitted * c - incident * within) / (transmitted * c + incident * within)
        guard across.isFinite, along.isFinite else { return 1 }
        return (across * across + along * along) / 2
    }

    /// The share of unpolarised light that crosses the boundary, 0 to 1, by Fresnel's transmission
    /// coefficients for the two polarisations, each weighted by the ratio of the power flows,
    /// `n₂ cos θ₂ / (n₁ cos θ₁)`. It and `reflectance(cosine:)` add up to 1; it is 0 at a grazing angle
    /// and beyond the critical angle, and 1 at every angle between equal indices.
    @inlinable
    public func transmittance(cosine: Scalar) -> Scalar {
        let incident = incident.value
        let transmitted = transmitted.value
        guard incident != transmitted else { return 1 }
        let c = Swift.min(Swift.max(cosine, 0), 1)
        let square = 1 - (1 - c * c) * (incident * incident) / (transmitted * transmitted)
        guard c > 0, square >= 0 else { return 0 }
        let within = square.squareRoot()
        let across = 2 * incident * c / (incident * c + transmitted * within)
        let along = 2 * incident * c / (transmitted * c + incident * within)
        let flow = (transmitted * within) / (incident * c)
        return flow * (across * across + along * along) / 2
    }
}

extension Refraction.Interface: Sendable where Scalar: Sendable {}

extension Refraction.Interface: Equatable {}

extension Refraction.Interface: Hashable {}
