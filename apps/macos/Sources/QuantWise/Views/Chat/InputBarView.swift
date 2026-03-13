import SwiftUI

struct InputBarView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var connectionVM: ConnectionViewModel
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var cameraService: CameraService
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Speech error banner
            if let err = speechService.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
            }

            // Camera error banner
            if let err = cameraService.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
            }

            // Image preview
            if let nsImage = cameraService.capturedImage {
                HStack {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button(action: { cameraService.clearCapture() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("移除图片")

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
            }

            HStack(spacing: 8) {
                // Mic button
                Button(action: handleMicTap) {
                    Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                        .foregroundStyle(speechService.isRecording ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .help("语音输入 (中文)")

                // Camera button
                Button(action: { cameraService.capturePhoto() }) {
                    Image(systemName: cameraService.isCapturing ? "camera.fill" : "camera")
                        .foregroundStyle(cameraService.isCapturing ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(cameraService.isCapturing)
                .help("拍照")

                // Text field
                TextField("输入消息…", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1 ... 5)
                    .focused($isFocused)
                    .onSubmit(send)

                // Send button
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? .blue : .gray)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(10)
        }
        .onChange(of: speechService.transcribedText) { _, newValue in
            if speechService.isRecording { inputText = newValue }
        }
    }

    // MARK: - Helpers

    private var hasText: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasImage: Bool {
        cameraService.capturedJPEGData != nil
    }

    private var canSend: Bool {
        (hasText || hasImage)
            && !chatVM.isStreaming
            && connectionVM.status == .connected
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend else { return }

        let prompt = text.isEmpty ? "请描述这张图片" : text
        let imageData = cameraService.capturedJPEGData

        inputText = ""
        cameraService.clearCapture()
        Task { await chatVM.sendMessage(prompt, imageData: imageData) }
    }

    private func handleMicTap() {
        if speechService.isRecording {
            speechService.stopRecording()
            if !speechService.transcribedText.isEmpty {
                inputText = speechService.transcribedText
                speechService.transcribedText = ""
            }
        } else {
            speechService.transcribedText = ""
            speechService.toggleRecording()
        }
    }
}
