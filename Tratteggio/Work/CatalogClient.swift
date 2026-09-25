import Foundation

/// Role: Work. Typed transport failures. DTO decode never crashes the loupe.
enum CatalogFault: Error, Equatable, Sendable {
    case cancelled
    case missing
    case transport
    case malformed
}

/// Role: Work. One HTTP hop. Injected so tests never leave the process.
protocol CatalogCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Work. URLSession hop, 15 s timeout, app User-Agent on every request.
struct CatalogSession: CatalogCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = CatalogClient.timeout
        configuration.timeoutIntervalForResource = CatalogClient.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": CatalogClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

struct NgaSearchDTO: Decodable, Sendable {
    var artworks: [NgaArtworkDTO]

    private enum CodingKeys: String, CodingKey {
        case results
        case data
        case items
        case hits
        case artobjects
    }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([NgaArtworkDTO].self) {
            artworks = array
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let results = try container.decodeIfPresent([NgaArtworkDTO].self, forKey: .results) {
            artworks = results
        } else if let data = try container.decodeIfPresent([NgaArtworkDTO].self, forKey: .data) {
            artworks = data
        } else if let items = try container.decodeIfPresent([NgaArtworkDTO].self, forKey: .items) {
            artworks = items
        } else if let hits = try container.decodeIfPresent([NgaArtworkDTO].self, forKey: .hits) {
            artworks = hits
        } else if let objects = try container.decodeIfPresent([NgaArtworkDTO].self, forKey: .artobjects) {
            artworks = objects
        } else if let single = try? NgaArtworkDTO(from: decoder) {
            artworks = [single]
        } else {
            artworks = []
        }
    }
}

struct NgaArtworkDTO: Decodable, Sendable {
    var objectid: Int?
    var title: String?
    var attribution: String?
    var accessionnumber: String?
    var imageuuid: String?
    var iiifurl: String?

    enum CodingKeys: String, CodingKey {
        case objectid
        case title
        case attribution
        case accessionnumber
        case accessionnum
        case imageuuid
        case uuid
        case iiifurl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        attribution = try container.decodeIfPresent(String.self, forKey: .attribution)
        accessionnumber = try container.decodeIfPresent(String.self, forKey: .accessionnumber)
            ?? (try container.decodeIfPresent(String.self, forKey: .accessionnum))
        imageuuid = try container.decodeIfPresent(String.self, forKey: .imageuuid)
            ?? (try container.decodeIfPresent(String.self, forKey: .uuid))
        iiifurl = try container.decodeIfPresent(String.self, forKey: .iiifurl)
        objectid = Self.decodeInt(container, key: .objectid)
    }

    func asRow() -> CatalogRow? {
        guard let objectID = objectid, objectID > 0 else { return nil }
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedMaker = attribution?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedTitle.isEmpty, !trimmedMaker.isEmpty else { return nil }
        let accession = (accessionnumber ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let imageUUID = imageuuid?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUUID = (imageUUID?.isEmpty == false) ? imageUUID : Self.uuidFromIIIF(iiifurl)
        let iiif = iiifurl?.trimmingCharacters(in: .whitespacesAndNewlines)
        return CatalogRow(
            objectID: objectID,
            accession: accession.isEmpty ? "nga-\(objectID)" : accession,
            maker: trimmedMaker,
            title: trimmedTitle,
            imageUUID: resolvedUUID,
            iiifURLString: (iiif?.isEmpty == false) ? iiif : nil
        )
    }

    private static func decodeInt(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let raw = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(raw)
        }
        return nil
    }

    private static func uuidFromIIIF(_ iiif: String?) -> String? {
        guard let iiif, !iiif.isEmpty else { return nil }
        let parts = iiif.split(separator: "/").map(String.init)
        guard let match = parts.first(where: { $0.count >= 32 && $0.contains("-") }) else {
            return parts.last.flatMap { $0.count >= 8 ? $0 : nil }
        }
        return match
    }
}

/// Role: Work. Owns National Gallery of Art search. cgi search pl maps to keyword, page, pageSize on collection-search-result.json. Never Open Food Facts. DTO then domain.
actor CatalogClient {
    static let userAgent = "Tratteggio/1.0 (iOS; +https://tratteggio-loupe.pro)"
    static let timeout: TimeInterval = 15
    static let searchHost = "www.nga.gov"
    static let searchPath = "/bin/ngaweb/collection-search-result.json"
    static let iiifHost = "api.nga.gov"
    static let contactURL = URL(string: "https://tratteggio-loupe.pro/contact-us")!
    static let ngaHomeURL = URL(string: "https://www.nga.gov")!
    static let ngaOpenAccessURL = URL(string: "https://www.nga.gov/open-access-images")!
    static let searchURL = URL(string: "https://www.nga.gov/bin/ngaweb/collection-search-result.json")!

    private let carrier: any CatalogCarrying
    private let decoder: JSONDecoder

    init(carrier: any CatalogCarrying) {
        self.carrier = carrier
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    init() {
        self.init(carrier: CatalogSession())
    }

    func search(query: String, page: Int = 1, pageSize: Int = 8) async throws -> [CatalogRow] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = Self.searchRequest(query: trimmed, page: page, pageSize: pageSize)
        let data = try await send(request)
        let dto: NgaSearchDTO
        do {
            dto = try decoder.decode(NgaSearchDTO.self, from: data)
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch {
            throw CatalogFault.malformed
        }
        var rows: [CatalogRow] = []
        var seen = Set<Int>()
        for artwork in dto.artworks {
            guard let row = artwork.asRow(), seen.insert(row.objectID).inserted else { continue }
            rows.append(row)
        }
        let preferred = rows.filter(\.hasUsableImage)
        return preferred.isEmpty ? rows : preferred
    }

    nonisolated static func searchRequest(query: String, page: Int = 1, pageSize: Int = 8) -> URLRequest {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = searchPath
        let size = min(max(pageSize, 1), 100)
        let pageIndex = max(page, 1)
        parts.queryItems = [
            URLQueryItem(name: "keyword", value: query),
            URLQueryItem(name: "page", value: String(pageIndex)),
            URLQueryItem(name: "pageSize", value: String(size)),
        ]
        var request = URLRequest(url: parts.url ?? searchURL, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    nonisolated static func objectPageURL(objectID: Int) -> URL {
        URL(string: "https://www.nga.gov/collection/art-object-page.\(objectID).html") ?? ngaHomeURL
    }

    nonisolated static func thumbURL(
        imageUUID: String?,
        iiifURLString: String?
    ) -> URL? {
        if let imageUUID, !imageUUID.isEmpty {
            var parts = URLComponents()
            parts.scheme = "https"
            parts.host = iiifHost
            parts.path = "/iiif/\(imageUUID)/full/!400,400/0/default.jpg"
            return parts.url
        }
        if let iiif = iiifURLString?.trimmingCharacters(in: .whitespacesAndNewlines), !iiif.isEmpty {
            return URL(string: iiif)
        }
        return nil
    }

    private func send(_ request: URLRequest, retry: Bool = true) async throws -> Data {
        do {
            try Task.checkCancellation()
            let (data, response) = try await carrier.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CatalogFault.transport
            }
            if http.statusCode == 404 {
                throw CatalogFault.missing
            }
            guard (200 ..< 300).contains(http.statusCode) else {
                if retry, http.statusCode >= 500 {
                    return try await send(request, retry: false)
                }
                throw CatalogFault.transport
            }
            return data
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault {
            throw fault
        } catch {
            if retry, Self.transient(error) {
                return try await send(request, retry: false)
            }
            throw CatalogFault.transport
        }
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }
}
