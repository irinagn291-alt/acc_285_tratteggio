import Foundation

/// Role: Work. One saved painting in the crate. LoupeFold is the algebraic case. objectid is the duplicate key.
struct Work: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var objectID: Int
    var accession: String
    var maker: String
    var title: String
    var imageUUID: String?
    var iiifURLString: String?
    var daykey: Int
    var fold: LoupeFold

    var thumbURL: URL? {
        CatalogClient.thumbURL(imageUUID: imageUUID, iiifURLString: iiifURLString)
    }

    static func shut(
        from row: CatalogRow,
        id: UUID = UUID(),
        daykey: Int
    ) -> Work {
        Work(
            id: id,
            objectID: row.objectID,
            accession: row.accession,
            maker: row.maker,
            title: row.title,
            imageUUID: row.imageUUID,
            iiifURLString: row.iiifURLString,
            daykey: daykey,
            fold: .shut
        )
    }
}

/// Role: Work. Catalog row before it is crated Shut. Cached so empty or failed NGA search still frames from the shelf.
struct CatalogRow: Identifiable, Equatable, Sendable, Codable {
    var objectID: Int
    var accession: String
    var maker: String
    var title: String
    var imageUUID: String?
    var iiifURLString: String?

    var id: Int { objectID }

    var thumbURL: URL? {
        CatalogClient.thumbURL(imageUUID: imageUUID, iiifURLString: iiifURLString)
    }

    var hasUsableImage: Bool {
        thumbURL != nil
    }
}
