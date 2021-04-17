//
//  Dictionary.swift
//  words (iOS)
//
//  Created by Dan Weiner on 4/10/21.
//

import Foundation

struct DWError: LocalizedError, Identifiable {
    let id = UUID()

    let description: String

    var errorDescription: String? {
        description
    }
}

// Provides a Swift API around the `words` executable.
class Dictionary {

    enum Direction: Int, CustomDebugStringConvertible {
        // Do not change. Reflected in tags in interface builder.
        case latinToEnglish = 0
        case englishToLatin = 1

        var debugDescription: String {
            switch self {
            case .englishToLatin: return "Eng->Ltn"
            case .latinToEnglish: return "Ltn->Eng"
            }
        }
    }

    struct Options: OptionSet {
        let rawValue: Int
        static let diagnosticMode = Options(rawValue: 1 << 0)
    }

    public static let shared = Dictionary()

    private lazy var executableURL: URL = {
        guard let url = Bundle.main.url(forAuxiliaryExecutable: "words") else {
            fatalError("Could not find words program file in bundle.")
        }
        return url
    }()
    private lazy var executablePath = executableURL.path
    private lazy var workingDir: URL = {
        guard var url = Bundle.main.url(forResource: "DICTFILE", withExtension: "GEN") else {
            fatalError("Could not find resource directory.")
        }
        return url.deletingLastPathComponent()
    }()

    private init() {}

    func getDefinition(_ search: String, direction: Direction, options: Options) throws -> String? {
        var input = direction == .englishToLatin ? "~E\n" : "~L\n"
        input += trim(input: search)
        input += "\n\n\n"
        let output = try runProcess(executablePath, stdin: input + "\n\n\n")
        if .diagnosticMode ~= options {
            let definitions = try parseDefinitions(from: output) ?? "No results found"
            return definitions + """
            \n\n\n\n
            ===============
            DIAGNOSTIC MODE
            ===============

            Program input:
            --------------
            \(input)

            Program output:
            ---------------
            \(output)
            """
        } else {
            return try parseDefinitions(from: output)
        }
    }

    private func trim(input: String) -> String {
        let commandCharacters = CharacterSet(["#", "!", "@"])
        return input.trimmingCharacters(in: commandCharacters)
    }

    private func parseDefinitions(from output: String) throws -> String? {
        let lines = output.split(separator: "\n")
        var start: Int?
        var end: Int?
        for (i, line) in lines.enumerated() {
            if line == "=>" {
                start = i + 1
            } else if line == "=>Blank exits =>" {
                end = i - 1
            }
        }
        guard let start = start else {
            return nil // No entry found
        }
        guard let end = end,
              start < end else {
            throw DWError(description: "Incorrectly formatted program output")
        }
        return lines[start...end].joined(separator: "\n")
    }

    @discardableResult
    private func runProcess(
        _ launchPath: String,
        arguments: [String] = [],
        stdin: String? = nil
    ) throws -> String {
        let p = Process()
        p.currentDirectoryURL = workingDir
        p.launchPath = launchPath
        p.arguments = arguments
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        p.standardOutput = outputPipe
        p.standardError = errorPipe

        if let stdin = stdin {
            let pipe = Pipe()
            pipe.fileHandleForWriting.write(stdin.data(using: .utf8) ?? Data())
            p.standardInput = pipe
        }

        try p.run()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let error = String(decoding: errorData, as: UTF8.self)

        if p.terminationStatus != 0 {
            throw DWError(description: "Program failed with exit code \(p.terminationStatus)")
        }

        if error.count > 0 {
            throw DWError(description: error)
        } else {
            return output
        }
    }
}
