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
