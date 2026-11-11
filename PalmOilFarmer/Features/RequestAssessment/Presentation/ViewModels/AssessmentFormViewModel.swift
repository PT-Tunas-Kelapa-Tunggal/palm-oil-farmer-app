import Foundation
import Observation

@MainActor
@Observable
final class AssessmentFormViewModel {
    var name = ""
    var phone = ""
    var address = ""
    private(set) var showsValidation = false

    init(contact: ReviewContactDetails? = nil) {
        name = contact?.name ?? ""
        phone = contact?.phone ?? ""
        address = contact?.address ?? ""
    }

    var nameError: String? {
        trimmed(name).isEmpty ? "Masukkan nama lengkap narahubung." : nil
    }

    var phoneError: String? {
        let value = trimmed(phone)
        let allowed = CharacterSet(charactersIn: "+0123456789 -()")
        let digits = value.filter { $0.isASCII && $0.isNumber }
        guard !value.isEmpty else { return "Masukkan nomor HP narahubung." }
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              (8...15).contains(digits.count),
              value.filter({ $0 == "+" }).count <= 1,
              !value.contains("+") || value.hasPrefix("+") else {
            return "Masukkan nomor HP yang valid, misalnya 0812 3456 7890."
        }
        return nil
    }

    var addressError: String? {
        trimmed(address).isEmpty ? "Masukkan alamat lengkap narahubung." : nil
    }

    /// Hands the validated form to its parent flow; no persistence occurs here.
    @discardableResult
    func save(onSave: (String, String, String) -> Void) -> Bool {
        showsValidation = true
        guard nameError == nil, phoneError == nil, addressError == nil else { return false }
        onSave(trimmed(name), trimmed(phone), trimmed(address))
        return true
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
