import CoreBluetooth
import Foundation
import Observation

/// A spreader seen while scanning.
struct DiscoveredSpreader: Identifiable, Equatable {
    let id: UUID
    let name: String
    var rssi: Int
}

/// One press of "Keluarkan Pupuk". The firmware sends no status, so the app times it.
struct DispenseRun: Equatable {
    let id = UUID()
    let zoneID: Int
    let liters: Double
    let milliseconds: Int
    let startedAt: Date

    func progress(at date: Date) -> Double {
        let total = Double(milliseconds)
        guard total > 0 else { return 1 }
        return min(max(date.timeIntervalSince(startedAt) * 1000 / total, 0), 1)
    }

    func remainingSeconds(at date: Date) -> Int {
        let remaining = Double(milliseconds) / 1000 - date.timeIntervalSince(startedAt)
        return max(Int(remaining.rounded(.up)), 0)
    }
}

/// How a run ended. `completed` is false when stopped or disconnected before the pump time ended.
struct FinishedDispense: Equatable {
    let runID: UUID
    let zoneID: Int
    let completed: Bool
}

/// Finds spreaders, connects to the one the farmer picks, and sends one "T:<ms>" command per dose.
/// The central uses the main queue, so delegate callbacks arrive on the main actor.
@Observable
final class SpreaderBLEManager: NSObject {
    enum Connection: Equatable {
        case idle, scanning, connecting, ready, notFound, disconnected
        case bluetoothOff, unauthorized, unsupported
    }

    private(set) var connection: Connection = .idle
    /// Devices found in the current scan, strongest signal first.
    private(set) var discovered: [DiscoveredSpreader] = []
    private(set) var isScanning = false
    private(set) var connectingID: UUID?
    private(set) var deviceName: String?
    private(set) var run: DispenseRun?
    private(set) var lastFinished: FinishedDispense?
    /// Last text the device notified, if it notifies anything (useful while testing).
    private(set) var lastDeviceText: String?
    private(set) var message: String?

    @ObservationIgnored private var central: CBCentralManager?
    @ObservationIgnored private var peripherals: [UUID: CBPeripheral] = [:]
    @ObservationIgnored private var peripheral: CBPeripheral?
    @ObservationIgnored private var commandCharacteristic: CBCharacteristic?
    @ObservationIgnored private var pendingServices = 0
    @ObservationIgnored private var lastPeripheralID: UUID?
    @ObservationIgnored private var timeout: Task<Void, Never>?
    @ObservationIgnored private var runTask: Task<Void, Never>?
    @ObservationIgnored private var wantsScan = false
    @ObservationIgnored private var userDisconnected = false

    var isReady: Bool { connection == .ready }
    var isRunning: Bool { run != nil }

    // MARK: Connection

    /// Starts looking for spreaders. The farmer then picks one with `connect(to:)`.
    func startScan() {
        message = nil
        wantsScan = true
        userDisconnected = false
        guard let central else {
            central = CBCentralManager(delegate: self, queue: nil)  // scan starts in didUpdateState
            return
        }
        if central.state == .poweredOn { scan() } else { centralManagerDidUpdateState(central) }
    }

    func connect(to id: UUID) {
        guard let target = peripherals[id] else { return }
        open(target)
    }

    /// Reconnects to the last spreader after a dropped link.
    func reconnect() {
        message = nil
        userDisconnected = false
        guard let central, central.state == .poweredOn, let id = lastPeripheralID,
              let known = central.retrievePeripherals(withIdentifiers: [id]).first else {
            startScan()
            return
        }
        open(known)
    }

    func disconnect() {
        userDisconnected = true
        wantsScan = false
        timeout?.cancel()
        endRun(completed: false)
        stopScanning()
        if let peripheral { central?.cancelPeripheralConnection(peripheral) }
        reset(to: .idle)
        discovered = []
    }

    // MARK: Dispensing

    /// Releases one dose as a single command: pump time = liters ÷ flow.
    @discardableResult
    func dispense(liters: Double, zoneID: Int) -> Bool {
        guard run == nil else {
            message = "Alat masih mengeluarkan pupuk."
            return false
        }
        guard let total = SpreaderPulse.milliseconds(liters: liters) else {
            message = "Dosis harus antara 0 dan \(SpreaderLimits.maxLiters.formatted()) L."
            return false
        }
        guard connection == .ready, commandCharacteristic != nil else {
            message = "Alat belum terhubung."
            return false
        }
        message = nil
        let newRun = DispenseRun(zoneID: zoneID, liters: liters, milliseconds: total, startedAt: .now)
        run = newRun
        runTask = Task { [weak self] in await self?.execute(newRun) }
        return true
    }

    /// Ends the run in the app. The pump stops now only if the firmware has a stop command;
    /// otherwise it runs until its time is up.
    func stop() {
        guard let run else { return }
        if let stopCommand = SpreaderGATT.stopCommand {
            write(Data(stopCommand.utf8))
            message = "Pupuk dihentikan."
        } else {
            let remaining = run.remainingSeconds(at: .now)
            message = remaining > 0
                ? "Alat belum punya perintah stop. Pompa berhenti sendiri dalam ±\(remaining) detik."
                : "Dihentikan."
        }
        endRun(completed: false)
    }

    private func execute(_ current: DispenseRun) async {
        guard write(SpreaderPulse.command(milliseconds: current.milliseconds)) else {
            endRun(completed: false)
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(current.milliseconds))
        } catch {
            return  // cancelled by stop() or disconnect()
        }
        guard run?.id == current.id else { return }
        endRun(completed: true)
    }

    private func endRun(completed: Bool) {
        runTask?.cancel()
        runTask = nil
        guard let run else { return }
        lastFinished = FinishedDispense(runID: run.id, zoneID: run.zoneID, completed: completed)
        self.run = nil
    }

    @discardableResult
    private func write(_ data: Data) -> Bool {
        guard connection == .ready, let peripheral, let commandCharacteristic else {
            message = "Alat belum terhubung."
            return false
        }
        let type: CBCharacteristicWriteType =
            commandCharacteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: commandCharacteristic, type: type)
        return true
    }

    // MARK: Steps

    private func scan() {
        guard let central, central.state == .poweredOn else { return }
        // iOS may still hold a link to a spreader (e.g. after reopening the screen).
        if let service = SpreaderGATT.service,
           let known = central.retrieveConnectedPeripherals(withServices: [service]).first {
            open(known)
            return
        }
        discovered = []
        peripherals = [:]
        connection = .scanning
        isScanning = true
        central.scanForPeripherals(withServices: SpreaderGATT.service.map { [$0] })
        startTimeout(seconds: 15) { manager in
            guard manager.connection == .scanning else { return }
            manager.stopScanning()  // keep the list; the farmer picks from it
            if manager.discovered.isEmpty {
                manager.connection = .notFound
                manager.message = "Alat tidak ditemukan. Pastikan alat menyala dan dekat dengan iPhone."
            }
        }
    }

    private func open(_ target: CBPeripheral) {
        stopScanning()
        peripheral = target
        target.delegate = self
        connectingID = target.identifier
        deviceName = discovered.first { $0.id == target.identifier }?.name ?? target.name ?? deviceName
        connection = .connecting
        central?.connect(target)
        startTimeout(seconds: 15) { manager in
            guard manager.connection == .connecting else { return }
            if let peripheral = manager.peripheral { manager.central?.cancelPeripheralConnection(peripheral) }
            manager.reset(to: .disconnected)
            manager.message = "Alat belum terjangkau. Dekatkan iPhone ke alat lalu coba lagi."
        }
    }

    private func stopScanning() {
        central?.stopScan()
        isScanning = false
    }

    private func startTimeout(seconds: Int, _ action: @escaping (SpreaderBLEManager) -> Void) {
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self, !Task.isCancelled else { return }
            action(self)
        }
    }

    private func becomeReady(with characteristic: CBCharacteristic, on target: CBPeripheral) {
        timeout?.cancel()
        commandCharacteristic = characteristic
        connectingID = nil
        lastPeripheralID = target.identifier
        if deviceName == nil { deviceName = target.name }
        connection = .ready
    }

    private func fail(_ text: String) {
        timeout?.cancel()
        endRun(completed: false)
        if let peripheral { central?.cancelPeripheralConnection(peripheral) }
        reset(to: .disconnected)
        message = text
    }

    private func reset(to state: Connection) {
        peripheral?.delegate = nil
        peripheral = nil
        commandCharacteristic = nil
        connectingID = nil
        pendingServices = 0
        connection = state
    }
}

// MARK: - CBCentralManagerDelegate

extension SpreaderBLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if wantsScan, connection != .ready, connection != .connecting { scan() }
        case .poweredOff:
            stopScanning()
            endRun(completed: false)
            reset(to: .bluetoothOff)
            message = "Nyalakan Bluetooth di iPhone untuk terhubung ke alat."
        case .unauthorized:
            reset(to: .unauthorized)
            message = "Izinkan Bluetooth untuk aplikasi ini di Pengaturan."
        case .unsupported:
            reset(to: .unsupported)
            message = "iPhone ini tidak mendukung Bluetooth LE."
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard connection == .scanning,
              let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name,
              !name.isEmpty else { return }
        if let prefix = SpreaderGATT.namePrefix, !name.hasPrefix(prefix) { return }
        peripherals[peripheral.identifier] = peripheral
        let rssi = RSSI.intValue == 127 ? -127 : RSSI.intValue  // 127 = unavailable
        if let index = discovered.firstIndex(where: { $0.id == peripheral.identifier }) {
            discovered[index].rssi = rssi
        } else {
            discovered.append(DiscoveredSpreader(id: peripheral.identifier, name: name, rssi: rssi))
        }
        discovered.sort { $0.rssi > $1.rssi }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(SpreaderGATT.service.map { [$0] })
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard peripheral == self.peripheral else { return }
        fail("Gagal terhubung ke alat. Coba lagi.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        guard peripheral == self.peripheral, !userDisconnected else { return }
        timeout?.cancel()
        endRun(completed: false)
        reset(to: .disconnected)
    }
}

// MARK: - CBPeripheralDelegate

extension SpreaderBLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services ?? []
        guard !services.isEmpty else {
            fail("Perangkat ini bukan alat pemupuk.")
            return
        }
        pendingServices = services.count
        for service in services {
            peripheral.discoverCharacteristics(SpreaderGATT.command.map { [$0] }, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard connection == .connecting else { return }
        pendingServices -= 1
        let characteristics = service.characteristics ?? []
        let writable = characteristics.first { characteristic in
            if let command = SpreaderGATT.command { return characteristic.uuid == command }
            return characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
        }
        for characteristic in characteristics where characteristic.properties.contains(.notify) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
        if let writable {
            becomeReady(with: writable, on: peripheral)
        } else if pendingServices <= 0 {
            fail("Alat tidak punya saluran perintah. Periksa firmware.")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value, let text = String(data: data, encoding: .utf8) else { return }
        lastDeviceText = text
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil { message = "Perintah tidak terkirim. Coba lagi." }
    }
}
