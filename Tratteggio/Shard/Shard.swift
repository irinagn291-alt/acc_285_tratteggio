import Foundation

/// Role: Shard. Magnified crop of a saved work. Frame writes this crop when Shut folds to Framed.
struct Shard: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var objectID: Int
    var imageUUID: String?
    var iiifURLString: String?
    var originX: Double
    var originY: Double
    var width: Double
    var height: Double

    var thumbURL: URL? {
        CatalogClient.thumbURL(imageUUID: imageUUID, iiifURLString: iiifURLString)
    }

    static func crop(work: Work, id: UUID = UUID()) -> Shard {
        let salt = abs(work.objectID)
        let originX = Double((salt % 37) + 6) / 100.0
        let originY = Double(((salt / 11) % 37) + 6) / 100.0
        return Shard(
            id: id,
            workID: work.id,
            objectID: work.objectID,
            imageUUID: work.imageUUID,
            iiifURLString: work.iiifURLString,
            originX: min(originX, 0.44),
            originY: min(originY, 0.44),
            width: 0.48,
            height: 0.48
        )
    }
}
