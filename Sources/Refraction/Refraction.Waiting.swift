extension Refraction {
    /// Where sixteen rays wait to be followed.
    public protocol Waiting {
        associatedtype Scalar: BinaryFloatingPoint
        init()
        subscript(index: Int32) -> Refraction.Trace<Scalar>.Ray { get set }
    }
}
