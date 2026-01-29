//
//  VedicEngine.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//


import Foundation

enum VargaChart: Int, CaseIterable {
    case d1 = 1, d2 = 2, d3 = 3, d4 = 4, d5 = 5, d6 = 6, d7 = 7, d8 = 8, d9 = 9, d10 = 10
    case d11 = 11, d12 = 12, d16 = 16, d20 = 20, d24 = 24, d27 = 27, d30 = 30
    case d40 = 40, d45 = 45, d60 = 60
}

struct BirthInput {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
    let second: Int
    let timeZone: TimeZone
    let latitude: Double
    let longitude: Double
    let locationName: String
}

struct VargaPosition {
    let signIndex: Int
    let degreeInSign: Double

    var longitude: Double {
        Double(signIndex) * 30.0 + degreeInSign
    }
}

class VedicEngine {
    static let shared = VedicEngine()
    
    init() {
        if let path = Bundle.main.resourcePath {
            swe_set_ephe_path(path)
        }
        
        swe_set_sid_mode(Int32(SE_SIDM_LAHIRI), 0, 0)
    }

    func generateD1Chart(date: Date, lat: Double, lon: Double) -> ChartData {
        generateChart(date: date, lat: lat, lon: lon, varga: .d1)
    }

    func generateChart(date: Date, lat: Double, lon: Double, varga: VargaChart) -> ChartData {
        let baseChart = generateBaseChart(date: date, lat: lat, lon: lon)
        guard varga != .d1 else { return baseChart }
        return buildVargaChart(from: baseChart, varga: varga)
    }

    func generateD1Chart(input: BirthInput) -> ChartData {
        generateChart(input: input, varga: .d1)
    }

    func generateChart(input: BirthInput, varga: VargaChart) -> ChartData {
        let date = makeDate(from: input)
        let baseChart = generateBaseChart(
            date: date,
            lat: input.latitude,
            lon: input.longitude,
            locationName: input.locationName
        )
        guard varga != .d1 else { return baseChart }
        return buildVargaChart(from: baseChart, varga: varga)
    }

    func generateMoonChart(from chart: ChartData) -> ChartData {
        guard let moonLongitude = chart.planetLongitudes[.moon] else { return chart }
        return ChartData(
            birthDate: chart.birthDate,
            locationName: chart.locationName,
            coordinate: chart.coordinate,
            ascendantLongitude: moonLongitude,
            planetLongitudes: chart.planetLongitudes
        )
    }

    private func generateBaseChart(
        date: Date,
        lat: Double,
        lon: Double,
        locationName: String = "Calculated"
    ) -> ChartData {
        let julianDay = calculateJulianDay(from: date)
        let flags = Int32(SEFLG_SWIEPH) | Int32(SEFLG_SPEED)
        let ayanamsa = calculateAyanamsa(julianDay: julianDay)
        let positions = calculatePlanetLongitudes(julianDay: julianDay, flags: flags, ayanamsa: ayanamsa)
        let ascendant = calculateAscendant(julianDay: julianDay, lat: lat, lon: lon, ayanamsa: ayanamsa)
        return ChartData(
            birthDate: date,
            locationName: locationName,
            coordinate: CodableCoordinate(latitude: lat, longitude: lon),
            ascendantLongitude: ascendant,
            planetLongitudes: positions
        )
    }

    private func makeDate(from input: BirthInput) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = input.timeZone
        let components = DateComponents(
            timeZone: input.timeZone,
            year: input.year,
            month: input.month,
            day: input.day,
            hour: input.hour,
            minute: input.minute,
            second: input.second
        )
        return calendar.date(from: components) ?? Date()
    }

    private func calculateJulianDay(from date: Date) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let year = Int32(calendar.component(.year, from: date))
        let month = Int32(calendar.component(.month, from: date))
        let day = Int32(calendar.component(.day, from: date))
        let hour = Double(calendar.component(.hour, from: date))
        let minute = Double(calendar.component(.minute, from: date))
        let second = Double(calendar.component(.second, from: date))
        let decimalHour = hour + (minute / 60.0) + (second / 3600.0)
        var julianDay: Double = 0
        swe_date_conversion(year, month, day, decimalHour, CChar(Int32(SE_GREG_CAL)), &julianDay)
        return julianDay
    }

    private func calculatePlanetLongitudes(
        julianDay: Double,
        flags: Int32,
        ayanamsa: Double
    ) -> [Planet: Double] {
        var positions = [Planet: Double]()
        let planetMap: [Planet: Int32] = [
            .sun: Int32(SE_SUN), .moon: Int32(SE_MOON), .mars: Int32(SE_MARS),
            .mercury: Int32(SE_MERCURY), .jupiter: Int32(SE_JUPITER),
            .venus: Int32(SE_VENUS), .saturn: Int32(SE_SATURN), .rahu: Int32(SE_MEAN_NODE)
        ]
        var xx = [Double](repeating: 0.0, count: 6)
        var serr = [Int8](repeating: 0, count: 256)

        for (planet, seId) in planetMap {
            swe_calc_ut(julianDay, seId, flags, &xx, &serr)
            positions[planet] = normalizeLongitude(xx[0] - ayanamsa)
        }

        if let rahuLon = positions[.rahu] {
            positions[.ketu] = normalizeLongitude(rahuLon + 180.0)
        }

        return positions
    }

    private func calculateAscendant(
        julianDay: Double,
        lat: Double,
        lon: Double,
        ayanamsa: Double
    ) -> Double {
        var cusps = [Double](repeating: 0.0, count: 13)
        var ascmc = [Double](repeating: 0.0, count: 10)
        swe_houses_ex(julianDay, Int32(SEFLG_SWIEPH), lat, lon, Int32(UnicodeScalar("W").value), &cusps, &ascmc)
        return normalizeLongitude(ascmc[0] - ayanamsa)
    }

    private func calculateAyanamsa(julianDay: Double) -> Double {
        swe_get_ayanamsa_ut(julianDay)
    }

    private func normalizeLongitude(_ longitude: Double) -> Double {
        var normalized = longitude.truncatingRemainder(dividingBy: 360.0)
        if normalized < 0 {
            normalized += 360.0
        }
        return normalized
    }

    private func buildVargaChart(from chart: ChartData, varga: VargaChart) -> ChartData {
        let ascendantPosition = VargaRules.mapPosition(longitude: chart.ascendantLongitude, varga: varga)
        var mappedPlanets: [Planet: Double] = [:]

        for (planet, longitude) in chart.planetLongitudes {
            let position = VargaRules.mapPosition(longitude: longitude, varga: varga)
            mappedPlanets[planet] = position.longitude
        }

        return ChartData(
            birthDate: chart.birthDate,
            locationName: chart.locationName,
            coordinate: chart.coordinate,
            ascendantLongitude: ascendantPosition.longitude,
            planetLongitudes: mappedPlanets
        )
    }
}

enum SignType {
    case movable
    case fixed
    case dual
}

struct VargaRules {
    static func mapPosition(longitude: Double, varga: VargaChart) -> VargaPosition {
        let signIndex = Int(floor(longitude / 30.0))
        let degreeInSign = longitude.truncatingRemainder(dividingBy: 30.0)
        return mapPosition(signIndex: signIndex, degreeInSign: degreeInSign, varga: varga)
    }

    static func mapPosition(signIndex: Int, degreeInSign: Double, varga: VargaChart) -> VargaPosition {
        switch varga {
        case .d1:
            return VargaPosition(signIndex: signIndex, degreeInSign: degreeInSign)
        case .d2:
            return horaMapping(signIndex: signIndex, degreeInSign: degreeInSign)
        case .d3:
            return drekkanaMapping(signIndex: signIndex, degreeInSign: degreeInSign)
        case .d4:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 4, evenOffset: 3)
        case .d5:
            return tableMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 5, table: VargaTables.d5)
        case .d6:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 6, evenOffset: 6)
        case .d7:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 7, evenOffset: 6)
        case .d8:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 8, evenOffset: 8)
        case .d9:
            return signTypeMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 9, table: VargaTables.d9)
        case .d10:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 10, evenOffset: 8)
        case .d11:
            return signTypeMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 11, table: VargaTables.d11)
        case .d12:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 12, evenOffset: 0)
        case .d16:
            return signTypeMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 16, table: VargaTables.d16)
        case .d20:
            return signTypeMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 20, table: VargaTables.d20)
        case .d24:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 24, evenOffset: 3)
        case .d27:
            return signTypeMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 27, table: VargaTables.d27)
        case .d30:
            return trimsamsaMapping(signIndex: signIndex, degreeInSign: degreeInSign)
        case .d40:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 40, evenOffset: 4)
        case .d45:
            return offsetMapping(signIndex: signIndex, degreeInSign: degreeInSign, divisions: 45, evenOffset: 8)
        case .d60:
            return shashtiamsaMapping(signIndex: signIndex, degreeInSign: degreeInSign)
        }
    }

    private static func horaMapping(signIndex: Int, degreeInSign: Double) -> VargaPosition {
        let isOdd = signIndex.isOddSign
        let divisionSize = 15.0
        let divisionIndex = Int(floor(degreeInSign / divisionSize))
        let targetSign = (isOdd ? [4, 3] : [3, 4])[min(divisionIndex, 1)]
        let degree = degreeInVargaSign(degreeInSign: degreeInSign, divisionSize: divisionSize)
        return VargaPosition(signIndex: targetSign, degreeInSign: degree)
    }

    private static func drekkanaMapping(signIndex: Int, degreeInSign: Double) -> VargaPosition {
        let divisionSize = 10.0
        let divisionIndex = Int(floor(degreeInSign / divisionSize))
        let sequence = signIndex.isOddSign
            ? [signIndex, signIndex + 4, signIndex + 8]
            : [signIndex, signIndex + 8, signIndex + 4]
        let targetSign = sequence[min(divisionIndex, 2)] % 12
        let degree = degreeInVargaSign(degreeInSign: degreeInSign, divisionSize: divisionSize)
        return VargaPosition(signIndex: targetSign, degreeInSign: degree)
    }

    private static func offsetMapping(
        signIndex: Int,
        degreeInSign: Double,
        divisions: Int,
        evenOffset: Int
    ) -> VargaPosition {
        let divisionSize = 30.0 / Double(divisions)
        let divisionIndex = Int(floor(degreeInSign / divisionSize))
        let startIndex = signIndex.isOddSign ? signIndex : (signIndex + evenOffset) % 12
        let targetSign = (startIndex + divisionIndex) % 12
        let degree = degreeInVargaSign(degreeInSign: degreeInSign, divisionSize: divisionSize)
        return VargaPosition(signIndex: targetSign, degreeInSign: degree)
    }

    private static func signTypeMapping(
        signIndex: Int,
        degreeInSign: Double,
        divisions: Int,
        table: [SignType: [Int]]
    ) -> VargaPosition {
        let divisionSize = 30.0 / Double(divisions)
        let divisionIndex = Int(floor(degreeInSign / divisionSize))
        let signType = signIndex.signType
        let sequence = table[signType] ?? []
        let targetSign = sequence.isEmpty ? signIndex : sequence[min(divisionIndex, sequence.count - 1)]
        let degree = degreeInVargaSign(degreeInSign: degreeInSign, divisionSize: divisionSize)
        return VargaPosition(signIndex: targetSign, degreeInSign: degree)
    }

    private static func tableMapping(
        signIndex: Int,
        degreeInSign: Double,
        divisions: Int,
        table: [SignType: [Int]]
    ) -> VargaPosition {
        let divisionSize = 30.0 / Double(divisions)
        let divisionIndex = Int(floor(degreeInSign / divisionSize))
        let signType = signIndex.signType
        let sequence = table[signType] ?? []
        let targetSign = sequence.isEmpty ? signIndex : sequence[min(divisionIndex, sequence.count - 1)]
        let degree = degreeInVargaSign(degreeInSign: degreeInSign, divisionSize: divisionSize)
        return VargaPosition(signIndex: targetSign, degreeInSign: degree)
    }

    private static func trimsamsaMapping(signIndex: Int, degreeInSign: Double) -> VargaPosition {
        let isOdd = signIndex.isOddSign
        let segments = isOdd ? VargaTables.d30Odd : VargaTables.d30Even
        var remaining = degreeInSign

        for segment in segments {
            if remaining < segment.size {
                let degree = (remaining / segment.size) * 30.0
                return VargaPosition(signIndex: segment.signIndex, degreeInSign: degree)
            }
            remaining -= segment.size
        }

        let fallback = segments.last?.signIndex ?? signIndex
        return VargaPosition(signIndex: fallback, degreeInSign: 29.9999)
    }

    private static func shashtiamsaMapping(signIndex: Int, degreeInSign: Double) -> VargaPosition {
        let divisionSize = 0.5
        let divisionIndex = Int(floor(degreeInSign / divisionSize))
        let startIndex = signIndex.isOddSign ? 0 : 6
        let targetSign = (startIndex + divisionIndex) % 12
        let degree = degreeInVargaSign(degreeInSign: degreeInSign, divisionSize: divisionSize)
        return VargaPosition(signIndex: targetSign, degreeInSign: degree)
    }

    private static func degreeInVargaSign(degreeInSign: Double, divisionSize: Double) -> Double {
        let degreeInDivision = degreeInSign.truncatingRemainder(dividingBy: divisionSize)
        return (degreeInDivision / divisionSize) * 30.0
    }
}

struct VargaTables {
    static let d5: [SignType: [Int]] = [
        .movable: [0, 1, 2, 3, 4],
        .fixed: [4, 3, 2, 1, 0],
        .dual: [8, 9, 10, 11, 0]
    ]

    static let d9: [SignType: [Int]] = [
        .movable: sequence(startIndex: 0, count: 9),
        .fixed: sequence(startIndex: 8, count: 9),
        .dual: sequence(startIndex: 4, count: 9)
    ]

    static let d11: [SignType: [Int]] = [
        .movable: sequence(startIndex: 0, count: 11),
        .fixed: sequence(startIndex: 4, count: 11),
        .dual: sequence(startIndex: 8, count: 11)
    ]

    static let d16: [SignType: [Int]] = [
        .movable: sequence(startIndex: 0, count: 16),
        .fixed: sequence(startIndex: 4, count: 16),
        .dual: sequence(startIndex: 8, count: 16)
    ]

    static let d20: [SignType: [Int]] = [
        .movable: sequence(startIndex: 0, count: 20),
        .fixed: sequence(startIndex: 8, count: 20),
        .dual: sequence(startIndex: 4, count: 20)
    ]

    static let d27: [SignType: [Int]] = [
        .movable: sequence(startIndex: 0, count: 27),
        .fixed: sequence(startIndex: 4, count: 27),
        .dual: sequence(startIndex: 8, count: 27)
    ]

    static let d30Odd: [VargaSegment] = [
        VargaSegment(size: 5.0, signIndex: 0),
        VargaSegment(size: 5.0, signIndex: 10),
        VargaSegment(size: 8.0, signIndex: 8),
        VargaSegment(size: 7.0, signIndex: 2),
        VargaSegment(size: 5.0, signIndex: 6)
    ]

    static let d30Even: [VargaSegment] = [
        VargaSegment(size: 5.0, signIndex: 6),
        VargaSegment(size: 7.0, signIndex: 2),
        VargaSegment(size: 8.0, signIndex: 8),
        VargaSegment(size: 5.0, signIndex: 10),
        VargaSegment(size: 5.0, signIndex: 0)
    ]

    private static func sequence(startIndex: Int, count: Int) -> [Int] {
        (0..<count).map { (startIndex + $0) % 12 }
    }
}

struct VargaSegment {
    let size: Double
    let signIndex: Int
}

private extension Int {
    var isOddSign: Bool {
        self % 2 == 0
    }

    var signType: SignType {
        switch self {
        case 0, 3, 6, 9:
            return .movable
        case 1, 4, 7, 10:
            return .fixed
        default:
            return .dual
        }
    }
}
