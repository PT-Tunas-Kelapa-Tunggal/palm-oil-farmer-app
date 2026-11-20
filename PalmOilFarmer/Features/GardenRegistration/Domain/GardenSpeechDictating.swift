import Foundation

/// Turns the farmer's speech into search text for "Cari Lokasi Kebun".
@MainActor
protocol GardenSpeechDictating: AnyObject {
    /// Starts listening. Yields the whole transcript so far each time it changes, and finishes when
    /// listening stops: after a pause, after `stop()`, or when the consuming task is cancelled.
    func transcripts() -> AsyncThrowingStream<String, Error>
    /// Stops listening. The stream still delivers the final transcript before it finishes.
    func stop()
}

enum GardenSpeechDictationError: Error, Equatable {
    /// Microphone or speech recognition permission was not granted.
    case notAuthorized
    /// Speech recognition for Indonesian is not available on this device right now.
    case unavailable
}
