import Foundation

/// Role: Work. Bundled crate shelf. Empty or failed National Gallery of Art search frames from here. Not a food catalog.
struct CrateShelf: Sendable {
    var rows: [CatalogRow]

    static let bundled = CrateShelf(rows: Self.makeRows())

    private static let catalog: [(Int, String, String, String, String)] = [
        (61379, "1983.1.29", "Claude Monet", "Woman with a Parasol - Madame Monet and Her Son", "a9994488-f9c2-4128-9ba4-37ec9a3f1bdc"),
        (46681, "1963.10.206", "Auguste Renoir", "A Girl with a Watering Can", "c958f518-171b-407e-af04-3a6beee3e757"),
        (46569, "1963.10.94", "Mary Cassatt", "The Boating Party", "f24d0c57-5e08-463c-9703-ac7fe904487d"),
        (50724, "1967.6.1.a", "Leonardo da Vinci", "Ginevra de' Benci [obverse]", "79160f14-05cb-46d2-8241-4c9f6aacb81d"),
        (12198, "1943.6.2", "James McNeill Whistler", "Symphony in White, No. 1: The White Girl", "fac977f2-c080-4ecb-9f8b-9616011ddc07"),
        (43624, "1956.10.1", "Edouard Manet", "The Railway", "0568b3c5-5ab6-4c73-9efb-fe02bfdb2cbf"),
        (30228, "1943.13.1", "Winslow Homer", "Breezing Up (A Fair Wind)", "df85093f-bc82-4e08-b13e-a60710af1734"),
        (46471, "1963.6.1", "John Singleton Copley", "Watson and the Shark", "eeff4dd6-9cec-4ff7-9184-ea12180d6285"),
        (52178, "1970.17.34", "Vincent van Gogh", "Farmhouse in Provence", "a1ad50b0-6e00-4878-8a7c-ef1786b3a020"),
        (39729, "1950.18.1", "Gilbert Stuart", "The Skater (Portrait of William Grant)", "efa6226d-3ca8-4d01-9458-89f4fff4d8bb"),
    ]

    private static func makeRows() -> [CatalogRow] {
        catalog.map { objectID, accession, maker, title, imageUUID in
            CatalogRow(
                objectID: objectID,
                accession: accession,
                maker: maker,
                title: title,
                imageUUID: imageUUID,
                iiifURLString: "https://api.nga.gov/iiif/\(imageUUID)"
            )
        }
    }
}
