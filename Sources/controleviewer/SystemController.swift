//
//  SystemController.swift
//  GestureControl Pro
//
//  Contrôleur d'actions système avec API d'accessibilité macOS
//

import Foundation
@preconcurrency import ApplicationServices
import Cocoa

@MainActor
class SystemController: ObservableObject {
    @Published var isEnabled = false
    @Published var actionsPerformed: Int = 0
    @Published var lastAction: SystemAction?

    private var actionThrottler = ActionThrottler()
    private var cursorSmoother = CursorSmoother()

    init() {
        checkAccessibilityPermissions()
        setupGestureNotifications()
    }

    // MARK: - Public Methods
    func performAction(_ action: SystemAction, with parameters: ActionParameters? = nil) {
        guard isEnabled && AXIsProcessTrusted() else {
            print("Permissions d'accessibilité requises")
            return
        }

        guard actionThrottler.shouldExecute(action) else { return }

        switch action {
        case .moveMouse:
            if let point = parameters?.mousePosition {
                moveMouse(to: point)
            }

        case .leftClick:
            performMouseClick(.left, at: parameters?.mousePosition)

        case .rightClick:
            performMouseClick(.right, at: parameters?.mousePosition)

        case .scrollUp:
            performScroll(.up, amount: parameters?.scrollAmount ?? 3)

        case .scrollDown:
            performScroll(.down, amount: parameters?.scrollAmount ?? 3)

        case .zoom:
            performZoom(parameters?.zoomFactor ?? 1.1)

        case .keyboardShortcut:
            if let shortcut = parameters?.keyboardShortcut {
                performKeyboardShortcut(shortcut)
            }

        case .pauseMode:
            // Mode pause - ne rien faire
            break
        }

        DispatchQueue.main.async {
            self.actionsPerformed += 1
            self.lastAction = action
        }
    }

    // MARK: - Private Methods
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()

        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }

        isEnabled = trusted

        // Vérifier périodiquement les permissions
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            let currentStatus = AXIsProcessTrusted()
            DispatchQueue.main.async {
                self?.isEnabled = currentStatus
            }
        }
    }

    private func setupGestureNotifications() {
        NotificationCenter.default.addObserver(
            forName: .gestureDetected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let gesture = notification.object as? DetectedGesture else { return }
            self?.handleDetectedGesture(gesture)
        }
    }

    private func handleDetectedGesture(_ gesture: DetectedGesture) {
        let action = gesture.type.defaultAction
        let parameters = createActionParameters(from: gesture)
        performAction(action, with: parameters)
    }

    private func createActionParameters(from gesture: DetectedGesture) -> ActionParameters {
        var parameters = ActionParameters()

        // Conversion des coordonnées de geste en position écran
        if let indexTip = gesture.landmarks.first {
            let screenPoint = convertToScreenCoordinates(indexTip)
            parameters.mousePosition = screenPoint
        }

        parameters.confidence = gesture.confidence
        parameters.timestamp = gesture.timestamp

        return parameters
    }

    private func convertToScreenCoordinates(_ point: CGPoint) -> CGPoint {
        // Conversion des coordonnées normalisées (0-1) en coordonnées écran
        guard let screen = NSScreen.main else { return .zero }

        let screenFrame = screen.frame
        let x = point.x * screenFrame.width
        let y = (1 - point.y) * screenFrame.height // Inverser Y pour macOS

        return CGPoint(x: x, y: y)
    }

    // MARK: - Mouse Actions
    private func moveMouse(to point: CGPoint) {
        let smoothedPoint = cursorSmoother.smooth(point)

        let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: smoothedPoint,
            mouseButton: .left
        )

        moveEvent?.post(tap: .cgSessionEventTap)
    }

    private func performMouseClick(_ button: CGMouseButton, at position: CGPoint?) {
        let clickPosition = position ?? NSEvent.mouseLocation
        
        let downType: CGEventType
        let upType: CGEventType
        
        switch button {
        case .left:
            downType = .leftMouseDown
            upType = .leftMouseUp
        case .right:
            downType = .rightMouseDown
            upType = .rightMouseUp
        default:
            return
        }

        let downEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: downType,
            mouseCursorPosition: clickPosition,
            mouseButton: button
        )

        let upEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: upType,
            mouseCursorPosition: clickPosition,
            mouseButton: button
        )

        downEvent?.post(tap: .cgSessionEventTap)

        // Délai réaliste pour le clic
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            upEvent?.post(tap: .cgSessionEventTap)
        }
    }

    private func performScroll(_ direction: ScrollDirection, amount: Int) {
        let scrollAmount = direction == .up ? amount : -amount
        
        let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: Int32(scrollAmount * 10),
            wheel2: 0,
            wheel3: 0
        )

        scrollEvent?.post(tap: .cgSessionEventTap)
    }
    
    private func performZoom(_ factor: Double) {
        // Simulation du zoom avec Cmd++ ou Cmd+-
        let keyCode: CGKeyCode = factor > 1.0 ? 24 : 27 // + ou -

        let flagsDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 55, // Cmd
            keyDown: true
        )
        flagsDown?.flags = .maskCommand

        let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: true
        )
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: keyCode,
            keyDown: false
        )

        let flagsUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: 55,
            keyDown: false
        )

        flagsDown?.post(tap: .cghidEventTap)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        flagsUp?.post(tap: .cghidEventTap)
    }

    private func performKeyboardShortcut(_ shortcut: KeyboardShortcut) {
        var flags: CGEventFlags = []

        if shortcut.command { flags.insert(.maskCommand) }
        if shortcut.option { flags.insert(.maskAlternate) }
        if shortcut.control { flags.insert(.maskControl) }
        if shortcut.shift { flags.insert(.maskShift) }

        let keyDown = CGEvent(
            keyboardEventSource: nil,
            virtualKey: shortcut.keyCode,
            keyDown: true
        )
        keyDown?.flags = flags

        let keyUp = CGEvent(
            keyboardEventSource: nil,
            virtualKey: shortcut.keyCode,
            keyDown: false
        )

        keyDown?.post(tap: .cghidEventTap)

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}

// MARK: - Supporting Types
enum SystemAction {
    case moveMouse
    case leftClick
    case rightClick
    case scrollUp
    case scrollDown
    case zoom
    case keyboardShortcut
    case pauseMode
}

struct ActionParameters {
    var mousePosition: CGPoint?
    var scrollAmount: Int?
    var zoomFactor: Double?
    var keyboardShortcut: KeyboardShortcut?
    var confidence: Float?
    var timestamp: Date?
}

struct KeyboardShortcut {
    let keyCode: CGKeyCode
    let command: Bool
    let option: Bool
    let control: Bool
    let shift: Bool

    static let copy = KeyboardShortcut(keyCode: 8, command: true, option: false, control: false, shift: false) // C
    static let paste = KeyboardShortcut(keyCode: 9, command: true, option: false, control: false, shift: false) // V
    static let undo = KeyboardShortcut(keyCode: 0, command: true, option: false, control: false, shift: false) // A -> Z
}

enum ScrollDirection {
    case up, down
}

// MARK: - Utility Classes
class ActionThrottler {
    private var lastActionTimes: [SystemAction: Date] = [:]
    private let throttleInterval: TimeInterval = 0.1 // 100ms

    func shouldExecute(_ action: SystemAction) -> Bool {
        let now = Date()
        let lastTime = lastActionTimes[action] ?? Date.distantPast

        if now.timeIntervalSince(lastTime) >= throttleInterval {
            lastActionTimes[action] = now
            return true
        }

        return false
    }
}

class CursorSmoother {
    private var previousPoint: CGPoint?
    private let smoothingFactor: Double = 0.3

    func smooth(_ point: CGPoint) -> CGPoint {
        guard let previous = previousPoint else {
            previousPoint = point
            return point
        }

        let smoothed = CGPoint(
            x: previous.x + (point.x - previous.x) * smoothingFactor,
            y: previous.y + (point.y - previous.y) * smoothingFactor
        )

        previousPoint = smoothed
        return smoothed
    }
}