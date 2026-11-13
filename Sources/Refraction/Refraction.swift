/// Light crossing from one medium into another: how much it bends and how much of it the boundary
/// sends back, how a medium's index varies with the wavelength, and what lenses of such a medium do.
///
/// Start from `Refraction.Index` for a medium, `Refraction.Interface` for a boundary between two,
/// `Refraction.Cauchy` for an index that varies with the wavelength, and `Refraction.Lens` and
/// `Refraction.Ball` for lenses.
public enum Refraction {}

extension Refraction {
    /// A direction mirrored by a surface with the unit normal `normal`: the law of reflection, the
    /// angle out equal to the angle in, in the plane of the direction and the normal.
    @inlinable
    public static func reflected<let N: Int, Scalar: BinaryFloatingPoint>(
        _ direction: Vector<N, Scalar>,
        at normal: Vector<N, Scalar>
    ) -> Vector<N, Scalar> {
        let twice = 2 * Self.dot(direction, normal)
        return Vector(InlineArray { direction[$0] - twice * normal[$0] })
    }

    /// The sum of the componentwise products, from the first component on.
    @inlinable
    static func dot<let N: Int, Scalar: BinaryFloatingPoint>(_ a: Vector<N, Scalar>, _ b: Vector<N, Scalar>) -> Scalar {
        guard N > 0 else { return 0 }
        var sum = a[0] * b[0]
        var index = 1
        while index < N {
            sum += a[index] * b[index]
            index += 1
        }
        return sum
    }
}
