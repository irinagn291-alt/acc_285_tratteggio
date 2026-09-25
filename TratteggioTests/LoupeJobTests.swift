import XCTest
@testable import Tratteggio

final class LoupeJobTests: XCTestCase {
    func test_customSchemeRoutesFourDestinationsAndFrame() throws {
        XCTAssertEqual(LoupeJob.parse(try url("tratteggio://quiz")), .quiz)
        XCTAssertEqual(LoupeJob.parse(try url("tratteggio://explore")), .explore)
        XCTAssertEqual(LoupeJob.parse(try url("tratteggio://saved")), .saved)
        XCTAssertEqual(LoupeJob.parse(try url("tratteggio://settings")), .settings)
        XCTAssertEqual(LoupeJob.parse(try url("tratteggio://frame")), .frame)
        XCTAssertEqual(LoupeJob.parse(try url("tratteggio://patch")), .patchGuide)
        XCTAssertNil(LoupeJob.parse(try url("tratteggio://game")))
        XCTAssertNotEqual(LoupeJob.quiz.cover, LoupeJob.explore.cover)
        XCTAssertNotEqual(LoupeJob.explore.cover, LoupeJob.saved.cover)
        XCTAssertNotEqual(LoupeJob.saved.cover, LoupeJob.settings.cover)
        XCTAssertNil(LoupeJob.quiz.cover)
        XCTAssertNil(LoupeJob.frame.cover)
        XCTAssertEqual(LoupeJob.explore.cover, .explore)
        XCTAssertEqual(LoupeJob.saved.cover, .saved)
        XCTAssertEqual(LoupeJob.settings.cover, .settings)
        XCTAssertEqual(Set(LoupeSheet.allCases.map(\.rawValue)).count, 4)
    }

    func test_httpsHostMapsPathsAndContact() throws {
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro")), .quiz)
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro/")), .quiz)
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro/explore")), .explore)
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro/saved")), .saved)
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro/settings")), .settings)
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro/contact-us")), .settings)
        XCTAssertEqual(LoupeJob.parse(try url("https://tratteggio-loupe.pro/frame")), .frame)
        XCTAssertNil(LoupeJob.parse(try url("https://example.com/explore")))
    }

    func test_copyNamesTheJobWithoutAxisStrings() {
        XCTAssertEqual(LoupeCopy.jobName, "Patch the shard.")
        XCTAssertEqual(LoupeCopy.muteHeadline, "Crate empty.")
        XCTAssertEqual(LoupeCopy.muteLine, "Save a work, then patch.")
        XCTAssertEqual(LoupeCopy.nextTap(sign: .mute), LoupeCopy.muteLine)
        XCTAssertEqual(LoupeCopy.nextTap(sign: .shut), "Frame a crop.")
        XCTAssertEqual(LoupeCopy.nextTap(sign: .framed), "Tap the missing word.")
        XCTAssertEqual(LoupeCopy.nextTap(sign: .smudge), "Tap the missing word.")
        XCTAssertEqual(LoupeCopy.nextTap(sign: .restored), "Frame another crop.")
        XCTAssertFalse(LoupeCopy.jobName.contains("SwiftUI"))
        XCTAssertFalse(LoupeCopy.jobName.contains("Loupe ADT"))
        XCTAssertEqual(LoupeCopy.fault(LoupeFault.patchOnShut), "Frame a crop first.")
        XCTAssertEqual(LoupeFigures.whole(2).isEmpty, false)
        XCTAssertEqual(LoupeSignInk.stamp(.framed), "FRAMED")
        XCTAssertEqual(LoupeSignInk.stamp(.mute), "MUTE")
    }

    func test_reviewHookSheetsStayDistinct() {
        XCTAssertEqual(ReviewHook.today.sheet, .quiz)
        XCTAssertEqual(ReviewHook.log.sheet, .saved)
        XCTAssertEqual(ReviewHook.goals.sheet, .settings)
        XCTAssertEqual(ReviewHook.explore.sheet, .explore)
        var chrome = CoverProbe()
        chrome.apply(.quiz)
        XCTAssertNil(chrome.cover)
        chrome.apply(.saved)
        XCTAssertEqual(chrome.cover, .saved)
        chrome.apply(.settings)
        XCTAssertEqual(chrome.cover, .settings)
        chrome.apply(.explore)
        XCTAssertEqual(chrome.cover, .explore)
    }

    private func url(_ raw: String) throws -> URL {
        try XCTUnwrap(URL(string: raw))
    }
}

private struct CoverProbe {
    var cover: LoupeCover?

    mutating func apply(_ sheet: LoupeSheet) {
        switch sheet {
        case .quiz: cover = nil
        case .explore: cover = .explore
        case .saved: cover = .saved
        case .settings: cover = .settings
        }
    }
}
