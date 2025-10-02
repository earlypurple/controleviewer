import Foundation
import SwiftUI
import Vision

// MARK: - Configuration des Gestes

struct GestureConfiguration: Codable, Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var sensitivity: Double // 0.0 à 1.0
    var action: GestureAction
    var isEnabled: Bool
    var customParameters: [String: Double]
    
    init(name: String, description: String, sensitivity: Double = 0.8, action: GestureAction, isEnabled: Bool = true) {
        self.name = name
        self.description = description
        self.sensitivity = sensitivity
        self.action = action
        self.isEnabled = isEnabled
        self.customParameters = [:]
    }
}

enum GestureAction: String, Codable, CaseIterable {
    case leftClick = "Clic Gauche"
    case rightClick = "Clic Droit"
    case doubleClick = "Double Clic"
    case scrollUp = "Défiler Haut"
    case scrollDown = "Défiler Bas"
    case moveCursor = "Déplacer Curseur"
    case dragAndDrop = "Glisser-Déposer"
    case zoom = "Zoom"
    case missionControl = "Mission Control"
    case showDesktop = "Afficher Bureau"
    case custom = "Action Personnalisée"
    case none = "Aucune Action"
    
    var systemName: String {
        switch self {
        case .leftClick: return "hand.tap.fill"
        case .rightClick: return "hand.point.right.fill"
        case .doubleClick: return "hand.tap.fill"
        case .scrollUp: return "arrow.up.circle.fill"
        case .scrollDown: return "arrow.down.circle.fill"
        case .moveCursor: return "cursorarrow"
        case .dragAndDrop: return "hand.drag.fill"
        case .zoom: return "magnifyingglass.circle.fill"
        case .missionControl: return "macwindow.on.rectangle"
        case .showDesktop: return "rectangle.grid.1x2.fill"
        case .custom: return "gear.circle.fill"
        case .none: return "xmark.circle.fill"
        }
    }
}

@MainActor
class GestureConfigurationManager: ObservableObject {
    @Published var configurations: [DetectedGesture: GestureConfiguration] = [:]
    @Published var globalSensitivity: Double = 0.8
    @Published var detectionThreshold: Double = 0.75
    @Published var smoothingFactor: Double = 0.3
    @Published var gestureTimeout: Double = 0.5
    
    // Paramètres avancés pour améliorer la précision
    @Published var fingerExtensionThreshold: Double = 0.6
    @Published var pinchDistanceThreshold: Double = 0.05
    @Published var swipeDistanceThreshold: Double = 0.1
    @Published var confidenceMultiplier: Double = 1.2
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "GestureConfigurations"
    
    init() {
        setupDefaultConfigurations()
        loadConfigurations()
    }
    
    private func setupDefaultConfigurations() {
        configurations = [
            .pointing: GestureConfiguration(
                name: "Pointage",
                description: "Déplacer le curseur avec l'index",
                sensitivity: 0.9,
                action: .moveCursor
            ),
            .pinch: GestureConfiguration(
                name: "Pince",
                description: "Clic gauche avec pouce et index",
                sensitivity: 0.8,
                action: .leftClick
            ),
            .fist: GestureConfiguration(
                name: "Poing Fermé",
                description: "Clic droit avec poing fermé",
                sensitivity: 0.7,
                action: .rightClick
            ),
            .peace: GestureConfiguration(
                name: "Signe de Paix",
                description: "Double clic avec index et majeur",
                sensitivity: 0.8,
                action: .doubleClick
            ),
            .thumbsUp: GestureConfiguration(
                name: "Pouce Levé",
                description: "Défiler vers le haut",
                sensitivity: 0.7,
                action: .scrollUp
            ),
            .openHand: GestureConfiguration(
                name: "Main Ouverte",
                description: "Mission Control",
                sensitivity: 0.8,
                action: .missionControl
            ),
            .swipeLeft: GestureConfiguration(
                name: "Balayage Gauche",
                description: "Navigation précédente",
                sensitivity: 0.6,
                action: .custom
            ),
            .swipeRight: GestureConfiguration(
                name: "Balayage Droite",
                description: "Navigation suivante",
                sensitivity: 0.6,
                action: .custom
            ),
            .swipeUp: GestureConfiguration(
                name: "Balayage Haut",
                description: "Défiler vers le haut",
                sensitivity: 0.6,
                action: .scrollUp
            ),
            .swipeDown: GestureConfiguration(
                name: "Balayage Bas",
                description: "Défiler vers le bas",
                sensitivity: 0.6,
                action: .scrollDown
            )
        ]
    }
    
    func updateConfiguration(for gesture: DetectedGesture, configuration: GestureConfiguration) {
        configurations[gesture] = configuration
        saveConfigurations()
    }
    
    func getConfiguration(for gesture: DetectedGesture) -> GestureConfiguration? {
        return configurations[gesture]
    }
    
    func updateSensitivity(for gesture: DetectedGesture, sensitivity: Double) {
        guard var config = configurations[gesture] else { return }
        config.sensitivity = max(0.0, min(1.0, sensitivity))
        configurations[gesture] = config
        saveConfigurations()
    }
    
    func toggleGesture(_ gesture: DetectedGesture) {
        guard var config = configurations[gesture] else { return }
        config.isEnabled.toggle()
        configurations[gesture] = config
        saveConfigurations()
    }
    
    func resetToDefaults() {
        setupDefaultConfigurations()
        saveConfigurations()
    }
    
    // MARK: - Persistance
    
    private func saveConfigurations() {
        do {
            let data = try JSONEncoder().encode(configurations)
            userDefaults.set(data, forKey: configKey)
            
            // Sauvegarder les paramètres globaux
            userDefaults.set(globalSensitivity, forKey: "GlobalSensitivity")
            userDefaults.set(detectionThreshold, forKey: "DetectionThreshold")
            userDefaults.set(smoothingFactor, forKey: "SmoothingFactor")
            userDefaults.set(gestureTimeout, forKey: "GestureTimeout")
            userDefaults.set(fingerExtensionThreshold, forKey: "FingerExtensionThreshold")
            userDefaults.set(pinchDistanceThreshold, forKey: "PinchDistanceThreshold")
            userDefaults.set(swipeDistanceThreshold, forKey: "SwipeDistanceThreshold")
            userDefaults.set(confidenceMultiplier, forKey: "ConfidenceMultiplier")
            
        } catch {
            print("Erreur lors de la sauvegarde des configurations: \(error)")
        }
    }
    
    private func loadConfigurations() {
        guard let data = userDefaults.data(forKey: configKey) else { return }
        
        do {
            let loadedConfigurations = try JSONDecoder().decode([DetectedGesture: GestureConfiguration].self, from: data)
            self.configurations = loadedConfigurations
            
            // Charger les paramètres globaux
            globalSensitivity = userDefaults.double(forKey: "GlobalSensitivity")
            detectionThreshold = userDefaults.double(forKey: "DetectionThreshold")
            smoothingFactor = userDefaults.double(forKey: "SmoothingFactor")
            gestureTimeout = userDefaults.double(forKey: "GestureTimeout")
            fingerExtensionThreshold = userDefaults.double(forKey: "FingerExtensionThreshold")
            pinchDistanceThreshold = userDefaults.double(forKey: "PinchDistanceThreshold")
            swipeDistanceThreshold = userDefaults.double(forKey: "SwipeDistanceThreshold")
            confidenceMultiplier = userDefaults.double(forKey: "ConfidenceMultiplier")
            
        } catch {
            print("Erreur lors du chargement des configurations: \(error)")
        }
    }
    
    // MARK: - Calculs de Précision Améliorés
    
    func calculateAdjustedConfidence(baseConfidence: Float, for gesture: DetectedGesture) -> Float {
        guard let config = configurations[gesture], config.isEnabled else { return 0.0 }
        
        let sensitivityFactor = Float(config.sensitivity * globalSensitivity)
        let adjustedConfidence = baseConfidence * sensitivityFactor * Float(confidenceMultiplier)
        
        return min(1.0, max(0.0, adjustedConfidence))
    }
    
    func shouldTriggerGesture(confidence: Float, for gesture: DetectedGesture) -> Bool {
        let adjustedConfidence = calculateAdjustedConfidence(baseConfidence: confidence, for: gesture)
        return adjustedConfidence >= Float(detectionThreshold)
    }
    
    func getFingerExtensionThreshold() -> Double {
        return fingerExtensionThreshold
    }
    
    func getPinchDistanceThreshold() -> Double {
        return pinchDistanceThreshold * globalSensitivity
    }
    
    func getSwipeDistanceThreshold() -> Double {
        return swipeDistanceThreshold * globalSensitivity
    }
}

// Extension pour rendre DetectedGesture Codable
extension DetectedGesture: Codable {
    enum CodingKeys: String, CodingKey {
        case pointing, peace, pinch, fist, openHand, thumbsUp
        case swipeLeft, swipeRight, swipeUp, swipeDown, unknown
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.pointing) { self = .pointing }
        else if container.contains(.peace) { self = .peace }
        else if container.contains(.pinch) { self = .pinch }
        else if container.contains(.fist) { self = .fist }
        else if container.contains(.openHand) { self = .openHand }
        else if container.contains(.thumbsUp) { self = .thumbsUp }
        else if container.contains(.swipeLeft) { self = .swipeLeft }
        else if container.contains(.swipeRight) { self = .swipeRight }
        else if container.contains(.swipeUp) { self = .swipeUp }
        else if container.contains(.swipeDown) { self = .swipeDown }
        else { self = .unknown }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .pointing: try container.encode(true, forKey: .pointing)
        case .peace: try container.encode(true, forKey: .peace)
        case .pinch: try container.encode(true, forKey: .pinch)
        case .fist: try container.encode(true, forKey: .fist)
        case .openHand: try container.encode(true, forKey: .openHand)
        case .thumbsUp: try container.encode(true, forKey: .thumbsUp)
        case .swipeLeft: try container.encode(true, forKey: .swipeLeft)
        case .swipeRight: try container.encode(true, forKey: .swipeRight)
        case .swipeUp: try container.encode(true, forKey: .swipeUp)
        case .swipeDown: try container.encode(true, forKey: .swipeDown)
        case .unknown: try container.encode(true, forKey: .unknown)
        }
    }
}
