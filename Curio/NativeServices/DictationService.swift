import Foundation
import Observation
@preconcurrency import Speech
@preconcurrency import AVFoundation

/// User-initiated, on-device transcription only. No backend or model output can
/// start it. Partial text remains separate until the user chooses Insert text.
@MainActor @Observable final class DictationService {
    enum Phase: Equatable { case idle, authorizing, listening, ready, failed(String) }
    private(set) var phase: Phase = .idle
    var transcript = ""
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognition: SFSpeechRecognitionTask?
    private var timeout: Task<Void,Never>?
    private var session = UUID()
    var active: Bool { phase == .listening || phase == .authorizing }

    func start() async {
        cancel()
        let token = session
        phase = .authorizing
        let speech = await Self.speechAuthorization()
        guard session == token else { return }
        guard speech == .authorized else { phase = .failed("Speech recognition permission is denied or restricted. You can enable it in System Settings → Privacy & Security → Speech Recognition."); return }
        let microphone = await AVCaptureDevice.requestAccess(for:.audio)
        guard session == token else { return }
        guard microphone else { phase = .failed("Microphone permission is denied. Enable Curio in System Settings → Privacy & Security → Microphone."); return }
        guard let recognizer = SFSpeechRecognizer(locale:.current), recognizer.isAvailable, recognizer.supportsOnDeviceRecognition else {
            phase = .failed("On-device dictation isn't available for this Mac or language. Curio will not send your audio to a server."); return
        }
        let engine = AVAudioEngine(), request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true; request.shouldReportPartialResults = true
        let input = engine.inputNode, format = input.outputFormat(forBus:0)
        guard format.sampleRate > 0 && format.channelCount > 0 else { phase = .failed("No microphone input is available."); return }
        self.engine = engine; self.request = request
        input.installTap(onBus:0,bufferSize:1024,format:format) { @Sendable buffer,_ in request.append(buffer) }
        recognition = recognizer.recognitionTask(with:request) { @Sendable [weak self] result,error in
            let text = result?.bestTranscription.formattedString
            let final = result?.isFinal == true
            let failed = error != nil
            Task { @MainActor [weak self] in
                guard let self, self.session == token else { return }
                if let text { self.transcript = String(text.prefix(Curiora.maximumDraftLength)) }
                if final { self.stop() }
                else if failed {
                    self.stop()
                    self.phase = .failed("Dictation stopped. Check the microphone and on-device language availability. Any recognized text is still editable below.")
                }
            }
        }
        do { engine.prepare(); try engine.start(); phase = .listening }
        catch { stop(); phase = .failed("The microphone couldn't start. Check its connection and permissions."); return }
        timeout = Task { [weak self] in
            do { try await Task.sleep(for:.seconds(60)) } catch { return }
            self?.stop()
        }
    }
    // Legacy Speech callbacks arrive on a TCC/background queue. An explicitly
    // Sendable callback must not inherit the service's MainActor executor.
    nonisolated static func speechAuthorization(
        request: @Sendable (@escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void = { callback in SFSpeechRecognizer.requestAuthorization(callback) }
    ) async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            request { @Sendable status in continuation.resume(returning:status) }
        }
    }
    func stop() {
        session = UUID(); timeout?.cancel(); timeout = nil
        engine?.stop(); engine?.inputNode.removeTap(onBus:0); engine = nil
        request?.endAudio(); recognition?.cancel(); recognition = nil; request = nil
        phase = transcript.isEmpty ? .idle : .ready
    }
    func cancel() { stop(); transcript = ""; phase = .idle }
}
