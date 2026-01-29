//
//  VedicTestView2.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//

import SwiftUI

struct VedicTestView2: View {
    @State private var output: String = "Press 'Run PyJHora Test' to calculate..."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("PyJHora Diagnostic")
                    .font(.title).bold()

                Button("Run PyJHora Test") {
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
        let input = BirthInput(
            year: 1991,
            month: 11,
            day: 13,
            hour: 15,
            minute: 0,
            second: 0,
            timeZone: TimeZone(secondsFromGMT: 6 * 3600 + 1800) ?? .current,
            latitude: 16.8409,
            longitude: 96.1735,
            locationName: "Rangoon, Burma"
        )

        output = PyJHoraBridge.diagnostic(input: input)
    }
}

#Preview {
    VedicTestView2()
}
