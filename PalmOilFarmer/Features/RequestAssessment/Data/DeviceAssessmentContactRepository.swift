import Foundation

struct DeviceAssessmentContactRepository: AssessmentContactRepository {
    private let fileURL: URL

    init(fileURL: URL = URL.applicationSupportDirectory
        .appending(path: "RequestAssessment", directoryHint: .isDirectory)
        .appending(path: "contacts.json", directoryHint: .notDirectory)) {
        self.fileURL = fileURL
    }

    func loadContacts() throws -> [ReviewContactDetails] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([ReviewContactDetails].self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }
    }

    func save(_ contact: ReviewContactDetails) throws -> [ReviewContactDetails] {
        var contacts = try loadContacts()
        guard !contacts.contains(contact) else { return contacts }
        contacts.append(contact)
        try write(contacts)
        return contacts
    }

    func update(_ original: ReviewContactDetails, to contact: ReviewContactDetails) throws -> [ReviewContactDetails] {
        var contacts = try loadContacts()
        guard let index = contacts.firstIndex(of: original) else {
            throw UpdateError.missingContact
        }
        guard contact != original else { return contacts }
        guard !contacts.contains(contact) else { throw UpdateError.duplicateContact }
        contacts[index] = contact
        try write(contacts)
        return contacts
    }

    func delete(_ contact: ReviewContactDetails) throws -> [ReviewContactDetails] {
        var contacts = try loadContacts()
        guard let index = contacts.firstIndex(of: contact) else { return contacts }
        contacts.remove(at: index)
        try write(contacts)
        return contacts
    }

    private enum UpdateError: LocalizedError {
        case missingContact, duplicateContact

        var errorDescription: String? {
            switch self {
            case .missingContact: "Narahubung ini sudah berubah. Buka kembali pengajuan."
            case .duplicateContact: "Narahubung dengan data ini sudah tersimpan."
            }
        }
    }

    private func write(_ contacts: [ReviewContactDetails]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(contacts)
        #if os(iOS)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: fileURL, options: .atomic)
        #endif
    }
}
