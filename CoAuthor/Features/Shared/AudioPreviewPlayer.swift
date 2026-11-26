import AVFoundation
import CryptoKit
import Foundation

/// Plays short voice-preview clips fetched from
/// `POST /v1/voices/{id}/preview`. Owns the AVAudioPlayer and a
/// two-level clip cache — in-memory for the session, plus the
/// Caches directory so relaunches don't regenerate (each
/// generation spends account characters).
@Observable
@MainActor
final class AudioPreviewPlayer: NSObject {
    /// The fixed sample line sent to TTS — part of the disk-cache
    /// key so changing it regenerates rather than serving stale audio.
    static let previewText = "This is a short preview of this voice "
        + "for your audiobook narration."

    private let backendClient: any BackendClient
    private var player: AVAudioPlayer?
    /// ElevenLabs voice_id → decoded audio for this session.
    private var clipCache: [String: Data] = [:]
    private var progressTimer: Timer?

    /// Local `Voice.id` currently loaded (playing or paused).
    private(set) var activeVoiceID: UUID?
    private(set) var isPlaying = false
    private(set) var isLoading = false
    /// Failure note for the strip ("preview unavailable" etc.).
    private(set) var error: String?
    private(set) var position: TimeInterval = 0

    init(backendClient: any BackendClient) {
        self.backendClient = backendClient
        super.init()
        // .playback so previews play under the hardware silent
        // switch — standard for intentional media playback.
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }

    var duration: TimeInterval { player?.duration ?? 0 }
    var progress: Double {
        duration > 0 ? position / duration : 0
    }

    /// Preview-button behavior: if this voice is already loaded,
    /// toggle pause/resume; otherwise fetch the clip and play.
    func toggle(voice: Voice) {
        if activeVoiceID == voice.id, player != nil {
            togglePlayback()
            return
        }
        stop()
        activeVoiceID = voice.id
        Task { await loadAndPlay(voice) }
    }

    func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        progressTimer?.invalidate()
        progressTimer = nil
        player?.stop()
        player = nil
        isPlaying = false
        isLoading = false
        position = 0
        activeVoiceID = nil
    }

    private func loadAndPlay(_ voice: Voice) async {
        let providerID = voice.savedVoiceID
        guard !providerID.isEmpty else {
            error = "No provider voice linked — sync from ElevenLabs first."
            return
        }
        guard BackendConfiguration.shared.useBackend else {
            error = "Backend mode is off — enable it in Settings → Developer."
            return
        }
        isLoading = true
        error = nil
        activeVoiceID = voice.id
        defer { isLoading = false }
        let fileURL = Self.clipFileURL(
            providerID: providerID, text: Self.previewText)
        do {
            let data: Data
            if let cached = clipCache[providerID] {
                data = cached
            } else if let diskData = try? Data(contentsOf: fileURL) {
                // Disk hit — cached from an earlier session, no call.
                data = diskData
                clipCache[providerID] = diskData
            } else {
                struct PreviewBody: Encodable {
                    var text: String
                }
                let result: BackendDTO.AudioResult =
                    try await backendClient.post(
                        "/v1/voices/\(providerID)/preview",
                        body: PreviewBody(text: Self.previewText)
                    )
                if let decoded = result.audioData {
                    data = decoded
                } else if let urlString = result.audioUrl,
                          let url = URL(string: urlString) {
                    let (fetched, _) = try await URLSession.shared
                        .data(from: url)
                    data = fetched
                } else {
                    error = "Preview unavailable — "
                        + (result.status ?? "no audio returned")
                        + "."
                    activeVoiceID = nil
                    return
                }
                clipCache[providerID] = data
                try? data.write(to: fileURL, options: .atomic)
            }
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            position = 0
            player?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            self.error = "Couldn't play the preview."
            activeVoiceID = nil
        }
    }

    /// `Caches/VoicePreviews/<voiceId>-<texthash>.mp3` — the text
    /// hash keeps stale clips from a changed preview line out of
    /// rotation. Caches may be purged under storage pressure; the
    /// fallback is simply regenerating.
    private static func clipFileURL(providerID: String, text: String) -> URL {
        let directory = FileManager.default.urls(
            for: .cachesDirectory, in: .userDomainMask
        )[0].appendingPathComponent("VoicePreviews", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)
        let digest = SHA256.hash(
            data: Data((providerID + "|" + text).utf8)
        )
        .prefix(8)
        .map { String(format: "%02x", $0) }
        .joined()
        return directory.appendingPathComponent("\(providerID)-\(digest).mp3")
    }

    /// Drops every cached clip — next previews regenerate.
    static func clearCachedClips() {
        let directory = FileManager.default.urls(
            for: .cachesDirectory, in: .userDomainMask
        )[0].appendingPathComponent("VoicePreviews", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(
            withTimeInterval: 0.25, repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.position = self?.player?.currentTime ?? 0
            }
        }
    }
}

extension AudioPreviewPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer, successfully flag: Bool
    ) {
        Task { @MainActor in
            self.isPlaying = false
            self.position = 0
            self.progressTimer?.invalidate()
            self.progressTimer = nil
        }
    }
}
