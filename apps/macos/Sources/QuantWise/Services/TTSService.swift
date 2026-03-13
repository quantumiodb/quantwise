import AVFoundation
import Foundation

@MainActor
final class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var currentMessageId: UUID?

    private let synthesizer = AVSpeechSynthesizer()
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    override init() {
        super.init()
        synthesizer.delegate = self
        cacheVoices()
    }

    func speak(_ text: String, messageId: UUID) {
        let wasThisMessage = currentMessageId == messageId
        if isSpeaking {
            stop()
            if wasThisMessage { return }
        }

        let clean = stripMarkdown(text)
        let lang = detectLanguage(clean)
        let voice = voiceCache[lang]

        // Split into sentences for natural cadence
        let sentences = splitSentences(clean)

        currentMessageId = messageId
        isSpeaking = true

        for (i, sentence) in sentences.enumerated() {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let utterance = AVSpeechUtterance(string: trimmed)
            utterance.voice = voice
            utterance.rate = 0.47
            utterance.pitchMultiplier = 1.05
            // Pause between sentences
            utterance.preUtteranceDelay = i == 0 ? 0.05 : 0.25
            utterance.postUtteranceDelay = 0.1

            synthesizer.speak(utterance)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .word)
        isSpeaking = false
        currentMessageId = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        Task { @MainActor in
            // Only mark done when queue is empty (no more queued utterances)
            if !self.synthesizer.isSpeaking {
                self.isSpeaking = false
                self.currentMessageId = nil
            }
        }
    }

    // MARK: - Voice Selection

    private func cacheVoices() {
        // Preferred voices (best sounding per language)
        let preferred: [String: [String]] = [
            "zh-CN": ["Tingting", "Lili", "Shanshan"],
            "en-US": ["Samantha", "Ava", "Zoe"],
        ]

        for (lang, names) in preferred {
            let voices = AVSpeechSynthesisVoice.speechVoices()
                .filter { $0.language == lang }
                // Prefer highest quality available
                .sorted { $0.quality.rawValue > $1.quality.rawValue }

            // Try preferred names first (in quality order)
            for name in names {
                if let match = voices.first(where: { $0.name == name }) {
                    voiceCache[lang] = match
                    break
                }
            }
            // Fallback to highest quality available
            if voiceCache[lang] == nil {
                voiceCache[lang] = voices.first
            }
        }
    }

    // MARK: - Text Processing

    /// Split text into sentences for more natural speech rhythm
    private func splitSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        // Split on Chinese and English sentence terminators
        let pattern = "(?<=[。！？.!?\\n])"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            var lastEnd = text.startIndex
            regex.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match else { return }
                let matchRange = Range(match.range, in: text)!
                let sentence = String(text[lastEnd ..< matchRange.lowerBound])
                if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sentences.append(sentence)
                }
                lastEnd = matchRange.lowerBound
            }
            // Remaining text
            let remaining = String(text[lastEnd...])
            if !remaining.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sentences.append(remaining)
            }
        } else {
            sentences = [text]
        }
        return sentences.isEmpty ? [text] : sentences
    }

    private func detectLanguage(_ text: String) -> String {
        let cjkCount = text.unicodeScalars.filter { $0.value >= 0x4E00 && $0.value <= 0x9FFF }.count
        return Double(cjkCount) / max(Double(text.count), 1) > 0.15 ? "zh-CN" : "en-US"
    }

    private func stripMarkdown(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "#{1,6}\\s+", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\*{1,3}", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\|", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "-{3,}", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "`", with: "")
        s = s.replacingOccurrences(of: "^\\s*[-*]\\s+", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
