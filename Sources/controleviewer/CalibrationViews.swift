//
//  CalibrationViews.swift
//  GestureControl Pro
//
//  Interface de calibration visuelle et interactive
//

import SwiftUI

// MARK: - Calibration Main View
struct ImprovedCalibrationView: View {
    @StateObject private var calibrationManager = CalibrationManager()
    @ObservedObject var gestureManager: GestureManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header avec progression
                CalibrationHeader(
                    step: calibrationManager.currentStep,
                    progress: calibrationManager.progress
                )
                
                Spacer()
                
                // Contenu principal selon l'étape
                CalibrationStepContent(
                    step: calibrationManager.currentStep,
                    statusMessage: calibrationManager.statusMessage,
                    samplesCollected: calibrationManager.samplesCollected
                )
                
                Spacer()
                
                // Boutons de contrôle
                CalibrationControls(
                    calibrationManager: calibrationManager,
                    isPresented: $isPresented
                )
            }
            .padding()
            
            // Overlay pour afficher les targets de calibration
            if calibrationManager.isCalibrating {
                CalibrationTargetsOverlay(step: calibrationManager.currentStep)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            calibrationManager.startCalibration()
        }
    }
}

// MARK: - Header
struct CalibrationHeader: View {
    let step: CalibrationManager.CalibrationStep
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: step.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calibration")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(step.title)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
}

// MARK: - Step Content
struct CalibrationStepContent: View {
    let step: CalibrationManager.CalibrationStep
    let statusMessage: String
    let samplesCollected: Int
    
    var body: some View {
        VStack(spacing: 32) {
            // Instructions
            Text(step.instructions)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 60)
                .fixedSize(horizontal: false, vertical: true)
            
            // Visualization selon l'étape
            Group {
                switch step {
                case .introduction:
                    IntroductionVisualization()
                case .handPosition:
                    HandPositionVisualization()
                case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .centerPoint:
                    CornerTargetVisualization(step: step, samplesCollected: samplesCollected)
                case .gestureTest:
                    GestureTestVisualization()
                case .completed:
                    CompletionVisualization()
                }
            }
            .frame(maxWidth: 600, maxHeight: 300)
            
            // Status message
            if !statusMessage.isEmpty && step != .introduction && step != .completed {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text(statusMessage)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Visualizations
struct IntroductionVisualization: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                HStack(spacing: 32) {
                    FeatureIcon(icon: "target", text: "Précision")
                    FeatureIcon(icon: "speedometer", text: "Performance")
                    FeatureIcon(icon: "checkmark.shield", text: "Fiabilité")
                }
            }
        }
    }
}

struct FeatureIcon: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.cyan)
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct HandPositionVisualization: View {
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Pulsing circle
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                .frame(width: 200, height: 200)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.3
                    }
                }
            
            // Hand icon
            Text("✋")
                .font(.system(size: 80))
        }
    }
}

struct CornerTargetVisualization: View {
    let step: CalibrationManager.CalibrationStep
    let samplesCollected: Int
    @State private var glowOpacity = 0.3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mini screen representation
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 400, height: 250)
                
                // Target corner indicator
                if let targetPosition = getTargetPosition(for: step, in: geometry.size) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30)
                        .position(targetPosition)
                        .shadow(color: .blue, radius: 20 * glowOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                glowOpacity = 1.0
                            }
                        }
                    
                    // Arrow pointing to target
                    Image(systemName: "arrow.down")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .position(x: targetPosition.x, y: targetPosition.y - 60)
                }
                
                // Progress indicator
                if samplesCollected > 0 {
                    VStack {
                        Text("\(samplesCollected)/10")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("échantillons")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func getTargetPosition(for step: CalibrationManager.CalibrationStep, in size: CGSize) -> CGPoint? {
        let rect = CGRect(x: size.width / 2 - 200, y: size.height / 2 - 125, width: 400, height: 250)
        
        switch step {
        case .topLeftCorner:
            return CGPoint(x: rect.minX + 30, y: rect.minY + 30)
        case .topRightCorner:
            return CGPoint(x: rect.maxX - 30, y: rect.minY + 30)
        case .bottomLeftCorner:
            return CGPoint(x: rect.minX + 30, y: rect.maxY - 30)
        case .bottomRightCorner:
            return CGPoint(x: rect.maxX - 30, y: rect.maxY - 30)
        case .centerPoint:
            return CGPoint(x: rect.midX, y: rect.midY)
        default:
            return nil
        }
    }
}

struct GestureTestVisualization: View {
    @State private var currentGesture = 0
    let gestures = ["✊", "✌️", "👍"]
    let gestureNames = ["Poing Fermé", "Peace Sign", "Pouce Levé"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text(gestures[currentGesture])
                .font(.system(size: 100))
                .transition(.scale.combined(with: .opacity))
            
            Text(gestureNames[currentGesture])
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation {
                    currentGesture = (currentGesture + 1) % gestures.count
                }
            }
        }
    }
}

struct CompletionVisualization: View {
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Circle()
                    .stroke(Color.green, lineWidth: 5)
                    .frame(width: 150, height: 150)
                
                if showCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Text("Calibration Réussie!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - Controls
struct CalibrationControls: View {
    @ObservedObject var calibrationManager: CalibrationManager
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Bouton Annuler
            Button(action: {
                calibrationManager.cancelCalibration()
                isPresented = false
            }) {
                Label("Annuler", systemImage: "xmark")
                    .frame(width: 120)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            // Bouton Précédent
            if calibrationManager.currentStep.rawValue > 0 && calibrationManager.currentStep != .completed {
                Button(action: {
                    calibrationManager.previousStep()
                }) {
                    Label("Précédent", systemImage: "chevron.left")
                        .frame(width: 120)
                }
                .buttonStyle(.bordered)
            }
            
            // Bouton Suivant / Terminer
            Button(action: {
                if calibrationManager.currentStep == .completed {
                    isPresented = false
                } else if calibrationManager.currentStep == .introduction {
                    calibrationManager.nextStep()
                } else {
                    // Pour les autres étapes, attendre que les échantillons soient collectés
                    // ou permettre de passer
                    calibrationManager.nextStep()
                }
            }) {
                if calibrationManager.currentStep == .completed {
                    Label("Terminer", systemImage: "checkmark")
                        .frame(width: 120)
                } else if calibrationManager.currentStep == .introduction {
                    Label("Commencer", systemImage: "play.fill")
                        .frame(width: 120)
                } else {
                    Label("Passer", systemImage: "chevron.right")
                        .frame(width: 120)
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Targets Overlay
struct CalibrationTargetsOverlay: View {
    let step: CalibrationManager.CalibrationStep
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Afficher les targets aux coins de l'écran
                if shouldShowCornerTarget(step) {
                    ForEach(getActiveCorners(step), id: \.self) { corner in
                        CornerTarget()
                            .position(getCornerPosition(corner, in: geometry.size))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func shouldShowCornerTarget(_ step: CalibrationManager.CalibrationStep) -> Bool {
        switch step {
        case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .centerPoint:
            return true
        default:
            return false
        }
    }
    
    private func getActiveCorners(_ step: CalibrationManager.CalibrationStep) -> [CornerPosition] {
        switch step {
        case .topLeftCorner: return [.topLeft]
        case .topRightCorner: return [.topRight]
        case .bottomLeftCorner: return [.bottomLeft]
        case .bottomRightCorner: return [.bottomRight]
        case .centerPoint: return [.center]
        default: return []
        }
    }
    
    private func getCornerPosition(_ corner: CornerPosition, in size: CGSize) -> CGPoint {
        let margin: CGFloat = 40
        
        switch corner {
        case .topLeft:
            return CGPoint(x: margin, y: margin)
        case .topRight:
            return CGPoint(x: size.width - margin, y: margin)
        case .bottomLeft:
            return CGPoint(x: margin, y: size.height - margin)
        case .bottomRight:
            return CGPoint(x: size.width - margin, y: size.height - margin)
        case .center:
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
    
    enum CornerPosition {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
}

struct CornerTarget: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
                .opacity(opacity)
            
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 20, height: 20)
            
            Image(systemName: "scope")
                .font(.system(size: 30))
                .foregroundColor(.red)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.5
                opacity = 0.3
            }
        }
    }
}
