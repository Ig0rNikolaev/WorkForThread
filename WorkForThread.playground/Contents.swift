import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }

    public let chipType: ChipType

    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }

        return Chip(chipType: chipType)
    }

    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}

class Repository {
    private let сondition = NSCondition()
    private var repository = [Chip]()
    private var isPredicate = false

    func appendChip(_ element: Chip) {
        сondition.lock()
        repository.append(element)
        isPredicate = true
        сondition.signal()
        сondition.unlock()
    }

    func removeChip() -> Chip? {
        var сhip: Chip?
        сondition.lock()
        while !isPredicate {
            сondition.wait()
            сhip = repository.removeLast()
        }
        isPredicate = false
        сondition.unlock()
        return сhip
    }
}

class GeneratingThread: Thread {
    private let repository: Repository
    private let dateFormatter = DateFormatter()
    private var timer = Timer()

    public init(repository: Repository) {
        self.repository = repository
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    override public func main() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: (true)) { [self] _ in
            let chip = Chip.make()
            repository.appendChip(chip)
            print("\(dateFormatter.string(from: Date())) - \(Thread.current.name ?? "") - чип создан")
        }
        RunLoop.current.run(until: Date().addingTimeInterval(20))
    }
}

class WorkerThread: Thread {
    private let repository: Repository
    private let dateFormatter = DateFormatter()

    public init(repository: Repository) {
        self.repository = repository
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    override public func main() {
        while true {
            repository.removeChip()?.sodering()
            print("\(dateFormatter.string(from: Date())) - \(Thread.current.name ?? " ") - чип удален")
        }
    }
}

let repository = Repository()

let generatingThread = GeneratingThread(repository: repository)
generatingThread.name = "GENR"
generatingThread.start()

let workerThread = WorkerThread(repository: repository)
workerThread.name = "WORK"
workerThread.start()
