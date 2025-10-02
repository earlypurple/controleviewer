import SwiftUI
import Foundation

// MARK: - Interface de Configuration des Gestes

struct GestureConfigurationView: View {
    @ObservedObject var configManager: GestureConfigurationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Paramètres globaux
                globalSettingsSection
                
                // Configuration des gestes individuels
                gestureConfigurationSection
                
                // Actions de configuration
                configurationActionsSection
            }
            .padding()
        }
    }
    
    private var globalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Paramètres Globaux")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ParameterSlider(
                    title: "Sensibilité Globale",
                    value: $configManager.globalSensitivity,
                    range: 0.1...1.0
                )
                
                ParameterSlider(
                    title: "Seuil de Détection",
                    value: $configManager.detectionThreshold,
                    range: 0.5...1.0
                )
                
                ParameterSlider(
                    title: "Lissage",
                    value: $configManager.smoothingFactor,
                    range: 0.1...1.0
                )
                
                ParameterSlider(
                    title: "Timeout entre Gestes (s)",
                    value: $configManager.gestureTimeout,
                    range: 0.1...2.0
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var gestureConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Configuration des Gestes")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(Array(configManager.configurations.keys), id: \.self) { gesture in
                    if let config = configManager.configurations[gesture] {
                        GestureConfigCard(
                            gesture: gesture,
                            configuration: config,
                            onUpdate: { newConfig in
                                configManager.updateConfiguration(for: gesture, configuration: newConfig)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var configurationActionsSection: some View {
        HStack(spacing: 20) {
            Button("Réinitialiser") {
                configManager.resetToDefaults()
            }
            .buttonStyle(.bordered)
            
            Button("Calibrer") {
                // Action de calibration
                print("🎯 Calibration lancée")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
        }
    }
}

struct GestureConfigCard: View {
    let gesture: DetectedGesture
    @State private var configuration: GestureConfiguration
    let onUpdate: (GestureConfiguration) -> Void
    
    init(gesture: DetectedGesture, configuration: GestureConfiguration, onUpdate: @escaping (GestureConfiguration) -> Void) {
        self.gesture = gesture
        self._configuration = State(initialValue: configuration)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // En-tête du geste
            HStack {
                Text(gesture.description)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("", isOn: $configuration.isEnabled)
                    .labelsHidden()
                    .onChange(of: configuration.isEnabled) {
                        onUpdate(configuration)
                    }
            }
            
            // Description
            Text(configuration.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Sensibilité
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Sensibilité")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.1f%%", configuration.sensitivity * 100))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $configuration.sensitivity, in: 0.1...1.0)
                    .accentColor(.blue)
                    .disabled(!configuration.isEnabled)
                    .onChange(of: configuration.sensitivity) {
                        onUpdate(configuration)
                    }
            }
            
            // Action assignée
            Menu {
                ForEach(GestureAction.allCases, id: \.self) { action in
                    Button(action.rawValue) {
                        configuration.action = action
                        onUpdate(configuration)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: configuration.action.systemName)
                        .foregroundColor(.blue)
                    Text(configuration.action.rawValue)
                        .font(.caption)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(6)
            }
            .disabled(!configuration.isEnabled)
        }
        .padding()
        .background(Color(.secondarySystemFill))
        .cornerRadius(10)
        .opacity(configuration.isEnabled ? 1.0 : 0.6)
    }
}
