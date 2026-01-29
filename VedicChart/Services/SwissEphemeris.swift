//
//  SwissEphemeris.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//

import Foundation

enum NodeType {
    case trueNode
    case meanNode

    var sweCode: Int32 {
        switch self {
        case .trueNode:
            return Int32(SE_TRUE_NODE)
        case .meanNode:
            return Int32(SE_MEAN_NODE)
        }
    }
}

enum SiderealMode: CaseIterable {
    case lahiri
    case lahiri1940
    case lahiriVp285
    case lahiriIcrc

    var sweCode: Int32 {
        switch self {
        case .lahiri:
            return Int32(SE_SIDM_LAHIRI)
        case .lahiri1940:
            return Int32(SE_SIDM_LAHIRI_1940)
        case .lahiriVp285:
            return Int32(SE_SIDM_LAHIRI_VP285)
        case .lahiriIcrc:
            return Int32(SE_SIDM_LAHIRI_ICRC)
        }
    }
}

struct AyanamsaInfo: Codable {
    let name: String
    let value: Double
}

final class SwissEphemeris {
    static let shared = SwissEphemeris()
    private(set) var nodeType: NodeType = .trueNode
    private(set) var siderealMode: SiderealMode = .lahiri
    private var isNodeTypeConfigured = false
    private var isSiderealModeConfigured = false

    private init() {
        setupEphemerisPath()
        configureSiderealMode(.lahiri)
    }

    deinit {
        swe_close()
    }

    private func setupEphemerisPath() {
        if let path = Bundle.main.resourcePath {
            swe_set_ephe_path(path)
        }
    }

    func configureNodeType(_ nodeType: NodeType) {
        guard !isNodeTypeConfigured else { return }
        self.nodeType = nodeType
        isNodeTypeConfigured = true
    }

    func configureSiderealMode(_ mode: SiderealMode) {
        siderealMode = mode
        swe_set_sid_mode(mode.sweCode, 0, 0)
        isSiderealModeConfigured = true
    }

    func ensureSiderealModeConfigured() {
        guard isSiderealModeConfigured else {
            let message = "SwissEphemeris sidereal mode was not configured before sidereal calculations."
            assertionFailure(message)
            NSLog(message)
            configureSiderealMode(siderealMode)
            return
        }
    }

    func ayanamsaInfo(julianDayET: Double) -> AyanamsaInfo? {
        var value = Double(0)
        var error = [Int8](repeating: 0, count: 256)
        let ret = swe_get_ayanamsa_ex(julianDayET, 0, &value, &error)
        guard ret >= 0 else {
            return nil
        }
        let name = String(cString: swe_get_ayanamsa_name(siderealMode.sweCode))
        return AyanamsaInfo(name: name, value: value)
    }
}

enum SEPlanet {
    case sun
    case moon
    case mars
    case mercury
    case jupiter
    case venus
    case saturn
    case rahu
    case ketu

    func sweCode(nodeType: NodeType) -> Int32 {
        switch self {
        case .sun: return Int32(SE_SUN)
        case .moon: return Int32(SE_MOON)
        case .mars: return Int32(SE_MARS)
        case .mercury: return Int32(SE_MERCURY)
        case .jupiter: return Int32(SE_JUPITER)
        case .venus: return Int32(SE_VENUS)
        case .saturn: return Int32(SE_SATURN)
        case .rahu: return nodeType.sweCode
        case .ketu: return nodeType.sweCode
        }
    }
}

func configureSiderealMode(_ mode: SiderealMode) {
    SwissEphemeris.shared.configureSiderealMode(mode)
}

func siderealLongitude(
    julianDay: Double,
    planet: SEPlanet
) throws -> Double {
    SwissEphemeris.shared.ensureSiderealModeConfigured()
    var result = [Double](repeating: 0.0, count: 6)
    var error = [Int8](repeating: 0, count: 256)

    let flags = SEFLG_SWIEPH | SEFLG_SIDEREAL

    let ret = swe_calc_ut(
        julianDay,
        planet.sweCode(nodeType: SwissEphemeris.shared.nodeType),
        Int32(flags),
        &result,
        &error
    )

    if ret < 0 {
        let message = String(cString: error)
        throw NSError(domain: "SwissEphemeris", code: -1, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }

    var longitude = result[0]

    if planet == .ketu {
        longitude += 180.0
        if longitude >= 360.0 {
            longitude -= 360.0
        }
    }

    return longitude
}

func ascendantLongitude(
    julianDay: Double,
    latitude: Double,
    longitude: Double
) throws -> Double {
    SwissEphemeris.shared.ensureSiderealModeConfigured()
    var cusps = [Double](repeating: 0.0, count: 13)
    var ascmc = [Double](repeating: 0.0, count: 10)

    let flags = SEFLG_SIDEREAL
    let ret = swe_houses_ex(
        julianDay,
        Int32(flags),
        latitude,
        longitude,
        Int32("P".utf8.first!),
        &cusps,
        &ascmc
    )

    if ret < 0 {
        throw NSError(domain: "SwissEphemeris", code: -2)
    }

    return ascmc[Int(SE_ASC)]
}
