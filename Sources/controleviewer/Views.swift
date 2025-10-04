//
//  Views.swift
//  GestureControl Pro
//
//  Vues supplémentaires pour l'interface utilisateur
//

import SwiftUI
import AVFoundation

// MARK: - Camera Control View
struct CameraControlView: View {
    @ObservedObject var gestureManager: GestureManager
    @ObservedObject var systemController: SystemController

    var body: some View {
        HStack(spacing: 20) {
            // Zone de prévisualisation caméra
            VStack {
                CameraPreviewView(gestureManager: gestureManager)
                    .frame(width: 640, height: 480)
                    .background(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(gestureManager.isRunning ? Color.blue : Color.gray, lineWidth: 2)
                    )

                // Informations sur le geste actuel
                if let gesture = gestureManager.currentGesture {
                    GestureInfoCard(gesture: gesture)
                        .transition(.opacity)
                }
            }

            // Panneau de contrôle
            VStack(alignment: .leading, spacing: 16) {
                // Statistiques en temps réel
                StatisticsPanel(
                    fps: gestureManager.currentFPS,
                    latency: gestureManager.latency,
                    handsDetected: gestureManager.handsDetected,
                    actionsPerformed: systemController.actionsPerformed
                )

                // Actions système
                SystemActionsPanel(systemController: systemController)

                Spacer()
            }
            .frame(width: 300)
        }
        .padding()
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: NSViewRepresentable {
    @ObservedObject var gestureManager: GestureManager

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = gestureManager.cameraPreviewLayer {
            previewLayer.frame = nsView.bounds
            nsView.layer = previewLayer
            nsView.wantsLayer = true
        }
    }
}

// MARK: - Gesture Info Card
struct GestureInfoCard: View {
    let gesture: DetectedGesture

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gesture.type.displayName)
                    .font(.headline)
                Text("Confiance: \(Int(gesture.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(gestureIcon(for: gesture.type))
                .font(.title)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func gestureIcon(for type: GestureType) -> String {
        switch type {
        case .pointingIndex: return "👆"
        case .closedFist: return "✊"
        case .peaceSign: return "✌️"
        case .thumbsUp: return "👍"
        case .thumbsDown: return "👎"
        case .openHand: return "✋"
        case .pinch: return "🤏"
        }
    }
}

// MARK: - Statistics Panel
struct StatisticsPanel: View {
    let fps: Double
    let latency: Double
    let handsDetected: Int
    let actionsPerformed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques Temps Réel")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                StatCard(title: "FPS", value: "\(Int(fps))", icon: "speedometer")
                StatCard(title: "Latence", value: "\(Int(latency))ms", icon: "timer")
                StatCard(title: "Mains", value: "\(handsDetected)", icon: "hand.raised")
                StatCard(title: "Actions", value: "\(actionsPerformed)", icon: "checkmark.circle")
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 80)
    }
}

// MARK: - System Actions Panel
struct SystemActionsPanel: View {
    @ObservedObject var systemController: SystemController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions Système")
                .font(.headline)

            if !systemController.isEnabled {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Permissions d'accessibilité requises")
                        .font(.caption)
                }
                .padding(.horizontal)
            }

            if let lastAction = systemController.lastAction {
                HStack {
                    Text("Dernière action:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(actionDescription(lastAction))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func actionDescription(_ action: SystemAction) -> String {
        switch action {
        case .moveMouse: return "Mouvement souris"
        case .leftClick: return "Clic gauche"
        case .rightClick: return "Clic droit"
        case .scrollUp: return "Scroll haut"
        case .scrollDown: return "Scroll bas"
        case .zoom: return "Zoom"
        case .keyboardShortcut: return "Raccourci clavier"
        case .pauseMode: return "Mode pause"
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var gestureManager: GestureManager

    var body: some View {
        Form {
            Section("Performance") {
                HStack {
                    Text("Mains maximum")
                    Spacer()
                    Stepper("\(gestureManager.settings.maxHandCount)", value: .constant(gestureManager.settings.maxHandCount), in: 1...2)
                }

                HStack {
                    Text("Seuil de confiance")
                    Spacer()
                    Slider(value: .constant(Double(gestureManager.settings.confidenceThreshold)), in: 0.1...1.0)
                        .frame(width: 100)
                }
            }

            Section("Options") {
                Toggle("Tracking activé", isOn: .constant(gestureManager.settings.trackingEnabled))
                Toggle("Lissage activé", isOn: .constant(gestureManager.settings.smoothingEnabled))
                Toggle("Calibration automatique", isOn: .constant(gestureManager.settings.calibrationEnabled))
            }
        }
        .padding()
    }
}

// MARK: - Gesture Config View
struct GestureConfigView: View {
    @ObservedObject var gestureManager: GestureManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration des Gestes")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(GestureType.allCases, id: \.self) { gestureType in
                    GestureConfigCard(gestureType: gestureType)
                }
            }
        }
        .padding()
    }
}

struct GestureConfigCard: View {
    let gestureType: GestureType
    @State private var isEnabled = true
    @State private var sensitivity: Double = 0.7

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(gestureIcon(for: gestureType))
                    .font(.title)
                VStack(alignment: .leading) {
                    Text(gestureType.displayName)
                        .font(.headline)
                    Text(actionDescription(for: gestureType.defaultAction))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $isEnabled)
            }

            if isEnabled {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sensibilité")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $sensitivity, in: 0.1...1.0)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .opacity(isEnabled ? 1.0 : 0.6)
    }

    private func gestureIcon(for type: GestureType) -> String {
        switch type {
        case .pointingIndex: return "👆"
        case .closedFist: return "✊"
        case .peaceSign: return "✌️"
        case .thumbsUp: return "👍"
        case .thumbsDown: return "👎"
        case .openHand: return "✋"
        case .pinch: return "🤏"
        }
    }

    private func actionDescription(for action: SystemAction) -> String {
        switch action {
        case .moveMouse: return "Contrôle du curseur"
        case .leftClick: return "Clic gauche"
        case .rightClick: return "Clic droit"
        case .scrollUp: return "Défilement vers le haut"
        case .scrollDown: return "Défilement vers le bas"
        case .zoom: return "Zoom"
        case .keyboardShortcut: return "Raccourci clavier"
        case .pauseMode: return "Mode pause"
        }
    }
}

// MARK: - Calibration View
struct CalibrationView: View {
    @ObservedObject var gestureManager: GestureManager
    @Binding var isCalibrating: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Calibration du Système")
                .font(.title)
                .fontWeight(.bold)

            Text("La calibration permet d'optimiser la détection pour votre environnement et votre utilisation.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Commencer la Calibration") {
                isCalibrating = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Statistics View
struct StatisticsView: View {
    @ObservedObject var gestureManager: GestureManager
    @ObservedObject var systemController: SystemController

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Text("Statistiques Détaillées")
                    .font(.title)
                    .fontWeight(.bold)

                // Graphiques et métriques détaillées ici
                Text("Fonctionnalité en développement")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Calibration Sheet
struct CalibrationSheet: View {
    @ObservedObject var gestureManager: GestureManager
    @Binding var isPresented: Bool
    @State private var currentStep = 1
    @State private var calibrationProgress: Double = 0

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Fermer") {
                    isPresented = false
                }
                Spacer()
                Text("Calibration - Étape \(currentStep)/3")
                    .font(.headline)
                Spacer()
                Button("Passer") {
                    nextStep()
                }
            }

            ProgressView(value: calibrationProgress)
                .progressViewStyle(LinearProgressViewStyle())

            switch currentStep {
            case 1:
                CalibrationStep1()
            case 2:
                CalibrationStep2()
            case 3:
                CalibrationStep3()
            default:
                Text("Calibration terminée!")
            }

            Spacer()
        }
        .padding()
        .frame(width: 600, height: 400)
    }

    private func nextStep() {
        if currentStep < 3 {
            currentStep += 1
            calibrationProgress = Double(currentStep) / 3.0
        } else {
            isPresented = false
        }
    }
}

struct CalibrationStep1: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Étape 1: Position de Référence")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Placez votre main au centre de la caméra, paume ouverte, à environ 50cm de distance.")
                .multilineTextAlignment(.center)
        }
    }
}

struct CalibrationStep2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Étape 2: Zone de Travail")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Déplacez votre index vers chaque coin de votre écran pour définir la zone de contrôle.")
                .multilineTextAlignment(.center)
        }
    }
}

struct CalibrationStep3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Étape 3: Test des Gestes")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Effectuez chaque geste configuré pour vérifier la reconnaissance.")
                .multilineTextAlignment(.center)
        }
    }
}