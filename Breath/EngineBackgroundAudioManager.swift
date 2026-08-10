//
//  BackgroundAudioManager.swift
//  Breath
//

import AVFoundation

/// Manages silent background audio to keep haptics running when screen is locked
/// 
/// ⚠️ IMPORTANT: You must add "Audio, AirPlay, and Picture in Picture" background mode
/// in your Xcode project capabilities (Signing & Capabilities → Background Modes)
class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var interruptionObserver: NSObjectProtocol?

    private init() {
        // AVAudioPlayer pauses itself on an interruption (e.g. the brief audio interruption
        // iOS sends around a lock/unlock) and does not resume automatically - do that here so
        // the background session (and thus the app's background execution) stays alive.
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard audioPlayer != nil,
              let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: typeValue) == .ended else { return }

        var shouldResume = false
        if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
            shouldResume = AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume)
        }
        guard shouldResume else { return }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play()
            print("🔊 Resumed background audio after interruption")
        } catch {
            print("❌ Failed to resume audio session after interruption: \(error)")
        }
    }

    // MARK: - Public Methods
    
    /// Start silent background audio session
    func startBackgroundAudio() {
        configureAudioSession()
        startSilentAudio()
        print("🔊 Background audio session started")
    }
    
    /// Stop background audio session
    func stopBackgroundAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("🔇 Background audio session stopped")
        } catch {
            print("❌ Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // Configure for playback with mixing (allows other audio to play)
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured for background playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    private func startSilentAudio() {
        // Generate silent audio data (1 second of silence, looping)
        guard let silentAudioURL = createSilentAudioFile() else {
            print("❌ Failed to create silent audio file")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: silentAudioURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.0 // Silent
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("✅ Silent audio player started")
        } catch {
            print("❌ Failed to start silent audio player: \(error)")
        }
    }
    
    /// Create a temporary silent audio file in memory
    private func createSilentAudioFile() -> URL? {
        // Try to load from bundle first (if you add a silent.mp3 file)
        if let bundleURL = Bundle.main.url(forResource: "silent", withExtension: "mp3") {
            return bundleURL
        }
        
        // Otherwise, create a minimal silent WAV file programmatically
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("silent.wav")
        
        // Check if it already exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        
        // Create minimal WAV file (1 second of silence at 44.1kHz, mono, 16-bit)
        let sampleRate: Int = 44100
        let numSamples = sampleRate * 1 // 1 second
        let numChannels: Int = 1
        let bitsPerSample: Int = 16
        let byteRate = sampleRate * numChannels * bitsPerSample / 8
        let blockAlign = numChannels * bitsPerSample / 8
        let dataSize = numSamples * blockAlign
        
        var data = Data()
        
        // WAV header
        data.append("RIFF".data(using: .ascii)!) // ChunkID
        data.append(uint32ToData(UInt32(36 + dataSize))) // ChunkSize
        data.append("WAVE".data(using: .ascii)!) // Format
        
        // fmt subchunk
        data.append("fmt ".data(using: .ascii)!) // Subchunk1ID
        data.append(uint32ToData(16)) // Subchunk1Size (16 for PCM)
        data.append(uint16ToData(1)) // AudioFormat (1 = PCM)
        data.append(uint16ToData(UInt16(numChannels))) // NumChannels
        data.append(uint32ToData(UInt32(sampleRate))) // SampleRate
        data.append(uint32ToData(UInt32(byteRate))) // ByteRate
        data.append(uint16ToData(UInt16(blockAlign))) // BlockAlign
        data.append(uint16ToData(UInt16(bitsPerSample))) // BitsPerSample
        
        // data subchunk
        data.append("data".data(using: .ascii)!) // Subchunk2ID
        data.append(uint32ToData(UInt32(dataSize))) // Subchunk2Size
        
        // Silent audio data (all zeros)
        data.append(Data(repeating: 0, count: dataSize))
        
        do {
            try data.write(to: fileURL)
            print("✅ Created silent audio file at \(fileURL)")
            return fileURL
        } catch {
            print("❌ Failed to write silent audio file: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Functions
    
    private func uint32ToData(_ value: UInt32) -> Data {
        var val = value.littleEndian
        return Data(bytes: &val, count: MemoryLayout<UInt32>.size)
    }
    
    private func uint16ToData(_ value: UInt16) -> Data {
        var val = value.littleEndian
        return Data(bytes: &val, count: MemoryLayout<UInt16>.size)
    }
}
