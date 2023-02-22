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
    private var repository = [Chip]()
    private let queue = DispatchQueue(label: "queueRepository", attributes: .concurrent)
    var countRepository: Int {
        return queue.sync {
            repository.count
        }
    }

    func appendChip(chip: Chip) {
        queue.async(flags: .barrier) {
            self.repository.append(chip)
        }
    }

    func removeChip() -> Chip {
        return queue.sync(flags: .barrier) {
            repository.removeLast()
        }
    }
}

class GeneratingThread: Thread {
    static let condition = NSCondition()
    static var isPredicate = false
    private let repository: Repository
    private let dateFormatter = DateFormatter()

    public init(repository: Repository) {
        self.repository = repository
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
    }

    override public func main() {
        (0..<10).forEach { _ in
            GeneratingThread.condition.lock()
            repository.appendChip(chip: Chip.make())
            print("\(dateFormatter.string(from: Date())): \(repository.countRepository) чип создан.")
            !GeneratingThread.isPredicate
            GeneratingThread.condition.signal()
            GeneratingThread.condition.unlock()
            GeneratingThread.sleep(forTimeInterval: 2)
        }
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
        (0..<10).forEach { _ in
            if !GeneratingThread.isPredicate {
                GeneratingThread.condition.wait()
            }
            repository.removeChip().sodering()
            print("\(dateFormatter.string(from: Date())): \(repository.countRepository) чип припаян.")
        }
    }
}

let repository = Repository()
let generatingThread = GeneratingThread(repository: repository)
let workerThread = WorkerThread(repository: repository)
generatingThread.start()
workerThread.start()
