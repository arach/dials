import CoreAudio
import AudioToolbox

enum AudioController {
    // MARK: Device discovery --------------------------------------------------
    struct Device {
        let id: AudioObjectID
        let name: String
    }

    struct DeviceInfo {
        let id: AudioDeviceID
        let name: String
        let manufacturer: String
        let channels: Int
        let sampleRates: [Double]
        let leftVolume: Float
        let rightVolume: Float
        let balance: Float
        let muted: Bool
        let transportType: String
    }

    static func allOutputDevices() throws -> [Device] {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)

        var dataSize: UInt32 = 0
        try check(AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                                 &addr, 0, nil, &dataSize))

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: deviceCount)

        try check(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                             &addr, 0, nil,
                                             &dataSize, &ids))
        return try ids.compactMap { id in
            guard isOutputDevice(id) else { return nil }
            return Device(id: id, name: try deviceName(for: id))
        }
    }

    static var defaultOutputDeviceID: AudioObjectID {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var id = AudioDeviceID()
        var size = UInt32(MemoryLayout.size(ofValue: id))
        _ = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                       &addr, 0, nil, &size, &id)
        return id
    }

    static func getBalance() throws -> Float {
        let devID = defaultOutputDeviceID
        var balance: Float = 0.5 // Default to center
        
        // First try stereo pan
        var stereoPanAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var stereoPanSize = UInt32(MemoryLayout.size(ofValue: balance))
        
        if AudioObjectHasProperty(devID, &stereoPanAddr) {
            AudioObjectGetPropertyData(devID, &stereoPanAddr, 0, nil, &stereoPanSize, &balance)
            return balance
        }
        
        // Fall back to virtual balance
        var balAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainBalance,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var balSize = UInt32(MemoryLayout.size(ofValue: balance))
        
        if AudioObjectHasProperty(devID, &balAddr) {
            AudioObjectGetPropertyData(devID, &balAddr, 0, nil, &balSize, &balance)
        }
        
        return balance
    }
    
    static func setBalance(_ balance: Float) throws {
        let devID = defaultOutputDeviceID
        
        // First try stereo pan (more commonly supported)
        var stereoPan = balance
        var stereoPanAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(devID, &stereoPanAddr) {
            let size = UInt32(MemoryLayout.size(ofValue: stereoPan))
            let status = AudioObjectSetPropertyData(devID, &stereoPanAddr, 0, nil, size, &stereoPan)
            if status == noErr {
                print("[Dials] Set balance to \(balance) using stereo pan")
                return
            }
        }
        
        // If that fails, try virtual balance
        var bal = balance
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainBalance,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(devID, &addr) {
            let size = UInt32(MemoryLayout.size(ofValue: bal))
            let status = AudioObjectSetPropertyData(devID, &addr, 0, nil, size, &bal)
            if status != noErr {
                print("[Dials] Failed to set balance on device \(devID) (OSStatus: \(status))")
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
        } else {
            throw NSError(domain: NSOSStatusErrorDomain, code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Device does not support balance control"
            ])
        }
    }

    /// Returns true if the device had a native balance property and we set it successfully.
    @discardableResult
    private static func setNativeBalance(_ balance: Float,
                                         deviceID: AudioObjectID) throws -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainBalance,
            mScope:    kAudioDevicePropertyScopeOutput,
            mElement:  kAudioObjectPropertyElementMain)

        guard AudioObjectHasProperty(deviceID, &addr) else {
            return false                                // property not available
        }

        var val = Float32(balance)
        let size = UInt32(MemoryLayout.size(ofValue: val))
        try check(AudioObjectSetPropertyData(deviceID, &addr, 0, nil, size, &val))
        return true
    }

    private static func setMasterBalance(_ balance: Float, deviceID: AudioObjectID) throws {
        var val = Float32(balance)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainBalance,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)

        let size = UInt32(MemoryLayout.size(ofValue: val))
        try check(AudioObjectSetPropertyData(deviceID, &addr, 0, nil, size, &val))
    }

    // MARK: Helpers -----------------------------------------------------------
    private static func deviceName(for id: AudioObjectID) throws -> String {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var cfName: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        _ = try withUnsafeMutablePointer(to: &cfName) { ptr in
            try check(AudioObjectGetPropertyData(id, &addr, 0, nil, &size, ptr))
        }
        return cfName as String
    }

    private static func isOutputDevice(_ id: AudioObjectID) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr else { return false }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
        defer { bufferList.deallocate() }
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, bufferList) == noErr else { return false }

        let audioListPtr = UnsafeMutableAudioBufferListPointer(bufferList)
        let channels = audioListPtr.reduce(0) { $0 + Int($1.mNumberChannels) }
        return channels > 0
    }

    private static func preferredStereoChannels(of id: AudioObjectID) throws -> (UInt32, UInt32)? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyPreferredChannelsForStereo,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var chans = [UInt32](repeating: 0, count: 2)
        var size = UInt32(MemoryLayout.size(ofValue: chans))
        let err = AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &chans)
        return err == noErr ? (chans[0], chans[1]) : nil
    }

    private static func setVolume(scalar: Float32, deviceID: AudioObjectID, channel: UInt32) throws {
        var value = scalar
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: channel)
        let size = UInt32(MemoryLayout.size(ofValue: value))
        try check(AudioObjectSetPropertyData(deviceID, &addr, 0, nil, size, &value))
    }

    @discardableResult
    private static func check(_ err: OSStatus) throws -> OSStatus {
        if err != noErr {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(err), userInfo: [NSLocalizedDescriptionKey: "OSStatus \(err)"])
        }
        return err
    }

    static func deviceInfo(id: AudioDeviceID) throws -> DeviceInfo {
        // Name
        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var nameAddr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        _ = withUnsafeMutablePointer(to: &name) { ptr in
            AudioObjectGetPropertyData(id, &nameAddr, 0, nil, &nameSize, ptr)
        }

        // Manufacturer
        var manu: CFString = "" as CFString
        var manuSize = UInt32(MemoryLayout<CFString>.size)
        var manuAddr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyManufacturer,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        _ = withUnsafeMutablePointer(to: &manu) { ptr in
            AudioObjectGetPropertyData(id, &manuAddr, 0, nil, &manuSize, ptr)
        }

        // Channels
        let channels = Int(try preferredStereoChannels(of: id)?.1 ?? 2)

        // Sample Rates
        var srAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var srSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(id, &srAddr, 0, nil, &srSize)
        let srCount = Int(srSize) / MemoryLayout<AudioValueRange>.size
        var srRanges = [AudioValueRange](repeating: AudioValueRange(mMinimum: 0, mMaximum: 0), count: srCount)
        AudioObjectGetPropertyData(id, &srAddr, 0, nil, &srSize, &srRanges)
        let sampleRates = srRanges.flatMap { [$0.mMinimum, $0.mMaximum] }.filter { $0 > 0 }

        // Volumes
        let leftVolume = (try? getVolume(deviceID: id, channel: 1)) ?? 0
        let rightVolume = (try? getVolume(deviceID: id, channel: 2)) ?? 0

        // Balance - try stereo pan first (since that's what we use for setting)
        var bal: Float = 0.5 // Default to center
        
        // First try stereo pan
        var stereoPanAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var stereoPanSize = UInt32(MemoryLayout.size(ofValue: bal))
        
        if AudioObjectHasProperty(id, &stereoPanAddr) {
            AudioObjectGetPropertyData(id, &stereoPanAddr, 0, nil, &stereoPanSize, &bal)
        } else {
            // Fall back to virtual balance
            var balAddr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainBalance,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain)
            var balSize = UInt32(MemoryLayout.size(ofValue: bal))
            AudioObjectGetPropertyData(id, &balAddr, 0, nil, &balSize, &bal)
        }

        // Muted
        var muted: UInt32 = 0
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var muteSize = UInt32(MemoryLayout.size(ofValue: muted))
        AudioObjectGetPropertyData(id, &muteAddr, 0, nil, &muteSize, &muted)

        // Transport Type
        var transport: UInt32 = 0
        var transAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var transSize = UInt32(MemoryLayout.size(ofValue: transport))
        AudioObjectGetPropertyData(id, &transAddr, 0, nil, &transSize, &transport)
        let transportType: String
        switch transport {
        case kAudioDeviceTransportTypeBuiltIn: transportType = "Built-in"
        case kAudioDeviceTransportTypeAggregate: transportType = "Aggregate"
        case kAudioDeviceTransportTypeUSB: transportType = "USB"
        case kAudioDeviceTransportTypeBluetooth: transportType = "Bluetooth"
        case kAudioDeviceTransportTypeHDMI: transportType = "HDMI"
        case kAudioDeviceTransportTypeDisplayPort: transportType = "DisplayPort"
        default: transportType = "Other"
        }

        return DeviceInfo(
            id: id,
            name: name as String,
            manufacturer: manu as String,
            channels: channels,
            sampleRates: sampleRates,
            leftVolume: leftVolume,
            rightVolume: rightVolume,
            balance: bal,
            muted: muted != 0,
            transportType: transportType
        )
    }

    static func getVolume(deviceID: AudioDeviceID, channel: UInt32) throws -> Float {
        var value: Float32 = 0
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: channel)
        var size = UInt32(MemoryLayout.size(ofValue: value))
        try check(AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &value))
        return value
    }
}