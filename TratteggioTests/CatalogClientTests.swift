import XCTest
@testable import Tratteggio

final class CatalogClientTests: XCTestCase {
    func testCgiSearchPlMapsOntoNgaKeywordPagePageSize() throws {
        let page2 = CatalogClient.searchRequest(query: "monet", page: 2, pageSize: 8)
        let url = try XCTUnwrap(page2.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let keyed = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        XCTAssertEqual(url.host, "www.nga.gov")
        XCTAssertEqual(url.path, "/bin/ngaweb/collection-search-result.json")
        XCTAssertEqual(keyed["keyword"], "monet")
        XCTAssertEqual(keyed["page"], "2")
        XCTAssertEqual(keyed["pageSize"], "8")
        XCTAssertNil(keyed["q"])
        XCTAssertNil(keyed["search_terms"])
        XCTAssertNil(keyed["page_size"])
        XCTAssertFalse(url.absoluteString.contains("openfoodfacts"))
        XCTAssertFalse(url.absoluteString.contains("cgi/search.pl"))
        XCTAssertFalse(url.absoluteString.contains("api.artic.edu"))
        XCTAssertFalse(url.absoluteString.contains("collectionapi.metmuseum.org"))
        XCTAssertFalse(url.absoluteString.contains("clevelandart.org"))
        XCTAssertFalse(url.absoluteString.contains("rijksmuseum"))
        XCTAssertEqual(page2.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(page2.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(page2.timeoutInterval, 15)
        XCTAssertEqual(CatalogClient.userAgent, "Tratteggio/1.0 (iOS; +https://tratteggio-loupe.pro)")

        let fromUUID = try XCTUnwrap(
            CatalogClient.thumbURL(
                imageUUID: "a9994488-f9c2-4128-9ba4-37ec9a3f1bdc",
                iiifURLString: nil
            )
        )
        XCTAssertEqual(fromUUID.host, "api.nga.gov")
        XCTAssertTrue(fromUUID.path.contains("/iiif/a9994488-f9c2-4128-9ba4-37ec9a3f1bdc/full/!400,400/0/default.jpg"))
    }

    func testDTOMapsNGAFieldsThenDomainRow() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((NgaFixtures.searchJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "monet", page: 1)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.objectID, 61379)
        XCTAssertEqual(row.accession, "1983.1.29")
        XCTAssertEqual(row.maker, "Claude Monet")
        XCTAssertEqual(row.title, "Woman with a Parasol - Madame Monet and Her Son")
        XCTAssertEqual(row.imageUUID, "a9994488-f9c2-4128-9ba4-37ec9a3f1bdc")
        XCTAssertNotNil(row.thumbURL)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func testPrefersRowsWithUsableImage() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((NgaFixtures.mixedJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "cassatt")
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.objectID, 46569)
        XCTAssertNotNil(rows.first?.thumbURL)
    }

    func testTransientTransportRetriesOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((NgaFixtures.searchJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "monet")
        XCTAssertEqual(rows.count, 1)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func testServerErrorRetriesOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), NgaFixtures.response(NgaFixtures.url, 503))),
            .success((NgaFixtures.searchJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "monet")
        XCTAssertEqual(rows.count, 1)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func testDoesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), NgaFixtures.response(NgaFixtures.url, 404))),
            .success((NgaFixtures.searchJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        do {
            _ = try await client.search(query: "monet")
            XCTFail("expected missing")
        } catch {
            XCTAssertEqual(error as? CatalogFault, .missing)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func testMalformedJSONIsHandled() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("not-json".utf8), NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        do {
            _ = try await client.search(query: "monet")
            XCTFail("malformed")
        } catch {
            XCTAssertEqual(error as? CatalogFault, .malformed)
        }
    }

    func testDoesNotRetryClientError() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), NgaFixtures.response(NgaFixtures.url, 400))),
            .success((NgaFixtures.searchJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        do {
            _ = try await client.search(query: "monet")
            XCTFail("expected transport")
        } catch {
            XCTAssertEqual(error as? CatalogFault, .transport)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func testEmptyQueryDoesNotHitNetwork() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((NgaFixtures.searchJSON, NgaFixtures.response(NgaFixtures.url, 200))),
        ])
        let client = CatalogClient(carrier: carrier)
        let rows = try await client.search(query: "   ")
        XCTAssertTrue(rows.isEmpty)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 0)
    }
}

private actor ScriptedCarrier: CatalogCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

enum NgaFixtures {
    static let url = URL(string: "https://www.nga.gov/bin/ngaweb/collection-search-result.json")!

    static let searchJSON = Data(
        """
        {"results":[{"objectid":61379,"title":"Woman with a Parasol - Madame Monet and Her Son","attribution":"Claude Monet","accessionnumber":"1983.1.29","imageuuid":"a9994488-f9c2-4128-9ba4-37ec9a3f1bdc"}]}
        """.utf8
    )

    static let mixedJSON = Data(
        """
        {"results":[{"objectid":1,"title":"Held Back","attribution":"Held Maker","accessionnumber":"1999.1"},{"objectid":46569,"title":"The Boating Party","attribution":"Mary Cassatt","accessionnumber":"1963.10.94","imageuuid":"f24d0c57-5e08-463c-9703-ac7fe904487d"}]}
        """.utf8
    )

    static func response(_ url: URL, _ code: Int) -> URLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
    }
}
