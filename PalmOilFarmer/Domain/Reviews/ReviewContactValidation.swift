import Foundation

extension ReviewContactDetails {
    static func validated(
        name: String,
        phone: String,
        address: String,
        hasConfirmedContact: Bool
    ) -> ReviewContactDetails? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = phone.filter(\.isNumber)
        guard !trimmedName.isEmpty, !trimmedAddress.isEmpty,
              digits.count >= 8, hasConfirmedContact else { return nil }
        // Keep the original phone formatting, matching the existing submission payload.
        return ReviewContactDetails(name: trimmedName, phone: phone, address: trimmedAddress)
    }
}
