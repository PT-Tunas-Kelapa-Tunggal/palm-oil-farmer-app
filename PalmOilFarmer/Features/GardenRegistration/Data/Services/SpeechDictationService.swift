import AVFoundation
import Speech

/// Live `GardenSpeechDictating` backed by the Speech framework, recognising Indonesian.
///
/// Listening stops by itself once the farmer pauses, so one tap on the microphone is enough.
@MainActor
final class SpeechDictationService: GardenSpeechDictating {
    private let locale: Locale
    private let initialTimeout: Duration
    private let pauseTimeout: Duration

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?
    private var timer: Task<Void, Never>?
    private var session = UUID()
    private var hasTapInstalled = false
    private var hasTranscript = false
    private var isStopping = false

    /// - Parameters:
    ///   - initialTimeout: how long to wait for the first words before giving up.
    ///   - pauseTimeout: how long a pause after speaking ends listening.
    init(locale: Locale = Locale(identifier: "id-ID"),
         initialTimeout: Duration = .seconds(6), pauseTimeout: Duration = .seconds(1.5)) {
        self.locale = locale
        self.initialTimeout = initialTimeout
        self.pauseTimeout = pauseTimeout
    }

    func transcripts() -> AsyncThrowingStream<String, Error> {
        finish()
        let id = UUID()
        session = id
        hasTranscript = false
        isStopping = false
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()
        self.continuation = continuation
        continuation.onTermination = { @Sendable [weak self] _ in
            Task { @MainActor in self?.finish(session: id) }
        }
        Task { await start(session: id) }
        return stream
    }

    func stop() {
        stopListening(session: session)
    }

    // MARK: Listening

    private func start(session id: UUID) async {
        do {
            guard await Self.requestAuthorization() else { throw GardenSpeechDictationError.notAuthorized }
            guard id == session, continuation != nil else { return }
            guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
                throw GardenSpeechDictationError.unavailable
            }
            self.recognizer = recognizer

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .search
            self.request = request

            try Self.installTap(on: audioEngine.inputNode, feeding: request)
            hasTapInstalled = true
            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = Self.recognize(request, with: recognizer) { [weak self] text, isFinal, error in
                self?.handle(session: id, text: text, isFinal: isFinal, error: error)
            }
            scheduleStop(session: id, after: initialTimeout)
        } catch {
            finish(session: id, error: error)
        }
    }

    private func handle(session id: UUID, text: String?, isFinal: Bool, error: (any Error)?) {
        guard id == session, continuation != nil else { return }
        if let text, !text.isEmpty {
            hasTranscript = true
            continuation?.yield(text)
            if !isStopping { scheduleStop(session: id, after: pauseTimeout) }
        }
        if let error {
            // Once something was heard, a late recogniser error (e.g. "no more speech") is not a failure.
            finish(session: id, error: hasTranscript ? nil : error)
        } else if isFinal {
            finish(session: id)
        }
    }

    private func scheduleStop(session id: UUID, after delay: Duration) {
        timer?.cancel()
        timer = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.stopListening(session: id)
        }
    }

    /// Ends audio input and lets the recogniser deliver its final transcript.
    private func stopListening(session id: UUID) {
        guard id == session, continuation != nil else { return }
        guard request != nil, !isStopping else {
            if request == nil { finish(session: id) }
            return
        }
        isStopping = true
        removeAudioInput()
        request?.endAudio()
        // The final result normally arrives at once; don't keep the stream open if it never does.
        timer?.cancel()
        timer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.finish(session: id)
        }
    }

    /// Tears everything down. Without `session` it always runs; with one, only for that session.
    private func finish(session id: UUID? = nil, error: (any Error)? = nil) {
        if let id, id != session { return }
        timer?.cancel()
        timer = nil
        removeAudioInput()
        request?.endAudio()
        request = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        let continuation = self.continuation
        self.continuation = nil
        if let error {
            continuation?.finish(throwing: error)
        } else {
            continuation?.finish()
        }
    }

    private func removeAudioInput() {
        if audioEngine.isRunning { audioEngine.stop() }
        if hasTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasTapInstalled = false
        }
    }

    // MARK: Off the main actor
    // The tap and the recognition handler are called on audio and recogniser threads, so they are
    // built in nonisolated functions and only hop back to the main actor with plain values.

    nonisolated private static func requestAuthorization() async -> Bool {
        let speech = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    nonisolated private static func installTap(on input: AVAudioInputNode,
                                               feeding request: SFSpeechAudioBufferRecognitionRequest) throws {
        let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.sampleRate > 0 else { throw GardenSpeechDictationError.unavailable }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
    }

    nonisolated private static func recognize(
        _ request: SFSpeechAudioBufferRecognitionRequest, with recognizer: SFSpeechRecognizer,
        onUpdate: @escaping @MainActor @Sendable (String?, Bool, (any Error)?) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            Task { @MainActor in onUpdate(text, isFinal, error) }
        }
    }
}
