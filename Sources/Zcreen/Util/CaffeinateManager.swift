import Foundation
import Combine

final class CaffeinateManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var remainingMinutes = 0

    private var process: Process?
    private var countdownTimer: Timer?

    static let durations: [(label: String, minutes: Int)] = [
        ("1h", 60),
        ("2h", 120),
        ("4h", 240),
    ]

    func activate(minutes: Int) {
        deactivate()

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        proc.arguments = ["-d", "-i", "-t", "\(minutes * 60)"]

        do {
            try proc.run()
            process = proc
            isActive = true
            remainingMinutes = minutes

            let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.remainingMinutes -= 1
                if self.remainingMinutes <= 0 {
                    self.deactivate()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            countdownTimer = timer

            Log.general.info("Caffeinate started for \(minutes) minutes")
        } catch {
            Log.general.error("Failed to start caffeinate: \(error.localizedDescription)")
        }
    }

    func deactivate() {
        process?.terminate()
        process = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        isActive = false
        remainingMinutes = 0
    }

    deinit {
        deactivate()
    }
}
