import AVFoundation
import Foundation

final class SoundHub {
    var soundEnabled = true
    var musicEnabled = true

    private var bgm: AVAudioPlayer?
    private var sfx: [String: AVAudioPlayer] = [:]
    private let session = AVAudioSession.sharedInstance()

    init() {
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        preload("sfx_click")
        preload("sfx_tick")
        preload("sfx_spin")
        preload("sfx_stop")
        preload("sfx_win")
    }

    func startMusic() {
        guard musicEnabled else { return }
        if bgm == nil {
            bgm = player("bgm_goldhall")
            bgm?.numberOfLoops = -1
            bgm?.volume = 0.36
        }
        bgm?.play()
    }

    func stopMusic() { bgm?.stop() }

    func click() { play("sfx_click", volume: 0.55) }
    func tick() { play("sfx_tick", volume: 0.28) }
    func spin() { play("sfx_spin", volume: 0.62) }
    func stopReel() { play("sfx_stop", volume: 0.52) }
    func win() { play("sfx_win", volume: 0.78) }

    private func play(_ name: String, volume: Float) {
        guard soundEnabled else { return }
        if let p = sfx[name] {
            p.currentTime = 0
            p.volume = volume
            p.play()
        }
    }

    private func preload(_ name: String) {
        sfx[name] = player(name)
    }

    private func player(_ name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.prepareToPlay()
        return p
    }
}
