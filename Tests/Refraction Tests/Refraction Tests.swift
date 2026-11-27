import Numeric
import Refraction
import Testing

enum `Refraction Tests` {}

extension `Refraction Tests` {
    typealias Interface = Refraction.Interface<Double>

    static func close(_ a: Double, _ b: Double, within tolerance: Double = 1e-12) -> Bool {
        abs(a - b) <= tolerance
    }

    static func close(_ a: Vector<3, Double>, _ b: Vector<3, Double>, within tolerance: Double = 1e-12) -> Bool {
        close(a[0], b[0], within: tolerance) && close(a[1], b[1], within: tolerance) && close(a[2], b[2], within: tolerance)
    }

    /// The unit direction going down into a surface whose normal is +z, at `angle` to the normal.
    static func incoming(_ angle: Double) -> Vector<3, Double> {
        Vector([Double.sin(angle), 0, -Double.cos(angle)])
    }

    static let up = Vector<3, Double>([0, 0, 1])

    /// Angles of incidence from head-on to nearly grazing.
    static let angles: [Double] = stride(from: 0.0, to: Double.pi / 2, by: Double.pi / 90).map { $0 }

    /// Index pairs light crosses between, both ways round.
    static let interfaces: [Interface] = [
        Interface(from: .vacuum, into: 1.5),
        Interface(from: 1.5, into: .vacuum),
        Interface(from: 1.33, into: 1.52),
        Interface(from: 2.4, into: 1.0003),
        Interface(from: 1, into: 1),
    ]
}

extension `Refraction Tests` {
    @Suite
    struct `Snell's law` {
        @Test
        func `Equal indices bend nothing`() {
            for index in [1.0, 1.33, 1.5, 2.4] {
                let interface = Interface(from: .init(index), into: .init(index))
                for angle in angles {
                    let bent = interface.refracted(incoming(angle), at: up).transmission ?? Vector(repeating: .nan)
                    #expect(`Refraction Tests`.close(bent, incoming(angle)))
                    let incidence = Radian<Double>(_unchecked: angle)
                    #expect(`Refraction Tests`.close(interface.refracted(incidence: incidence).transmission?.underlying ?? .nan, angle))
                }
            }
        }

        @Test
        func `Light meeting the boundary head-on passes straight`() {
            for interface in interfaces {
                #expect(interface.refracted(Vector([0, 0, -1]), at: up) == .transmitted(Vector([0, 0, -1])))
                #expect(interface.refracted(incidence: .zero) == .transmitted(.zero))
            }
        }

        @Test
        func `The sines of the angles are in the inverse ratio of the indices, in both forms`() throws {
            for interface in interfaces {
                for angle in angles {
                    let incident = interface.incident.value
                    let transmitted = interface.transmitted.value
                    guard incident * Double.sin(angle) < transmitted else { continue }
                    let bent = try #require(interface.refracted(incoming(angle), at: up).transmission)
                    #expect(`Refraction Tests`.close(bent[0] * bent[0] + bent[1] * bent[1] + bent[2] * bent[2], 1))
                    #expect(bent[1] == 0 && bent[2] < 0)
                    #expect(`Refraction Tests`.close(incident * Double.sin(angle), transmitted * bent[0]))
                    let theta = try #require(interface.refracted(incidence: Radian(_unchecked: angle)).transmission)
                    #expect(`Refraction Tests`.close(incident * Double.sin(angle), transmitted * Double.sin(theta.underlying)))
                    #expect(`Refraction Tests`.close(Double.sin(theta.underlying), bent[0]))
                }
            }
        }

        @Test
        func `Light crossing back the other way leaves in the direction it came`() throws {
            let interface = Interface(from: .vacuum, into: 1.5)
            for angle in angles {
                let inside = try #require(interface.refracted(incoming(angle), at: up).transmission)
                let outside = try #require(interface.reversed.refracted(inside, at: up).transmission)
                #expect(`Refraction Tests`.close(outside, incoming(angle)))
            }
        }

        @Test
        func `Beyond the critical angle the outcome is total internal reflection`() throws {
            let interface = Interface(from: 1.5, into: .vacuum)
            let critical = try #require(interface.critical).underlying
            #expect(`Refraction Tests`.close(Double.sin(critical), 1 / 1.5))
            #expect(Interface(from: .vacuum, into: 1.5).critical == nil)
            #expect(Interface(from: 1.5, into: 1.5).critical == nil)
            for angle in angles {
                let vector = interface.refracted(incoming(angle), at: up)
                let scalar = interface.refracted(incidence: Radian(_unchecked: angle))
                if angle > critical + 1e-9 {
                    #expect(vector == .totalInternalReflection(Refraction.reflected(incoming(angle), at: up)))
                    #expect(scalar == .totalInternalReflection(Radian(_unchecked: angle)))
                    #expect(vector.transmission == nil)
                } else if angle < critical - 1e-9 {
                    #expect(vector.transmission != nil)
                    #expect(scalar.transmission != nil)
                }
            }
            for angle in angles where angle > 0 {
                #expect(Interface(from: .vacuum, into: 1.5).refracted(incoming(angle), at: up).transmission != nil)
            }
        }

        @Test
        func `The law of reflection mirrors a direction about the normal`() {
            #expect(Refraction.reflected(Vector<3, Double>([0.6, 0, -0.8]), at: up) == Vector([0.6, 0, 0.8]))
            #expect(Refraction.reflected(Vector<3, Double>([0, 0, -1]), at: up) == Vector([0, 0, 1]))
            #expect(Refraction.reflected(Vector<3, Double>([0, 1, 0]), at: up) == Vector([0, 1, 0]))
            let outcome = Refraction.Outcome<Int>.totalInternalReflection(3)
            #expect(outcome.value == 3 && outcome.transmission == nil)
        }
    }
}

extension `Refraction Tests` {
    @Suite
    struct `Fresnel's equations` {
        @Test
        func `The reflected and transmitted shares sum to one`() {
            for interface in interfaces {
                for angle in angles {
                    let cosine = Double.cos(angle)
                    let reflected = interface.reflectance(cosine: cosine)
                    let transmitted = interface.transmittance(cosine: cosine)
                    #expect(reflected >= 0 && reflected <= 1 && transmitted >= 0 && transmitted <= 1 + 1e-15)
                    #expect(`Refraction Tests`.close(reflected + transmitted, 1, within: 1e-12))
                }
            }
        }

        @Test
        func `Head-on the share is the squared ratio of the difference to the sum, and at a grazing angle all`() {
            let glass = Interface(from: .vacuum, into: 1.5)
            #expect(`Refraction Tests`.close(glass.reflectance(cosine: 1), 0.04))
            #expect(`Refraction Tests`.close(glass.reversed.reflectance(cosine: 1), 0.04))
            #expect(`Refraction Tests`.close(Interface(from: .vacuum, into: 2).reflectance(cosine: 1), 1.0 / 9))
            #expect(`Refraction Tests`.close(glass.reflectance(cosine: 0.5), 0.089_186_712_802_212_76, within: 1e-15))
            #expect(glass.reflectance(cosine: 0) == 1)
            #expect(glass.transmittance(cosine: 0) == 0)
            #expect(Interface(from: 1.5, into: 1.5).reflectance(cosine: 0.3) == 0)
            #expect(Interface(from: 1.5, into: 1.5).reflectance(cosine: 0) == 0)
            var last = 0.0
            for step in stride(from: 1.0, through: 0.0, by: -0.05) {
                let share = glass.reflectance(cosine: step)
                #expect(share >= last - 1e-12)
                last = share
            }
        }

        @Test
        func `Beyond the critical angle everything is reflected`() throws {
            let interface = Interface(from: 1.5, into: .vacuum)
            let critical = try #require(interface.critical).underlying
            for angle in angles where angle > critical + 1e-9 {
                #expect(interface.reflectance(cosine: Double.cos(angle)) == 1)
                #expect(interface.transmittance(cosine: Double.cos(angle)) == 0)
                #expect(Refraction.Schlick(interface).reflectance(cosine: Double.cos(angle)) == 1)
            }
        }

        @Test
        func `Schlick's approximation is within four hundredths of Fresnel's equations between vacuum and glass`() {
            for interface in [Interface(from: .vacuum, into: 1.5), Interface(from: 1.5, into: .vacuum)] {
                let schlick = Refraction.Schlick(interface)
                #expect(`Refraction Tests`.close(schlick.normal, interface.reflectance(cosine: 1)))
                #expect(`Refraction Tests`.close(schlick.reflectance(cosine: 1), interface.reflectance(cosine: 1)))
                for step in stride(from: 0.0, through: 1, by: 0.001) {
                    #expect(abs(schlick.reflectance(cosine: step) - interface.reflectance(cosine: step)) <= 0.04)
                }
            }
            #expect(Refraction.Schlick(Interface(from: .vacuum, into: 1.5)).reflectance(cosine: 0) == 1)
        }
    }
}

extension `Refraction Tests` {
    @Suite
    struct `Cauchy's law` {
        @Test
        func `An infinite Abbe number gives one index for every wavelength`() {
            let medium = Refraction.Cauchy<Double>(index: 1.5)
            #expect(medium.abbe == .infinity && !medium.isDispersive && medium.b == 0 && medium.a == 1.5)
            for nanometres in stride(from: 380.0, through: 750, by: 10) {
                #expect(medium.index(at: .init(nanometres: nanometres)) == 1.5)
            }
            for abbe in [0, -20, Double.nan] {
                #expect(Refraction.Cauchy(index: 1.5, abbe: abbe).index(at: .init(nanometres: 420)) == 1.5)
            }
        }

        @Test
        func `A finite Abbe number gives blue a higher index than red, and the Abbe number back`() {
            for abbe in [17.0, 30, 45, 64] {
                let medium = Refraction.Cauchy<Double>(index: 1.5, abbe: abbe)
                let blue = medium.index(at: .init(nanometres: 450))
                let green = medium.index(at: .init(nanometres: 530))
                let red = medium.index(at: .init(nanometres: 680))
                #expect(blue > green && green > red)
                #expect(medium.index(at: .d) == 1.5)
                let f = medium.index(at: .F).value
                let c = medium.index(at: .C).value
                #expect(`Refraction Tests`.close((1.5 - 1) / (f - c), abbe, within: 1e-9))
                let lambda = 600.0
                #expect(`Refraction Tests`.close(medium.index(at: .init(nanometres: lambda)).value, medium.a + medium.b / (lambda * lambda)))
            }
            #expect(Refraction.Cauchy(index: 1.5, abbe: 20).index(at: .init(nanometres: 0)) == 1.5)
        }

        @Test
        func `A wavelength is the same in nanometres and in metres`() {
            let green = Refraction.Wavelength<Double>(metres: 5.5e-7)
            #expect(`Refraction Tests`.close(green.nanometres, 550, within: 1e-9))
            #expect(`Refraction Tests`.close(Refraction.Wavelength<Double>(nanometres: 550).metres, 5.5e-7, within: 1e-20))
            #expect(Refraction.Wavelength<Double>.F < .d && Refraction.Wavelength<Double>.d < .C)
        }
    }
}

extension `Refraction Tests` {
    @Suite
    struct `Lenses` {
        @Test
        func `A ball of index n enlarges by n over two minus n at contact`() {
            for index in [1.2, 1.33, 1.5, 1.8] {
                let ball = Refraction.Ball<Double>(index: .init(index), radius: 15)
                #expect(`Refraction Tests`.close(ball.enlargement(at: 0), index / (2 - index), within: 1e-12))
            }
            let glass = Refraction.Ball<Double>(index: 1.5, radius: 15)
            #expect(`Refraction Tests`.close(glass.enlargement(at: 0), 3))
            #expect(glass.enlargement(at: 3) > glass.enlargement(at: 0))
            #expect(`Refraction Tests`.close(glass.focal.back, 7.5))
            #expect(glass.enlargement(at: 40) < 0)
        }

        @Test
        func `A ball is the thick lens of its two faces`() {
            for index in [1.2, 1.5, 1.8] {
                let ball = Refraction.Ball<Double>(index: .init(index), radius: 4, surroundings: 1.33)
                #expect(`Refraction Tests`.close(ball.focal.length, ball.lens.focalLength, within: 1e-12))
            }
            #expect(Refraction.Ball<Double>(index: 1, radius: 4).focal.length == .infinity)
        }

        @Test
        func `A thin lens follows the lensmaker's equation, and a flat plate has no power`() {
            let thin = Refraction.Lens<Double>(index: 1.5, front: 100, back: -100, thickness: 0)
            #expect(`Refraction Tests`.close(thin.focalLength, 100))
            let plano = Refraction.Lens<Double>(index: 1.5, front: 50, back: .infinity, thickness: 5)
            #expect(`Refraction Tests`.close(plano.focalLength, 100))
            let plate = Refraction.Lens<Double>(index: 1.5, front: .infinity, back: .infinity, thickness: 5)
            #expect(plate.power == 0)
            let water = Refraction.Lens<Double>(index: 1.5, front: 100, back: -100, thickness: 0, surroundings: 1.5)
            #expect(water.power == 0)
            let diverging = Refraction.Lens<Double>(index: 1.5, front: -100, back: 100, thickness: 2)
            #expect(diverging.power < 0)
        }
    }
}
