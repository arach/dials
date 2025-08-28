import SwiftUI
import AppKit

/// A notification window that shows success/error messages and auto-dismisses
class NotificationWindow: NSWindow {
    private var dismissTimer: Timer?
    
    init(type: NotificationType, title: String, message: String, secondaryMessage: String? = nil, autoDismissAfter seconds: TimeInterval = 3.0) {
        // Create window
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 140),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Window properties
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.isMovableByWindowBackground = false
        self.hasShadow = true
        
        // Create content view
        let contentView = NotificationView(
            type: type,
            title: title,
            message: message,
            secondaryMessage: secondaryMessage
        )
        self.contentView = NSHostingView(rootView: contentView)
        
        // Position at top-right of screen
        positionWindow()
        
        // Animate in
        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 1.0
        }
        
        // Auto-dismiss
        if seconds > 0 {
            dismissTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
                self.dismiss()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = self.frame
        
        // Position at top-right with some padding
        let x = screenFrame.maxX - windowFrame.width - 20
        let y = screenFrame.maxY - windowFrame.height - 20
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func dismiss() {
        dismissTimer?.invalidate()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 0.0
        }) {
            self.close()
        }
    }
}

enum NotificationType {
    case success
    case error
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

struct NotificationView: View {
    let type: NotificationType
    let title: String
    let message: String
    let secondaryMessage: String?
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: type.icon)
                .font(.system(size: 36))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let secondaryMessage = secondaryMessage {
                    Text(secondaryMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)
        )
    }
}

/// Global function to show notifications
func showNotification(type: NotificationType, title: String, message: String, secondaryMessage: String? = nil, autoDismissAfter seconds: TimeInterval = 3.0) {
    DispatchQueue.main.async {
        _ = NotificationWindow(
            type: type,
            title: title,
            message: message,
            secondaryMessage: secondaryMessage,
            autoDismissAfter: seconds
        )
    }
}