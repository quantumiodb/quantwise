import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechService: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    /// Whether both speech and microphone permissions are granted
    private var speechAuthorized = false
    private var micAuthorized = false

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hans"))
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task { await startRecordingWithAuth() }
        }
    }

    // MARK: - Authorization

    private func startRecordingWithAuth() async {
        errorMessage = nil

        // 1. Microphone permission
        if !micAuthorized {
            let micStatus = await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    cont.resume(returning: granted)
                }
            }
            micAuthorized = micStatus
            if !micAuthorized {
                errorMessage = "需要麦克风权限"
                return
            }
        }

        // 2. Speech recognition permission
        if !speechAuthorized {
            let speechStatus = await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { status in
                    cont.resume(returning: status)
                }
            }
            speechAuthorized = (speechStatus == .authorized)
            if !speechAuthorized {
                errorMessage = "需要语音识别权限"
                return
            }
        }

        startRecording()
    }

    // MARK: - Recording

    private func startRecording() {
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }

        // Clean up any previous session
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                if let error {
                    // Don't report cancellation errors
                    if (error as NSError).domain != "kAFAssistantErrorDomain"
                        || (error as NSError).code != 216
                    {
                        self.errorMessage = error.localizedDescription
                    }
                    self.stopRecording()
                } else if result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = "无法启动录音: \(error.localizedDescription)"
            stopRecording()
        }
    }

    func stopRecording() {
        guard isRecording || audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
