//
//  VedicChartTests.swift
//  VedicChartTests
//
//  Created by Dhan Moti on 29/1/26.
//

import Foundation
import Testing
@testable import VedicChart

struct VedicChartTests {

    @Test("Matches Astroyogi stress test sample rows")
    func stressTestSampleRowsMatchAstroyogi() async throws {
        let rows = try StressTestRow.load(from: StressTestRow.defaultCSVURL, limit: 5)
        #expect(!rows.isEmpty, "Expected stress test rows to load.")

        let engine = VedicEngine.shared
        let tolerance = 0.1

        for row in rows {
            let chart = engine.generateChart(input: row.birthInput, varga: .d1)

            #expect(abs(chart.ascendantLongitude - row.expectedAscendantLongitude) <= tolerance,
                    "Ascendant mismatch for \(row.debugDescription)")

            for (planet, expectedLongitude) in row.expectedPlanetLongitudes {
                let actualLongitude = chart.planetLongitudes[planet] ?? 0.0
                #expect(abs(actualLongitude - expectedLongitude) <= tolerance,
                        "\(planet.rawValue) mismatch for \(row.debugDescription)")
            }
        }
    }

    @Test("Divisional charts match fixture data")
    func divisionalChartsMatchFixtureData() async throws {
        let rows = try DivisionalChartFixtureRow.load(from: DivisionalChartFixtureRow.defaultCSVURL)
        #expect(!rows.isEmpty, "Expected divisional chart fixture rows to load.")

        let engine = VedicEngine.shared

        for row in rows {
            for (varga, expectations) in row.expectedVargas {
                let chart = engine.generateChart(input: row.birthInput, varga: varga)
                let ascendantSignIndex = chart.ascendantSignIndex

                #expect(
                    ascendantSignIndex == expectations.ascendantSignIndex,
                    "Ascendant mismatch for \(row.debugDescription) \(varga.displayName)"
                )

                for (planet, expectedHouse) in expectations.planetHouses {
                    let actualHouse = chart.getHouse(for: planet)
                    #expect(
                        actualHouse == expectedHouse,
                        "\(planet.rawValue) house mismatch for \(row.debugDescription) \(varga.displayName)"
                    )
                }
            }
        }
    }
}

private struct StressTestRow {
    let birthInput: BirthInput
    let expectedAscendantLongitude: Double
    let expectedPlanetLongitudes: [Planet: Double]
    let debugDescription: String

    static var defaultCSVURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("AstroyogiStressTestData.csv")
    }

    static func load(from url: URL, limit: Int? = nil) throws -> [StressTestRow] {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StressTestError.invalidEncoding
        }

        let lines = content.split(whereSeparator: \.isNewline)
        guard let header = lines.first else {
            throw StressTestError.missingHeader
        }
        let headers = header.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard headers.count >= 36 else {
            throw StressTestError.invalidHeader
        }

        var rows: [StressTestRow] = []
        for line in lines.dropFirst() {
            if let limit, rows.count >= limit { break }
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= headers.count else { continue }
            guard let row = StressTestRow(fields: fields) else { continue }
            rows.append(row)
        }
        return rows
    }

    init?(fields: [String]) {
        guard
            let dateParts = StressTestRow.parseDate(fields[0]),
            let timeParts = StressTestRow.parseTime(fields[1]),
            let latitude = Double(fields[2]),
            let longitude = Double(fields[3]),
            let timeZoneHours = Double(fields[4]),
            let expectedAscendant = Double(fields[8]),
            let sunLongitude = Double(fields[11]),
            let moonLongitude = Double(fields[14]),
            let marsLongitude = Double(fields[17]),
            let mercuryLongitude = Double(fields[20]),
            let jupiterLongitude = Double(fields[23]),
            let venusLongitude = Double(fields[26]),
            let saturnLongitude = Double(fields[29]),
            let rahuLongitude = Double(fields[32]),
            let ketuLongitude = Double(fields[35])
        else {
            return nil
        }

        let timeZoneSeconds = Int(timeZoneHours * 3600.0)
        let timeZone = TimeZone(secondsFromGMT: timeZoneSeconds) ?? .gmt
        let locationName = fields[5]

        self.birthInput = BirthInput(
            year: dateParts.year,
            month: dateParts.month,
            day: dateParts.day,
            hour: timeParts.hour,
            minute: timeParts.minute,
            second: timeParts.second,
            timeZone: timeZone,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName
        )
        self.expectedAscendantLongitude = expectedAscendant
        self.expectedPlanetLongitudes = [
            .sun: sunLongitude,
            .moon: moonLongitude,
            .mars: marsLongitude,
            .mercury: mercuryLongitude,
            .jupiter: jupiterLongitude,
            .venus: venusLongitude,
            .saturn: saturnLongitude,
            .rahu: rahuLongitude,
            .ketu: ketuLongitude
        ]
        self.debugDescription = "\(fields[0]) \(fields[1]) \(locationName)"
    }

    private static func parseDate(_ value: String) -> (year: Int, month: Int, day: Int)? {
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        return (year, month, day)
    }

    private static func parseTime(_ value: String) -> (hour: Int, minute: Int, second: Int)? {
        let parts = value.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        let second = parts.count > 2 ? Int(parts[2]) ?? 0 : 0
        return (hour, minute, second)
    }
}

private enum StressTestError: Error {
    case invalidEncoding
    case missingHeader
    case invalidHeader
}

private struct DivisionalChartFixtureRow {
    struct VargaExpectations {
        let ascendantSignIndex: Int
        let planetHouses: [Planet: Int]
    }

    struct LocationDetails {
        let latitude: Double
        let longitude: Double
        let timeZone: TimeZone
    }

    let birthInput: BirthInput
    let expectedVargas: [VargaChart: VargaExpectations]
    let debugDescription: String

    private static let signNames: [String] = [
        "Aries",
        "Taurus",
        "Gemini",
        "Cancer",
        "Leo",
        "Virgo",
        "Libra",
        "Scorpio",
        "Sagittarius",
        "Capricorn",
        "Aquarius",
        "Pisces"
    ]

    private static let vargaColumns: [(varga: VargaChart, prefix: String)] = [
        (.d1, "D1"),
        (.d2, "D2"),
        (.d3, "D3"),
        (.d4, "D4"),
        (.d7, "D7"),
        (.d9, "D9"),
        (.d10, "D10"),
        (.d12, "D12"),
        (.d16, "D16"),
        (.d20, "D20"),
        (.d24, "D24"),
        (.d27, "D27"),
        (.d30, "D30"),
        (.d40, "D40"),
        (.d45, "D45"),
        (.d60, "D60")
    ]

    private static let planetHouseColumns: [(planet: Planet, suffix: String)] = [
        (.sun, "Sun_House"),
        (.moon, "Moon_House"),
        (.mars, "Mars_House"),
        (.mercury, "Mercury_House"),
        (.jupiter, "Jupiter_House"),
        (.venus, "Venus_House"),
        (.saturn, "Saturn_House"),
        (.rahu, "Rahu_House"),
        (.ketu, "Ketu_House")
    ]

    private static let knownLocations: [String: LocationDetails] = [
        "Rangoon, Burma": LocationDetails(
            latitude: 16.8409,
            longitude: 96.1735,
            timeZone: TimeZone(secondsFromGMT: Int(6.5 * 3600.0)) ?? .gmt
        )
    ]

    static var defaultCSVURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("vedic_divisional_charts_unit_test_fixture.csv")
    }

    static func load(from url: URL) throws -> [DivisionalChartFixtureRow] {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw DivisionalFixtureError.invalidEncoding
        }

        let lines = content.split(whereSeparator: \.isNewline)
        guard let headerLine = lines.first else {
            throw DivisionalFixtureError.missingHeader
        }

        let headers = parseCSVLine(String(headerLine))
        guard !headers.isEmpty else {
            throw DivisionalFixtureError.invalidHeader
        }

        var rows: [DivisionalChartFixtureRow] = []
        for line in lines.dropFirst() {
            let fields = parseCSVLine(String(line))
            guard fields.count >= headers.count else { continue }
            let fieldMap = Dictionary(uniqueKeysWithValues: zip(headers, fields))
            if let row = try DivisionalChartFixtureRow(fields: fieldMap) {
                rows.append(row)
            }
        }
        return rows
    }

    init?(fields: [String: String]) throws {
        guard
            let dateValue = fields["date"],
            let timeValue = fields["time"],
            let locationValue = fields["location"],
            let dateParts = DivisionalChartFixtureRow.parseDate(dateValue),
            let timeParts = DivisionalChartFixtureRow.parseTime(timeValue)
        else {
            return nil
        }

        guard let locationDetails = DivisionalChartFixtureRow.knownLocations[locationValue] else {
            throw DivisionalFixtureError.unknownLocation(locationValue)
        }

        let expectations = try DivisionalChartFixtureRow.buildVargaExpectations(from: fields)

        self.birthInput = BirthInput(
            year: dateParts.year,
            month: dateParts.month,
            day: dateParts.day,
            hour: timeParts.hour,
            minute: timeParts.minute,
            second: timeParts.second,
            timeZone: locationDetails.timeZone,
            latitude: locationDetails.latitude,
            longitude: locationDetails.longitude,
            locationName: locationValue
        )
        self.expectedVargas = expectations
        let name = fields["name"] ?? "Unknown"
        self.debugDescription = "\(name) \(dateValue) \(timeValue) \(locationValue)"
    }

    private static func buildVargaExpectations(from fields: [String: String]) throws -> [VargaChart: VargaExpectations] {
        var expectations: [VargaChart: VargaExpectations] = [:]

        for config in vargaColumns {
            let ascKey = "\(config.prefix)_AscSign"
            guard let ascSignName = fields[ascKey] else { continue }
            guard let ascendantSignIndex = signNames.firstIndex(of: ascSignName) else {
                throw DivisionalFixtureError.invalidSign(ascSignName)
            }

            var planetHouses: [Planet: Int] = [:]
            for planetColumn in planetHouseColumns {
                let key = "\(config.prefix)_\(planetColumn.suffix)"
                guard let value = fields[key], let house = Int(value) else {
                    throw DivisionalFixtureError.invalidHouse(key)
                }
                planetHouses[planetColumn.planet] = house
            }

            expectations[config.varga] = VargaExpectations(
                ascendantSignIndex: ascendantSignIndex,
                planetHouses: planetHouses
            )
        }

        return expectations
    }

    private static func parseDate(_ value: String) -> (year: Int, month: Int, day: Int)? {
        let parts = value.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        return (year, month, day)
    }

    private static func parseTime(_ value: String) -> (hour: Int, minute: Int, second: Int)? {
        let parts = value.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }
        let second = parts.count > 2 ? Int(parts[2]) ?? 0 : 0
        return (hour, minute, second)
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var index = line.startIndex

        while index < line.endIndex {
            let char = line[index]
            if char == "\"" {
                if inQuotes {
                    let nextIndex = line.index(after: index)
                    if nextIndex < line.endIndex, line[nextIndex] == "\"" {
                        current.append("\"")
                        index = nextIndex
                    } else {
                        inQuotes = false
                    }
                } else {
                    inQuotes = true
                }
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
            index = line.index(after: index)
        }

        fields.append(current)
        return fields
    }
}

private enum DivisionalFixtureError: Error {
    case invalidEncoding
    case missingHeader
    case invalidHeader
    case unknownLocation(String)
    case invalidSign(String)
    case invalidHouse(String)
}
