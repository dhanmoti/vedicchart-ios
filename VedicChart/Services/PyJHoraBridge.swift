//
//  PyJHoraBridge.swift
//  VedicChart
//
//  Created by Dhan Moti on 29/1/26.
//

import Foundation

#if canImport(PythonKit)
import PythonKit
#endif

struct PyJHoraBridge {
    static func diagnostic(input: BirthInput) -> String {
        #if canImport(PythonKit)
        if let errorMessage = configurePythonPath() {
            return errorMessage
        }

        let module = Python.attemptImport("pyjhora")
        guard let pyjhora = module else {
            return missingPyJHoraMessage()
        }

        let sys = Python.import("sys")
        let version = pyjhora.__version__
        let pythonVersion = sys.version

        let header = "--- PYJHORA RESULTS ---\n"
        let info = "PyJHora Version: \(version)\nPython: \(pythonVersion)\n"
        let payload = "Input: \(input.locationName) | \(input.year)-\(input.month)-\(input.day) \(input.hour):\(input.minute):\(input.second) | Lat \(input.latitude), Lon \(input.longitude)\n"
        let footer = "\nPyJHora is available from the bundled python directory. Use this hook to wire up chart calculations."
        return header + info + payload + footer
        #else
        return "PythonKit is unavailable on this platform, so PyJHora cannot be loaded."
        #endif
    }

    #if canImport(PythonKit)
    private static func configurePythonPath() -> String? {
        let fileManager = FileManager.default
        guard let resourceURL = Bundle.main.resourceURL else {
            return "Unable to locate app bundle resources for Python modules."
        }

        let pythonURL = resourceURL.appendingPathComponent("python")
        guard fileManager.fileExists(atPath: pythonURL.path) else {
            return "Python modules not found. Add PyJHora to VedicChart/Resources/python so it is bundled."
        }

        let sys = Python.import("sys")
        sys.path.append(pythonURL.path)
        return nil
    }

    private static func missingPyJHoraMessage() -> String {
        let message = "PyJHora could not be imported. Ensure the library is bundled under Resources/python (site-packages) or installed into the embedded Python environment."
        return message
    }
    #endif
}
