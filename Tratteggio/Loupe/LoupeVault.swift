import Foundation

/// Role: Loupe. Projects Loupe to UserDefaults ttg.loupe.v1 plus an atomic Application Support file. Views never touch this type.
actor LoupeVault {
    private let directory: URL
    private let suiteName: String?
    private let fileManager: FileManager

    init(
        directory: URL,
        suiteName: String? = nil,
        fileManager: FileManager = .default
    ) {
        self.directory = directory
        self.suiteName = suiteName
        self.fileManager = fileManager
    }

    nonisolated static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Tratteggio", isDirectory: true)
    }

    func load() -> (loupe: Loupe, warning: LoupeWarning?) {
        if let loupe = decode(defaults().data(forKey: LoupeKey.snapshot)) {
            return (loupe, nil)
        }
        if let loupe = decode(read(fileURL)) {
            return (loupe, nil)
        }
        if let loupe = decode(defaults().data(forKey: LoupeKey.backup)) {
            return (loupe, .recoveredFromBackup)
        }
        if let loupe = decode(read(backupURL)) {
            return (loupe, .recoveredFromBackup)
        }
        let hadPayload = defaults().data(forKey: LoupeKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        return (.empty, hadPayload ? .startedEmpty : nil)
    }

    func save(_ loupe: Loupe) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try LoupeDocument.encode(loupe)
        let box = defaults()
        if let current = box.data(forKey: LoupeKey.snapshot) {
            box.set(current, forKey: LoupeKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        box.set(data, forKey: LoupeKey.snapshot)
        try data.write(to: fileURL, options: .atomic)
        excludeCacheIfPresent()
    }

    func wipe() throws {
        let box = defaults()
        box.removeObject(forKey: LoupeKey.snapshot)
        box.removeObject(forKey: LoupeKey.backup)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        if fileManager.fileExists(atPath: cacheURL.path) {
            try fileManager.removeItem(at: cacheURL)
        }
    }

    func demoPlanted() -> Bool {
        defaults().object(forKey: LoupeKey.demo) != nil
    }

    func markDemoPlanted() {
        defaults().set(true, forKey: LoupeKey.demo)
    }

    private func decode(_ data: Data?) -> Loupe? {
        guard let data else { return nil }
        return try? LoupeDocument.decode(data)
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("loupe.json", isDirectory: false)
    }

    private var backupURL: URL {
        directory.appendingPathComponent("loupe.json.backup", isDirectory: false)
    }

    private var cacheURL: URL {
        directory.appendingPathComponent("catalog-cache.json", isDirectory: false)
    }

    private func excludeCacheIfPresent() {
        guard fileManager.fileExists(atPath: cacheURL.path) else { return }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = cacheURL
        try? url.setResourceValues(values)
    }

    private func defaults() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }
}
