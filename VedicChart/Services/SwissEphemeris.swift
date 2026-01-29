//
//  SwissEphemeris.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//

import Foundation

final class SwissEphemeris {
    static let shared = SwissEphemeris()

    private init() {
        setupEphemerisPath()
    }

    deinit {
        swe_close()
    }

    private func setupEphemerisPath() {
        if let path = Bundle.main.resourcePath {
            swe_set_ephe_path(path)
        }
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

    var sweCode: Int32 {
        switch self {
        case .sun: return Int32(SE_SUN)
        case .moon: return Int32(SE_MOON)
        case .mars: return Int32(SE_MARS)
        case .mercury: return Int32(SE_MERCURY)
        case .jupiter: return Int32(SE_JUPITER)
        case .venus: return Int32(SE_VENUS)
        case .saturn: return Int32(SE_SATURN)
        case .rahu: return Int32(SE_TRUE_NODE)
        case .ketu: return Int32(SE_TRUE_NODE)
        }
    }
}

func configureSiderealMode() {
    swe_set_sid_mode(Int32(SE_SIDM_LAHIRI), 0, 0)
}

func siderealLongitude(
    julianDay: Double,
    planet: SEPlanet
) throws -> Double {
    var result = [Double](repeating: 0.0, count: 6)
    var error = [Int8](repeating: 0, count: 256)

    let flags = SEFLG_SWIEPH | SEFLG_SIDEREAL

    let ret = swe_calc_ut(
        julianDay,
        planet.sweCode,
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
