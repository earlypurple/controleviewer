import Foundation
import CoreGraphics
import AppKit
import Carbon
import SwiftUI

enum ScrollDirection {
    case up, down, none
}

@MainActor
class GestureController: ObservableObject {
    @Published var lastDetectedGesture = "Aucun"
    @Published var gestureControlEnabled = true
    @Published var gesturesDetected: Int = 0
    @Published var actionsExecuted: Int = 0
    
    private var lastClickTime: Date = Date()
    private let clickCooldown: TimeInterval = 0.5 // 500ms entre les clics
    
    // Propriétés pour l'interface professionnelle
    var currentGesture: String? {
        return nil // Simulation
    }
    
    var gestureHistory: [String] {
        return [] // Simulation
    }
    
    var recentActions: [String] {
        return [] // Simulation
    }
    
    func moveCursor(to point: CGPoint) {
        guard gestureControlEnabled else { return }
        
        lastDetectedGesture = "Pointage"
        
        // Déplacer le curseur
        let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)
        moveEvent?.post(tap: .cghidEventTap)
    }
    
    func performLeftClick() {
        guard gestureControlEnabled && canPerformClick() else { return }
        
        lastDetectedGesture = "Clic gauche"
        actionsExecuted += 1
        
        let currentPosition = CGEvent(source: nil)?.location ?? CGPoint.zero
        
        // Événement de pression du bouton
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: currentPosition, mouseButton: .left)
        mouseDown?.post(tap: .cghidEventTap)
        
        // Événement de relâchement du bouton
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: currentPosition, mouseButton: .left)
        mouseUp?.post(tap: .cghidEventTap)
        
        lastClickTime = Date()
    }
    
    func performRightClick() {
        guard gestureControlEnabled && canPerformClick() else { return }
        
        lastDetectedGesture = "Clic droit"
        actionsExecuted += 1
        
        let currentPosition = CGEvent(source: nil)?.location ?? CGPoint.zero
        
        // Événement de pression du bouton droit
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: currentPosition, mouseButton: .right)
        mouseDown?.post(tap: .cghidEventTap)
        
        // Événement de relâchement du bouton droit
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: currentPosition, mouseButton: .right)
        mouseUp?.post(tap: .cghidEventTap)
        
        lastClickTime = Date()
    }
    
    func performScroll(direction: ScrollDirection) {
        guard gestureControlEnabled else { return }
        
        let scrollAmount: Int32 = direction == .up ? 3 : -3
        
        lastDetectedGesture = "Scroll \(direction == .up ? "haut" : "bas")"
        
        let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: scrollAmount, wheel2: 0, wheel3: 0)
        scrollEvent?.post(tap: .cghidEventTap)
    }
    
    func performKeyPress(keyCode: CGKeyCode) {
        guard gestureControlEnabled else { return }
        
        // Événement de pression de touche
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        keyDown?.post(tap: .cghidEventTap)
        
        // Événement de relâchement de touche
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func performSwipe(direction: SwipeDirection) {
        guard gestureControlEnabled else { return }
        
        switch direction {
        case .left:
            lastDetectedGesture = "Swipe gauche"
            // Simuler Command + flèche gauche (retour page)
            performKeyCombo(keyCode: 123, modifiers: .maskCommand) // Flèche gauche
            
        case .right:
            lastDetectedGesture = "Swipe droite"
            // Simuler Command + flèche droite (page suivante)
            performKeyCombo(keyCode: 124, modifiers: .maskCommand) // Flèche droite
            
        case .up:
            lastDetectedGesture = "Swipe haut"
            // Simuler Mission Control
            performKeyPress(keyCode: 126) // Flèche haut
            
        case .down:
            lastDetectedGesture = "Swipe bas"
            // Simuler affichage du bureau
            performKeyPress(keyCode: 125) // Flèche bas
        }
    }
    
    private func performKeyCombo(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    private func canPerformClick() -> Bool {
        return Date().timeIntervalSince(lastClickTime) > clickCooldown
    }
}

enum SwipeDirection {
    case left, right, up, down
}

// Extensions pour les touches de clavier communes
extension CGKeyCode {
    static let space: CGKeyCode = 49
    static let enter: CGKeyCode = 36
    static let escape: CGKeyCode = 53
    static let tab: CGKeyCode = 48
    static let delete: CGKeyCode = 51
    static let arrowLeft: CGKeyCode = 123
    static let arrowRight: CGKeyCode = 124
    static let arrowDown: CGKeyCode = 125
    static let arrowUp: CGKeyCode = 126
}

// MARK: - Méthodes pour l'interface professionnelle
extension GestureController {
    func startCalibration() {
        print("🎯 Début de la calibration des gestes")
    }
    
    func resetCalibration() {
        print("🔄 Reset de la calibration")
    }
    
    func simulateLeftClick() {
        performLeftClick()
    }
    
    func simulateRightClick() {
        performRightClick()
    }
    
    func simulateClick() {
        performLeftClick()
    }
    
    func simulateScroll(direction: ScrollDirection, amount: Int) {
        performScroll(direction: direction)
    }
    
    func simulateSwipe(direction: SwipeDirection) {
        performSwipe(direction: direction)
    }
    
    func simulateZoom(factor: Double) {
        print("🔍 Zoom simulé: \(factor)")
    }
    
    // MARK: - Traitement des gestes détectés en temps réel
    
    func processDetectedGesture(_ gesture: DetectedGesture, at position: CGPoint, confidence: Float) {
        guard gestureControlEnabled else { return }
        guard confidence > 0.8 else { return } // Seuil de confiance minimum
        
        // Éviter les déclenchements répétés trop rapides
        let now = Date()
        if now.timeIntervalSince(lastClickTime) < 0.5 { return }
        
        lastDetectedGesture = gesture.description
        gesturesDetected += 1
        
        // Convertir la position relative en coordonnées écran
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let screenPosition = CGPoint(
            x: position.x * screenSize.width,
            y: (1.0 - position.y) * screenSize.height // Inverser Y
        )
        
        // Exécuter l'action correspondante
        switch gesture {
        case .pointing:
            // Déplacer le curseur vers la position pointée
            moveCursor(to: screenPosition)
            
        case .pinch:
            // Clic gauche
            performLeftClick()
            print("👆 Clic détecté par geste de pince")
            
        case .fist:
            // Clic droit
            performRightClick()
            print("✊ Clic droit détecté par poing fermé")
            
        case .peace:
            // Double clic
            performDoubleClick()
            print("✌️ Double clic détecté par geste de paix")
            
        case .thumbsUp:
            // Scroll vers le haut
            performScroll(direction: .up)
            print("👍 Scroll haut détecté par pouce levé")
            
        case .openHand:
            // Fonction spéciale (par exemple, Mission Control)
            performKeyPress(keyCode: CGKeyCode(kVK_F3))
            print("🖐 Mission Control activé par main ouverte")
            
        case .swipeLeft:
            // Navigation arrière
            performKeyPress(keyCode: CGKeyCode(kVK_LeftArrow))
            print("👈 Navigation gauche détectée")
            
        case .swipeRight:
            // Navigation avant
            performKeyPress(keyCode: CGKeyCode(kVK_RightArrow))
            print("👉 Navigation droite détectée")
            
        case .swipeUp:
            // Scroll vers le haut
            performScroll(direction: .up)
            print("👆 Scroll haut détecté")
            
        case .swipeDown:
            // Scroll vers le bas
            performScroll(direction: .down)
            print("👇 Scroll bas détecté")
            
        case .unknown:
            // Ne rien faire pour les gestes non reconnus
            break
        }
        
        lastClickTime = now
    }
    
    private func performDoubleClick() {
        guard gestureControlEnabled else { return }
        
        let currentPosition = NSEvent.mouseLocation
        let position = CGPoint(x: currentPosition.x, y: NSScreen.main!.frame.height - currentPosition.y)
        
        // Premier clic
        let mouseDown1 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        let mouseUp1 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left)
        
        // Deuxième clic
        let mouseDown2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left)
        let mouseUp2 = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left)
        
        // Configurer le deuxième clic comme double clic
        mouseDown2?.setIntegerValueField(.mouseEventClickState, value: 2)
        mouseUp2?.setIntegerValueField(.mouseEventClickState, value: 2)
        
        // Exécuter la séquence
        mouseDown1?.post(tap: .cghidEventTap)
        mouseUp1?.post(tap: .cghidEventTap)
        mouseDown2?.post(tap: .cghidEventTap)
        mouseUp2?.post(tap: .cghidEventTap)
    }
}
