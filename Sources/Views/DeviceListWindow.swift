import SwiftUI
import AppKit

/// Window for displaying device lists with proper UI
class DeviceListWindow: NSWindow {
    init(title: String, devices: [DeviceInfo]) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = title
        self.center()
        
        let contentView = DeviceListView(title: title, devices: devices)
        self.contentView = NSHostingView(rootView: contentView)
        
        self.isReleasedWhenClosed = false
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Data model for device information
struct DeviceInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let details: [(String, String)]
    let isDefault: Bool
    let icon: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DeviceInfo, rhs: DeviceInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// SwiftUI view for displaying device list
struct DeviceListView: View {
    let title: String
    let devices: [DeviceInfo]
    @State private var selectedDevice: DeviceInfo?
    
    var body: some View {
        HSplitView {
            // Device list
            List(devices, selection: $selectedDevice) { device in
                DeviceRow(device: device)
                    .tag(device)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200, idealWidth: 250)
            
            // Device details
            if let device = selectedDevice ?? devices.first {
                DeviceDetailView(device: device)
                    .frame(minWidth: 250)
            } else {
                VStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a device")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            selectedDevice = devices.first
        }
    }
}

struct DeviceRow: View {
    let device: DeviceInfo
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.icon)
                .font(.system(size: 20))
                .foregroundColor(device.isDefault ? .accentColor : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(device.name)
                        .font(.system(size: 13, weight: device.isDefault ? .semibold : .regular))
                    
                    if device.isDefault {
                        Text("DEFAULT")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(4)
                    }
                }
                
                if let firstDetail = device.details.first {
                    Text(firstDetail.1)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DeviceDetailView: View {
    let device: DeviceInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: device.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if device.isDefault {
                            Label("Default Device", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(device.details, id: \.0) { detail in
                        DetailRow(label: detail.0, value: detail.1)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

/// Parse audio device list from SDK output
func parseAudioDevices(from output: String) -> [DeviceInfo] {
    var devices: [DeviceInfo] = []
    let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
    
    for line in lines {
        if line.contains("Audio Output Devices:") { continue }
        
        let isDefault = line.starts(with: "*")
        let cleanLine = line.trimmingCharacters(in: CharacterSet(charactersIn: "* "))
        
        if let match = cleanLine.range(of: " (ID: ") {
            let name = String(cleanLine[..<match.lowerBound])
            let idPart = String(cleanLine[match.upperBound...]).dropLast()
            
            let device = DeviceInfo(
                name: name,
                details: [
                    ("Device ID", String(idPart)),
                    ("Type", "Audio Output"),
                    ("Status", isDefault ? "Default" : "Available")
                ],
                isDefault: isDefault,
                icon: "speaker.wave.2"
            )
            devices.append(device)
        }
    }
    
    return devices
}

/// Parse display list from SDK output
func parseDisplays(from output: String) -> [DeviceInfo] {
    var devices: [DeviceInfo] = []
    var currentDevice: (name: String, details: [(String, String)], isMain: Bool)?
    
    let lines = output.components(separatedBy: "\n")
    
    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.starts(with: "Display ID:") {
            // Save previous device if exists
            if let device = currentDevice {
                devices.append(DeviceInfo(
                    name: device.name,
                    details: device.details,
                    isDefault: device.isMain,
                    icon: device.isMain ? "display" : "tv"
                ))
            }
            
            // Start new device
            let id = trimmed.replacingOccurrences(of: "Display ID: ", with: "")
            currentDevice = (
                name: "Display \(id)",
                details: [("Display ID", id)],
                isMain: false
            )
        } else if trimmed.starts(with: "Name:") {
            let name = trimmed.replacingOccurrences(of: "Name: ", with: "").trimmingCharacters(in: .whitespaces)
            currentDevice?.name = name
        } else if trimmed.starts(with: "Resolution:") {
            let resolution = trimmed.replacingOccurrences(of: "Resolution: ", with: "").trimmingCharacters(in: .whitespaces)
            currentDevice?.details.append(("Resolution", resolution))
        } else if trimmed.starts(with: "Main:") {
            let isMain = trimmed.contains("Yes")
            currentDevice?.isMain = isMain
            currentDevice?.details.append(("Main Display", isMain ? "Yes" : "No"))
        } else if trimmed.starts(with: "Active:") {
            let value = trimmed.replacingOccurrences(of: "Active: ", with: "").trimmingCharacters(in: .whitespaces)
            currentDevice?.details.append(("Active", value))
        } else if trimmed.starts(with: "Builtin:") {
            let value = trimmed.replacingOccurrences(of: "Builtin: ", with: "").trimmingCharacters(in: .whitespaces)
            currentDevice?.details.append(("Built-in", value))
        }
    }
    
    // Add last device
    if let device = currentDevice {
        devices.append(DeviceInfo(
            name: device.name,
            details: device.details,
            isDefault: device.isMain,
            icon: device.isMain ? "display" : "tv"
        ))
    }
    
    return devices
}

/// Show device list window
func showDeviceListWindow(title: String, output: String, type: DeviceType) {
    DispatchQueue.main.async {
        let devices: [DeviceInfo]
        
        switch type {
        case .audio:
            devices = parseAudioDevices(from: output)
        case .display:
            devices = parseDisplays(from: output)
        }
        
        _ = DeviceListWindow(title: title, devices: devices)
    }
}

enum DeviceType {
    case audio
    case display
}