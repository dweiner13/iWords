//
//  ResultParser.swift
//  words (macOS)
//
//  Created by Dan Weiner on 4/24/21.
//

import Foundation
import Parsing

enum PartOfSpeech: String, CustomStringConvertible {
    case noun = "N",
         verb = "V",
         adjective = "ADJ",
         adverb = "ADV"
    
    var description: String {
        switch self {
        case .noun: return "n."
        case .verb: return "v."
        case .adjective: return "adj."
        case .adverb: return "adv."
        }
    }

    static let parser = Prefix(1).compactMap { (substr: String.SubSequence) -> PartOfSpeech? in
        PartOfSpeech(rawValue: String(substr))
    }
}

enum Gender: String, CustomStringConvertible {
    case masculine = "M",
         feminine = "F",
         neuter = "N"
    
    var description: String {
        switch self {
        case .masculine: return "masc."
        case .feminine: return "fem."
        case .neuter: return "neut."
        }
    }

    static let parser = Prefix(1).compactMap { (substr: String.SubSequence) -> Gender? in
        Gender(rawValue: String(substr))
    }
}

extension Optional where Wrapped == Gender {
    static let parser = Prefix(1).map { (substr: String.SubSequence) -> Gender? in
        Gender(rawValue: String(substr))
    }
}

enum Declension: Int, CustomStringConvertible {
    case first = 1,
         second,
         third,
         fourth,
         fifth
    
    var description: String {
        switch self {
        case .first: return "1st decl."
        case .second: return "2nd decl."
        case .third: return "3rd decl."
        case .fourth: return "4th decl."
        case .fifth: return "5th decl."
        }
    }

    static let parser = Prefix(1).compactMap { (substr: String.SubSequence) -> Declension? in
        guard let raw = Int(String(substr)),
              let decl = Declension(rawValue: raw) else {
                  return nil
              }
        return decl
    }
}

enum Conjugation: Int, CustomStringConvertible {
    case first = 1,
         second,
         third,
         fourth,
         fifth, // ??
         sixth // ??
    
    var description: String {
        switch self {
        case .first: return "1st conj."
        case .second: return "2nd conj."
        case .third: return "3rd conj."
        case .fourth: return "4th conj."
        case .fifth: return "5th conj."
        case .sixth: return "6th conj."
        }
    }

    static let parser = Prefix(1).compactMap { (substr: String.SubSequence) -> Conjugation? in
        guard let raw = Int(String(substr)),
              let conj = Conjugation(rawValue: raw) else {
                  return nil
              }
        return conj
    }
}

enum Case: String, CustomStringConvertible {
    case nominative = "NOM"
    case accusative = "ACC"
    case ablative = "ABL"
    case dative = "DAT"
    case genitive = "GEN"
    case locative = "LOC"
    case vocative = "VOC"

    var description: String {
        switch self {
        case .nominative:
            return "nom."
        case .accusative:
            return "acc."
        case .ablative:
            return "abl."
        case .dative:
            return "dat."
        case .genitive:
            return "gen."
        case .locative:
            return "loc."
        case .vocative:
            return "voc."
        }
    }

    static let parser = Prefix(3).compactMap { (substr: String.SubSequence) -> Case? in
        guard let decl = Case(rawValue: String(substr)) else {
            return nil
        }
        return decl
    }
}

private func notLineEnding(_ c: UTF8.CodeUnit) -> Bool {
    c != .init(ascii: "\r") && c != .init(ascii: "\n")
}

struct Definition: Equatable, Identifiable {
    var id: String {
        return expansion.principleParts + expansion.pos.description
    }

    internal init(possibilities: [Possibility], expansion: Expansion, meaning: String, truncated: Bool = false) {
        self.possibilities = possibilities
        self.expansion = expansion
        self.meaning = meaning
        self.truncated = truncated
    }
    
    let possibilities: [Possibility]
    let expansion: Expansion
    let meaning: String
    // Whether or not extra unlikely possibilities were excluded from the list of results.
    let truncated: Bool
}

enum Expansion: Equatable {
    case noun(String, Declension, Gender)
    case adj(String)
    case adv(String)
    case verb(String, Conjugation?)
    
    var principleParts: String {
        switch self {
        case .noun(let pp, _, _), .verb(let pp, _), .adj(let pp), .adv(let pp): return pp
        }
    }
    
    var pos: PartOfSpeech {
        switch self {
        case .noun: return .noun
        case .verb: return .verb
        case .adj: return .adjective
        case .adv: return .adverb
        }
    }
}

enum Number: String, CaseIterable, CustomStringConvertible, Parseable {
    case singular = "S"
    case plural = "P"

    var description: String {
        switch self {
        case .singular:
            return "sing."
        case .plural:
            return "pl."
        }
    }
}

// A fully declined instance of a noun
struct Noun: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
    let text: String
    let declension: Declension
    let variety: Int
    let `case`: Case
    let number: Number
    let gender: Gender

    var debugDescription: String {
        "Noun: \(text), \(declension), \(variety), \(`case`), \(number), \(gender)"
    }

    var description: String {
        "\(`case`) \(number)"
    }
}

enum Degree: String, CustomStringConvertible {
    case positive = "POS"
    case comparative = "COMP"
    case superlative = "SUPER"

    var description: String {
        switch self {
        case .positive: return "pos."
        case .comparative: return "comp."
        case .superlative: return "super."
        }
    }

    static let parser = Prefix(5).compactMap { (substr: String.SubSequence) -> Degree? in
        Degree(rawValue: substr.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct Adjective: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
    let text: String
    let declension: Declension
    let variety: Int
    let `case`: Case
    let number: Number
    let gender: Gender?
    let degree: Degree

    var debugDescription: String {
        "Adjective: \(text), \(declension), \(variety), \(`case`), \(number), \(String(describing: gender)), \(degree)"
    }

    var description: String {
        "\(declension) \(`case`) \(number) \(gender?.description.appending(" ") ?? "")\(degree)"
    }
}

struct Adverb: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
    let text: String
    let degree: Degree

    var debugDescription: String {
        "Adverb: \(text) \(degree)"
    }

    var description: String {
        "\(degree)"
    }
}

protocol Parseable: CaseIterable, RawRepresentable {
    static var parser: AnyParser<String.SubSequence, Self> { get }
}

extension Parseable where RawValue == Int {
    static var parser: AnyParser<String.SubSequence, Self> {
        Prefix(1).compactMap { (substr: String.SubSequence) -> Self? in
            guard let raw = Int(String(substr)),
                  let value = Self.init(rawValue: raw) else {
                      return nil
                  }
            return value
        }.eraseToAnyParser()
    }
}

extension Optional where Wrapped: RawRepresentable, Wrapped.RawValue == Int {
    static var parser: AnyParser<String.SubSequence, Self> {
        Prefix(1).map { (substr: String.SubSequence) -> Self in
            guard let raw = Int(String(substr)),
                  let value = Wrapped.init(rawValue: raw) else {
                      return nil
                  }
            return value
        }.eraseToAnyParser()
    }
}

extension Parseable where RawValue == String {
    static var parser: AnyParser<String.SubSequence, Self> {
        let max = allCases.reduce(0) { partialResult, element in
            element.rawValue.count > partialResult ? element.rawValue.count : partialResult
        }
        return Prefix(max).compactMap { (substr: String.SubSequence) -> Self? in
            Self.init(rawValue: substr.trimmingCharacters(in: .whitespacesAndNewlines))
        }.eraseToAnyParser()
    }
}

extension Optional where Wrapped: RawRepresentable, Wrapped: CaseIterable, Wrapped.RawValue == String {
    static var parser: AnyParser<String.SubSequence, Self> {
        let max = Wrapped.allCases.reduce(0) { partialResult, element in
            element.rawValue.count > partialResult ? element.rawValue.count : partialResult
        }
        return Prefix(max).map { (substr: String.SubSequence) -> Self in
            Wrapped.init(rawValue: substr.trimmingCharacters(in: .whitespacesAndNewlines))
        }.eraseToAnyParser()
    }
}

enum Tense: String, CustomStringConvertible {
    case present = "PRES"
    case imperfect = "IMPF"
    case future = "FUT"
    case perfect = "PERF"
    case pluperfect = "PLUP"
    case futurePerfect = "FUTP"

    var description: String {
        switch self {
        case .present:
            return "pres."
        case .imperfect:
            return "impf."
        case .future:
            return "fut."
        case .perfect:
            return "perf."
        case .pluperfect:
            return "plup."
        case .futurePerfect:
            return "fut. perf."
        }
    }

    static let parser = Prefix(4).compactMap { (substr: String.SubSequence) -> Tense? in
        Tense(rawValue: substr.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

enum Voice: String, CustomStringConvertible, Parseable {
    case active = "ACTIVE"
    case passive = "PASSIVE"
    case middle = "MIDDLE" // ? do we need this ?

    var description: String {
        switch self {
        case .active:
            return "active"
        case .passive:
            return "passive"
        case .middle:
            return "middle"
        }
    }
}

enum Mood: String, CustomStringConvertible, Parseable {
    case indicative = "IND"
    case infinitive = "INF"
    case subjunctive = "SUB"
    case imperative = "IMP"

    var description: String {
        switch self {
        case .indicative:
            return "ind."
        case .infinitive:
            return "inf."
        case .subjunctive:
            return "sub."
        case .imperative:
            return "imp."
        }
    }
}

enum Person: Int, CustomStringConvertible, Parseable {
    case first = 1
    case second = 2
    case third = 3

    var description: String {
        switch self {
        case .first:
            return "1st person"
        case .second:
            return "2nd person"
        case .third:
            return "3rd person"
        }
    }
}

// TODO: create a protocol for more DRY
struct Verb: Equatable, CustomDebugStringConvertible, CustomStringConvertible {
    let text: String
    let conjugation: Conjugation
    let variety: Int
    let tense: Tense
    let voice: Voice
    let mood: Mood
    let person: Person?
    let number: Number?

    var debugDescription: String {
        "Verb: \(text) \(conjugation) \(variety) \(tense) \(voice) \(mood) \(person) \(number)"
    }

    var description: String {
        "\(conjugation) \(tense) \(voice) \(mood) \(person?.description.appending(" ") ?? "")\(number?.description ?? "")"
    }
}

enum Possibility: Equatable, CustomDebugStringConvertible {
    case noun(Noun)
    case adjective(Adjective)
    case adverb(Adverb)
    case verb(Verb)

    var debugDescription: String {
        switch self {
        case .noun(let noun):
            return noun.debugDescription
        case .adjective(let adj):
            return adj.debugDescription
        case .adverb(let adv):
            return adv.debugDescription
        case .verb(let verb):
            return verb.debugDescription
        }
    }

    var word: String {
        switch self {
        case .noun(let noun):
            return noun.text
        case .adjective(let adj):
            return adj.text
        case .adverb(let adv):
            return adv.text
        case .verb(let verb):
            return verb.text
        }
    }

    var description: String {
        switch self {
        case .noun(let noun):
            return noun.description
        case .adjective(let adj):
            return adj.description
        case .adverb(let adv):
            return adv.description
        case .verb(let verb):
            return verb.description
        }
    }
}

let principleParts = PrefixUpTo("  ").map(String.init(_:))

let nounExpansion = principleParts
    .skip(StartsWith("  "))
    .skip(StartsWith(PartOfSpeech.noun.rawValue))
    .skip(StartsWith(" ("))
    .take(Declension.parser)
    .skip(Prefix(2))
    .skip(StartsWith(") "))
    .take(Gender.parser)
    .skip(Rest())
    .map(Expansion.noun)
    .eraseToAnyParser()

let adjExpansion = principleParts
    .skip(StartsWith("  "))
    .skip(StartsWith(PartOfSpeech.adjective.rawValue))
    .skip(Rest())
    .map(Expansion.adj)
    .eraseToAnyParser()

let advExpansion = principleParts
    .skip(StartsWith("  "))
    .skip(StartsWith(PartOfSpeech.adverb.rawValue))
    .skip(Rest())
    .map(Expansion.adv)
    .eraseToAnyParser()

let verbExpansion = principleParts
    .skip(StartsWith("  "))
    .skip(StartsWith(PartOfSpeech.verb.rawValue))
    .take(StartsWith(" (")
            .take(Conjugation?.parser)
            .skip(Prefix(2))
            .skip(StartsWith(") "))
            .orElse(Skip(Rest()).map { Conjugation?.none }))
    .map(Expansion.verb)
    .eraseToAnyParser()

let expansion = OneOfMany([nounExpansion, adjExpansion, advExpansion, verbExpansion])

// Parses a string with a given total length N. First M characters <= N must be non-whitespace, and
// will be returned.
struct Padded<Input>: Parser where Input: Collection,
                                   Input.SubSequence == Input,
                                   Input.Element == UTF8.CodeUnit {
    let length: Int

    func parse(_ input: inout Input) -> Input? {
        guard input.count >= length else { return nil }

        for i in input.indices {
            let c = Character(Unicode.Scalar(input[i]))
            guard input.distance(from: input.startIndex, to: i) > 0 || !c.isWhitespace else {
                return nil
            }
            if c.isWhitespace {
                return input[...i]
            }
        }
        return input
    }
}

let variety = Prefix<Substring>(1).map(String.init(_:)).compactMap(Int.init(_:))

let nounPossibility = Prefix<Substring>(21).map {
        $0.trimmingCharacters(in: .whitespaces)
    }
    .skip(StartsWith("N      "))
    .take(Declension.parser)
    .skip(StartsWith(" "))
    .take(variety)
    .skip(StartsWith(" "))
    .take(Case.parser)
    .skip(StartsWith(" "))
    .take(Number.parser)
    .skip(StartsWith(" "))
    .take(Gender.parser)
    .skip(Rest())
    .map {
        ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.0.4, $0.1)
    }
    .map(Noun.init)
    .map(Possibility.noun)
    .eraseToAnyParser()

let adjPossibility = Prefix<Substring>(21)
    .map {
        $0.trimmingCharacters(in: .whitespaces)
    }
    .skip(StartsWith("ADJ    "))
    .take(Declension.parser)
    .skip(StartsWith(" "))
    .take(variety)
    .skip(StartsWith(" "))
    .take(Case.parser)
    .skip(StartsWith(" "))
    .take(Number.parser)
    .skip(StartsWith(" "))
    .take(Gender?.parser)
    .skip(StartsWith(" "))
    .take(Degree.parser)
    .skip(Rest())
    .map {
        ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.0.4, $0.1, $0.2)
    }
    .map(Adjective.init)
    .map(Possibility.adjective)
    .eraseToAnyParser()

let advPossibility = Prefix<Substring>(21)
    .map {
        $0.trimmingCharacters(in: .whitespaces)
    }
    .skip(StartsWith("ADV    "))
    .take(Degree.parser)
    .skip(Rest())
    .map {
        ($0.0, $0.1)
    }
    .map(Adverb.init)
    .map(Possibility.adverb)
    .eraseToAnyParser()

// ambulav.issem        V      1 1 PLUP ACTIVE  SUB 1 S
let verbPossibility: AnyParser<Substring, Possibility> = Prefix<Substring>(21)
    .map {
        $0.trimmingCharacters(in: .whitespaces)
    }
    .skip(StartsWith("V      "))
    .take(Conjugation.parser)
    .skip(StartsWith(" "))
    .take(variety)
    .skip(StartsWith(" "))
    .take(Tense.parser)
    .skip(StartsWith(" "))
    .take(Voice.parser)
    .skip(StartsWith(" "))
    .take(Mood.parser)
    .skip(StartsWith(" "))
    .take(Person?.parser)
    .skip(StartsWith(" "))
    .take(Number?.parser)
    .skip(Rest())
    .map {
        Verb(text: $0.0.0, conjugation: $0.0.1, variety: $0.0.2, tense: $0.0.3, voice: $0.0.4, mood: $0.1, person: $0.2, number: $0.3)
    }
    .map(Possibility.verb)
    .eraseToAnyParser()

let possibility = OneOfMany([nounPossibility, adjPossibility, advPossibility, verbPossibility])

func parse(_ str: String) -> ([Definition], Bool)? {
    var definitions: [Definition] = []
    var lines = str
        .split(whereSeparator: \.isNewline)
        .makeIterator()

    var truncated = false

    var possibilities: [Possibility] = []
    var exp: Expansion? = nil
    var meaning: String? = nil
    let appendNewDefinition = {
        guard let e = exp, let m = meaning else { return }
        definitions.append(.init(possibilities: possibilities,
                                 expansion: e,
                                 meaning: m))
        possibilities = []
        exp = nil
        meaning = nil
    }
    while let line = lines.next() {
        if let p = possibility.parse(line) {
            appendNewDefinition()
            possibilities.append(p)
        } else if let e = expansion.parse(line) {
            if exp == nil {
                exp = e
            } else {
                appendNewDefinition()
                exp = e
            }
        } else if exp != nil {
            if line == "*" {
                truncated = true
            } else if meaning == nil {
                meaning = String(line)
            } else {
                meaning! += "\n\(line)"
            }
        } else {
            return nil
        }
    }

    appendNewDefinition()

    return (definitions, truncated)
}

//func parse(_ str: String) -> Definition? {
//    let lines = str.split(whereSeparator: \.isNewline)
//    let possibilities = lines.lazy
//        .prefix { substr in
//            substr.count == 56 && !substr.contains("]")
//        }
//        .compactMap(possibility.parse)
//    let rest = lines[possibilities.count...].joined(separator: "\n")
//    guard let (expansion, meaning) = result.parse(rest) else {
//        return nil
//    }
//    return Definition(
//        possibilities: Array(possibilities.map { "\($0)" }),
//        expansion: expansion,
//        meaning: meaning.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: ["*"]),
//        truncated: meaning.last == "*"
//    )
//}
