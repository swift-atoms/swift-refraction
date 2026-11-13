extension Refraction {
    /// The wavelength of light in vacuum, held in nanometres: visible light runs from about 380 to
    /// about 750.
    public struct Wavelength<Scalar: BinaryFloatingPoint> {
        /// The wavelength in nanometres.
        public var nanometres: Scalar

        /// The wavelength of `nanometres` nanometres.
        @inlinable
        public init(nanometres: Scalar) {
            self.nanometres = nanometres
        }
    }
}

extension Refraction.Wavelength {
    /// The wavelength of `metres` metres.
    @inlinable
    public init(metres: Scalar) {
        self.init(nanometres: metres * 1_000_000_000)
    }

    /// The wavelength in metres.
    @inlinable
    public var metres: Scalar { nanometres / 1_000_000_000 }
}

extension Refraction.Wavelength {
    /// The Fraunhofer d line of helium, 587.5618 nm, yellow: where an Abbe number's index is taken.
    @inlinable
    public static var d: Self { Self(nanometres: 587.5618) }

    /// The Fraunhofer F line of hydrogen, 486.1327 nm, blue.
    @inlinable
    public static var F: Self { Self(nanometres: 486.1327) }

    /// The Fraunhofer C line of hydrogen, 656.2725 nm, red.
    @inlinable
    public static var C: Self { Self(nanometres: 656.2725) }
}

extension Refraction.Wavelength: Sendable where Scalar: Sendable {}

extension Refraction.Wavelength: Equatable {}

extension Refraction.Wavelength: Hashable {}

extension Refraction.Wavelength: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.nanometres < rhs.nanometres
    }
}
