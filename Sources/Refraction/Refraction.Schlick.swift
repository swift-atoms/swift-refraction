extension Refraction {
    /// Schlick's approximation of the share of unpolarised light a boundary reflects:
    /// `R₀ + (1 − R₀)(1 − cos θ)⁵`, with `R₀` the share head-on. It is exact head-on and at a grazing
    /// angle and cheaper than `Refraction.Interface.reflectance(cosine:)` between; where light comes
    /// from the denser side the cosine is that of the transmitted angle, and beyond the critical angle
    /// it is 1. Between vacuum and an index of 1.5, either way, it is within four hundredths of Fresnel's
    /// equations; it is poorest near a grazing angle between close indices, and between equal ones it
    /// still rises to 1 at a grazing angle, where Fresnel's equations give 0.
    public struct Schlick<Scalar: BinaryFloatingPoint> {
        /// The boundary approximated.
        public var interface: Refraction.Interface<Scalar>

        /// Schlick's approximation for `interface`.
        @inlinable
        public init(_ interface: Refraction.Interface<Scalar>) {
            self.interface = interface
        }
    }
}

extension Refraction.Schlick {
    /// The share reflected head-on, `((n₁ − n₂) / (n₁ + n₂))²`.
    @inlinable
    public var normal: Scalar {
        let incident = interface.incident.value
        let transmitted = interface.transmitted.value
        let root = (incident - transmitted) / (incident + transmitted)
        return root * root
    }

    /// The approximate share reflected for light meeting the boundary at an angle whose cosine to the
    /// normal is `cosine`, held to 0 through 1.
    @inlinable
    public func reflectance(cosine: Scalar) -> Scalar {
        var c = Swift.min(Swift.max(cosine, 0), 1)
        if interface.incident > interface.transmitted {
            let ratio = interface.ratio
            let square = 1 - ratio * ratio * (1 - c * c)
            guard square >= 0 else { return 1 }
            c = square.squareRoot()
        }
        let r = normal
        let m = 1 - c
        return r + (1 - r) * m * m * m * m * m
    }
}

extension Refraction.Schlick: Sendable where Scalar: Sendable {}

extension Refraction.Schlick: Equatable {}

extension Refraction.Schlick: Hashable {}
