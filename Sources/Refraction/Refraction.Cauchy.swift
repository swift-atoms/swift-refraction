extension Refraction {
    /// A medium whose index varies with the wavelength by Cauchy's law, `n(λ) = A + B / λ²`, built from
    /// its index at the d line and its Abbe number, as optical glass is catalogued.
    ///
    /// The Abbe number is `V = (n_d − 1) / (n_F − n_C)`: about 64 for borosilicate crown, 60 for crown
    /// glass, 30 for dense flint and 17 for the most dispersive optical glass. The lower it is, the more
    /// the index falls from blue to red. Cauchy's two terms fit transparent media across the visible
    /// range; they do not hold near an absorption band.
    public struct Cauchy<Scalar: BinaryFloatingPoint> {
        /// The index at the d line, `Refraction.Wavelength.d`.
        public var index: Refraction.Index<Scalar>

        /// The Abbe number. Infinite, or anything not positive, is one index at every wavelength.
        public var abbe: Scalar

        /// The medium of index `index` at the d line and Abbe number `abbe`.
        @inlinable
        public init(index: Refraction.Index<Scalar>, abbe: Scalar = .infinity) {
            self.index = index
            self.abbe = abbe
        }
    }
}

extension Refraction.Cauchy {
    /// Whether the index varies with the wavelength: whether the Abbe number is positive and finite.
    @inlinable
    public var isDispersive: Bool { abbe.isFinite && abbe > 0 }

    /// Cauchy's B in square nanometres: `(n_d − 1) / V / (1 / λ_F² − 1 / λ_C²)`, which makes
    /// `n_F − n_C` equal `(n_d − 1) / V`. 0 without dispersion.
    @inlinable
    public var b: Scalar {
        guard isDispersive else { return 0 }
        let f = Refraction.Wavelength<Scalar>.F.nanometres
        let c = Refraction.Wavelength<Scalar>.C.nanometres
        return (index.value - 1) / abbe / (1 / (f * f) - 1 / (c * c))
    }

    /// Cauchy's A: `n_d − B / λ_d²`, the index the law tends to at long wavelengths.
    @inlinable
    public var a: Scalar {
        let d = Refraction.Wavelength<Scalar>.d.nanometres
        return index.value - b / (d * d)
    }

    /// The index at `wavelength`: exactly `index` at the d line, higher at shorter wavelengths and lower
    /// at longer ones, and `index` at every wavelength without dispersion. A wavelength that is not
    /// positive and finite has `index`.
    @inlinable
    public func index(at wavelength: Refraction.Wavelength<Scalar>) -> Refraction.Index<Scalar> {
        let lambda = wavelength.nanometres
        guard isDispersive, lambda > 0, lambda.isFinite else { return index }
        let d = Refraction.Wavelength<Scalar>.d.nanometres
        return Refraction.Index(index.value + b * (1 / (lambda * lambda) - 1 / (d * d)))
    }
}

extension Refraction.Cauchy: Sendable where Scalar: Sendable {}

extension Refraction.Cauchy: Equatable {}

extension Refraction.Cauchy: Hashable {}
