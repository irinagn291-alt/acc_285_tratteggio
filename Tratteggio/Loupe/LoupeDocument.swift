import Foundation

/// Role: Loupe. Preference keys. Snapshot is JSON Data under ttg.loupe.v1. Demo is Simulator only.
enum LoupeKey {
    static let snapshot = "ttg.loupe.v1"
    static let backup = "ttg.loupe.v1.backup"
    static let demo = "ttg.demo.v1"
}

enum LoupeCodecError: Error, Equatable, Sendable {
    case unsupportedSchema(Int)
    case corrupt
}

/// Role: Loupe. Codable LoupeDocument. schemaVersion from 1. Fold case is stored. Restored-ness is not a parallel bool. Mute is a loupe write.
enum LoupeDocument {
    static func encode(_ loupe: Loupe) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var copy = loupe
        copy.schemaVersion = Loupe.currentSchema
        return try encoder.encode(RootFile(loupe: copy))
    }

    static func decode(_ data: Data) throws -> Loupe {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw LoupeCodecError.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var loupe = try decoder.decode(RootFile.self, from: data).loupe
                loupe.schemaVersion = Loupe.currentSchema
                return loupe
            } catch let error as LoupeCodecError {
                throw error
            } catch {
                throw LoupeCodecError.corrupt
            }
        default:
            throw LoupeCodecError.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}

private struct RootFile: Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var card: FramedCard?
    var patchMarks: [PatchMark]
    var smudgeMarks: [SmudgeMark]
    var markLog: [MarkRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?
    var mute: Bool

    init(loupe: Loupe) {
        schemaVersion = loupe.schemaVersion
        onboardingComplete = loupe.onboardingComplete
        works = loupe.works
        card = loupe.card
        patchMarks = loupe.patchMarks
        smudgeMarks = loupe.smudgeMarks
        markLog = loupe.markLog
        cachedRows = loupe.cachedRows
        focusedWorkID = loupe.focusedWorkID
        mute = loupe.mute
    }

    var loupe: Loupe {
        Loupe(
            schemaVersion: schemaVersion,
            onboardingComplete: onboardingComplete,
            works: works,
            card: card,
            patchMarks: patchMarks,
            smudgeMarks: smudgeMarks,
            markLog: markLog,
            cachedRows: cachedRows,
            focusedWorkID: focusedWorkID,
            mute: mute
        )
    }
}
