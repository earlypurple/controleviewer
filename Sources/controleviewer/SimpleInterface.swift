//
//  SimpleInterface.swift
//  controleviewer
//
//  Interface professionnelle simplifiée
//

import SwiftUI
import AVFoundation

struct SimpleControlView: View {
    @StateObject private var interfaceManager = InterfaceManager()
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var gestureController = GestureController()
    @StateObject private var aiEngine = AIGestureEngine()
    @StateObject private var spatialManager = SpatialVisionManager()
    @StateObject private var cloudManager = CloudIntelligenceManager()
    @StateObject private var learningEngine = GestureLearningEngine()
    
    @State private var selectedSection = "Dashboard"
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainContent
        }
        .onAppear {
            setupManagers()
        }
        .navigationTitle("ControleViewer Pro")
        .preferredColorScheme(.dark)
    }
    
    private func setupManagers() {
        interfaceManager.configure(
            camera: cameraManager,
            gesture: gestureController,
            ai: aiEngine,
            spatial: spatialManager,
            cloud: cloudManager
        )
        
        // Connecter le moteur d'apprentissage
        cameraManager.learningEngine = learningEngine
        
        print("🧠 Moteur d'apprentissage connecté")
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedSection) {
            Section("CONTRÔLE") {
                NavigationLink("Dashboard", value: "Dashboard")
                    .badge(interfaceManager.isDetecting ? "ACTIF" : "INACTIF")
                
                NavigationLink("Gestes", value: "Gestes")
                    .badge(interfaceManager.learnedGestures.count)
                
                NavigationLink("Caméra", value: "Caméra")
                    .badge(Text("\(Int(interfaceManager.currentFPS))fps"))
            }
            
            Section("INTELLIGENCE") {
                NavigationLink("IA", value: "IA")
                    .badge(interfaceManager.isLearning ? "APPRENTISSAGE" : "PRÊT")
                
                NavigationLink("Spatial", value: "Spatial")
                
                NavigationLink("Cloud", value: "Cloud")
                    .badge(interfaceManager.isConnected ? "CONNECTÉ" : "HORS LIGNE")
            }
            
            Section("PARAMÈTRES") {
                NavigationLink("Configuration", value: "Configuration")
                NavigationLink("Calibration", value: "Calibration")
                NavigationLink("Statistiques", value: "Statistiques")
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 250, ideal: 300)
    }
    
    // MARK: - Contenu Principal
    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedSection {
        case "Dashboard":
            dashboardView
        case "Gestes":
            gesturesView
        case "Caméra":
            cameraView
        case "IA":
            aiView
        case "Spatial":
            spatialView
        case "Cloud":
            cloudView
        case "Configuration":
            configurationView
        case "Calibration":
            calibrationView
        case "Statistiques":
            statisticsView
        default:
            dashboardView
        }
    }
    
    // MARK: - Dashboard
    
    private var dashboardView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                
                // Carte Caméra
                SimpleDashboardCard(
                    title: "Caméra",
                    value: interfaceManager.isDetecting ? "ACTIVE" : "INACTIVE",
                    subtitle: "\(Int(interfaceManager.currentFPS)) FPS",
                    icon: "camera.fill",
                    color: interfaceManager.isDetecting ? .green : .gray
                ) {
                    if interfaceManager.isDetecting {
                        interfaceManager.stopCamera()
                    } else {
                        interfaceManager.startCamera()
                    }
                }
                
                // Carte Gestes
                SimpleDashboardCard(
                    title: "Dernier Geste",
                    value: interfaceManager.lastDetectedGesture,
                    subtitle: "\(interfaceManager.learnedGestures.count) gestes appris",
                    icon: "hand.raised.fill",
                    color: .blue
                ) {
                    interfaceManager.startCalibration()
                }
                
                // Carte IA
                SimpleDashboardCard(
                    title: "Intelligence IA",
                    value: String(format: "%.1f%%", interfaceManager.gestureAccuracy * 100),
                    subtitle: interfaceManager.isLearning ? "En apprentissage" : "Prêt",
                    icon: "brain.head.profile",
                    color: interfaceManager.isLearning ? .orange : .green
                ) {
                    if interfaceManager.isLearning {
                        interfaceManager.stopLearning()
                    } else {
                        interfaceManager.startLearning()
                    }
                }
                
                // Carte Cloud
                SimpleDashboardCard(
                    title: "Cloud",
                    value: interfaceManager.isConnected ? "CONNECTÉ" : "HORS LIGNE",
                    subtitle: String(format: "%.0fms", interfaceManager.networkLatency),
                    icon: "cloud.fill",
                    color: interfaceManager.isConnected ? .green : .red
                ) {
                    print("🌐 Configuration cloud")
                }
            }
            .padding()
            
            // Contrôles Rapides
            VStack(alignment: .leading, spacing: 16) {
                Text("Contrôles Rapides")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    SimpleQuickActionButton(
                        title: "Clic",
                        icon: "cursorarrow.click",
                        color: .blue
                    ) {
                        interfaceManager.simulateClick()
                    }
                    
                    SimpleQuickActionButton(
                        title: "Scroll",
                        icon: "scroll",
                        color: .green
                    ) {
                        interfaceManager.simulateScroll(direction: .up)
                    }
                    
                    SimpleQuickActionButton(
                        title: "Swipe",
                        icon: "hand.draw",
                        color: .orange
                    ) {
                        interfaceManager.simulateSwipe(direction: .left)
                    }
                    
                    SimpleQuickActionButton(
                        title: "Zoom",
                        icon: "plus.magnifyingglass",
                        color: .purple
                    ) {
                        interfaceManager.simulateZoom(factor: 1.2)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Dashboard")
    }
    
    // MARK: - Autres Vues
    
    private var gesturesView: some View {
        VStack {
            Text("Contrôle des Gestes")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Gestes appris: \(interfaceManager.learnedGestures.count)")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Gestes")
    }
    
    private var cameraView: some View {
        VStack {
            Text("Contrôle Caméra")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("FPS: \(Int(interfaceManager.currentFPS))")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Caméra")
    }
    
    private var aiView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Titre principal
                Text("Intelligence Artificielle Adaptative")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Statut d'apprentissage
                learningStatusCard
                
                // Métriques de performance
                performanceMetricsCard
                
                // Gestes appris
                learnedGesturesCard
                
                // Contrôles d'apprentissage
                learningControlsCard
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("🧠 IA Adaptative")
    }
    
    private var learningStatusCard: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: learningEngine.isLearning ? "brain.head.profile.fill" : "brain.head.profile")
                    .font(.title)
                    .foregroundColor(learningEngine.isLearning ? .green : .blue)
                    .symbolEffect(.pulse, isActive: learningEngine.isLearning)
                
                VStack(alignment: .leading) {
                    Text("Statut d'Apprentissage")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(learningEngine.isLearning ? "En cours d'apprentissage..." : "En veille intelligente")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Barre de progression
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Progrès d'apprentissage")
                        .font(.caption)
                    Spacer()
                    Text("\(Int(learningEngine.learningProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: learningEngine.learningProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var performanceMetricsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Métriques de Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                MetricView(
                    title: "Précision IA",
                    value: String(format: "%.1f%%", learningEngine.recognitionAccuracy * 100),
                    icon: "target",
                    color: learningEngine.recognitionAccuracy > 0.8 ? .green : .orange
                )
                
                MetricView(
                    title: "Échantillons",
                    value: "\(learningEngine.trainingDataCount)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                MetricView(
                    title: "Gestes Appris",
                    value: "\(learningEngine.learnedGestures.count)",
                    icon: "hand.raised.fill",
                    color: .purple
                )
                
                MetricView(
                    title: "Précision Système",
                    value: String(format: "%.1f%%", interfaceManager.gestureAccuracy * 100),
                    icon: "checkmark.shield.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var learnedGesturesCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Gestes Appris Récemment")
                .font(.headline)
                .fontWeight(.semibold)
            
            if learningEngine.learnedGestures.isEmpty {
                Text("L'IA apprend encore vos gestes...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(minHeight: 60)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(Array(learningEngine.learnedGestures.keys.prefix(6)), id: \.self) { gestureKey in
                        if let pattern = learningEngine.learnedGestures[gestureKey] {
                            LearnedGestureView(
                                name: gestureKey,
                                confidence: pattern.averageConfidence,
                                sampleCount: pattern.sampleCount
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var learningControlsCard: some View {
        VStack(spacing: 15) {
            Text("Contrôles d'Apprentissage")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 15) {
                Button(action: {
                    if learningEngine.isLearning {
                        learningEngine.stopLearning()
                    } else {
                        learningEngine.startContinuousLearning()
                    }
                }) {
                    HStack {
                        Image(systemName: learningEngine.isLearning ? "pause.fill" : "play.fill")
                        Text(learningEngine.isLearning ? "Pause" : "Démarrer")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(learningEngine.isLearning ? .orange : .green)
                
                Button("Réinitialiser") {
                    learningEngine.resetLearning()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            Text("L'IA apprend automatiquement de vos gestes pour améliorer la précision.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var spatialView: some View {
        VStack {
            Text("Computing Spatial")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Spatial")
    }
    
    private var cloudView: some View {
        VStack {
            Text("Intelligence Cloud")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Latence: \(String(format: "%.0fms", interfaceManager.networkLatency))")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Cloud")
    }
    
    private var configurationView: some View {
        VStack {
            Text("Configuration")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Configuration")
    }
    
    private var calibrationView: some View {
        VStack {
            Text("Calibration")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Démarrer la calibration") {
                interfaceManager.startCalibration()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Calibration")
    }
    
    private var statisticsView: some View {
        VStack {
            Text("Statistiques")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Statistiques")
    }
}

// MARK: - Composants UI

struct SimpleDashboardCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SimpleQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vues d'Apprentissage IA

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct LearnedGestureView: View {
    let name: String
    let confidence: Float
    let sampleCount: Int
    
    var body: some View {
        VStack(spacing: 5) {
            Text(name)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(confidence > 0.8 ? .green : .orange)
            
            Text("\(sampleCount) échantillons")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(confidence > 0.8 ? Color.green : Color.orange, lineWidth: 1)
        )
    }
}
