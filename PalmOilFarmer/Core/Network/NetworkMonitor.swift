import Foundation
import Network
import Observation

/// Observes device internet connectivity using Apple's Network framework (`NWPathMonitor`).
@MainActor
@Observable
public final class NetworkMonitor: Sendable {
    public static let shared = NetworkMonitor()

    public private(set) var isConnected: Bool = true

    #if DEBUG
    /// Allows mocking network state in previews and tests.
    public var isMockDisconnected: Bool = false {
        didSet {
            updateConnectionState(pathStatus: currentPathStatus)
        }
    }
    #endif

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var currentPathStatus: NWPath.Status = .satisfied

    public init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        self.queue = DispatchQueue(label: "com.putra.PalmOilFarmer.NetworkMonitor", qos: .background)

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.currentPathStatus = path.status
                self?.updateConnectionState(pathStatus: path.status)
            }
        }
        monitor.start(queue: queue)
        currentPathStatus = monitor.currentPath.status
        updateConnectionState(pathStatus: currentPathStatus)
    }

    deinit {
        monitor.cancel()
    }

    private func updateConnectionState(pathStatus: NWPath.Status) {
        #if DEBUG
        if isMockDisconnected {
            isConnected = false
            return
        }
        #endif
        isConnected = (pathStatus == .satisfied)
    }

    public func refresh() {
        currentPathStatus = monitor.currentPath.status
        updateConnectionState(pathStatus: currentPathStatus)
    }
}

