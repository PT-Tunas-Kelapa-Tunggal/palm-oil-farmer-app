import Foundation

/// Data sources the location step needs.
@MainActor
struct GardenRegistrationServices {
    let locations: any GardenLocationRepository
    let photos: any GardenPhotoRepository
    /// Voice search. `nil` hides the microphone button.
    var dictation: (any GardenSpeechDictating)? = nil
}
