//
//  VedicTestView.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//


import SwiftUI

struct VedicTestView: View {
    @State private var output: String = "Press 'Run Test' to calculate..."
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Vedic Engine Diagnostic")
                    .font(.title).bold()
                
                Button("Run Calculation Test") {
                    runDiagnostic()
                }
                .buttonStyle(.borderedProminent)
                
                Divider()
                
                Text(output)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
        }
    }
    
    func runDiagnostic() {
        let engine = VedicEngine.shared
        let rangoonTimeZone = TimeZone(secondsFromGMT: 6 * 3600 + 1800) ?? .current
        let input = BirthInput(
            year: 1991,
            month: 11,
            day: 13,
            hour: 15,
            minute: 0,
            second: 0,
            timeZone: rangoonTimeZone,
            latitude: 16.8409,
            longitude: 96.1735,
            locationName: "Rangoon, Burma"
        )
        let charts = VargaChart.allCases.map { varga in
            (varga, engine.generateChart(input: input, varga: varga))
        }

        var report = "--- RESULTS ---\n"
        for (index, entry) in charts.enumerated() {
            report += formatChartReport(title: "\(entry.0.displayName) Chart", chart: entry.1)
            if index < charts.count - 1 {
                report += "\n\n"
            }
        }

        self.output = report
    }

    private func formatChartReport(title: String, chart: ChartData) -> String {
        var report = "\(title)\n"
        report += "Location: \(chart.locationName)\n"
        if let ayanamsa = chart.ayanamsa {
            report += "Ayanamsa: \(ayanamsa.name) (\(String(format: "%.4f", ayanamsa.value))°)\n"
        }
        report += "Ascendant: \(String(format: "%.2f", chart.ascendantLongitude))°\n"
        report += "Asc Sign: \(chart.ascendantSignIndex + 1) (1=Aries)\n\n"

        report += "Planet      | Deg        | House\n"
        report += "-------------------------------\n"

        for planet in Planet.allCases {
            let lon = chart.planetLongitudes[planet] ?? 0
            let house = chart.getHouse(for: planet)
            report += String(format: "%-11@ | %-10.2f | %-5d\n", planet.rawValue, lon, house)
        }

        return report
    }
}
