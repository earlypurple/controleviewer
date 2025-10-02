//
//  InterfaceManager.swift
//  controleviewer
//
//  Gestionnaire pour l'interface professionnelle
//

import SwiftUI
import Combine

@MainActor
class InterfaceManager: ObservableObject {
    @Published var selectedSection: String = "Dashboard"
    @Published var showSettings = false
    @Published var showCalibration = false
    @Published var showStatistics = false
    
    // Références aux managers
    private var cameraManager: CameraManager?
    private var gestureController: GestureController?
    private var aiEngine: AIGestureEngine?
    private var spatialManager: SpatialVisionManager?
    private var cloudManager: CloudIntelligenceManager?
    
    // Méthodes wrapper pour éviter les problèmes de binding
    
    func configure(
        camera: CameraManager,
        gesture: GestureController,
        ai: AIGestureEngine,
        spatial: SpatialVisionManager,
        cloud: CloudIntelligenceManager
    ) {
        self.cameraManager = camera
        self.gestureController = gesture
        self.aiEngine = ai
        self.spatialManager = spatial
        self.cloudManager = cloud
    }
    
    // MARK: - Actions de l'interface
    
    func startCalibration() {
        gestureController?.startCalibration()
        showCalibration = true
    }
    
    func resetCalibration() {
        gestureController?.resetCalibration()
    }
    
    func startLearning() {
        aiEngine?.startLearning()
    }
    
    func stopLearning() {
        aiEngine?.stopLearning()
    }
    
    func startCamera() {
        cameraManager?.startSession()
    }
    
    func stopCamera() {
        cameraManager?.stopCamera()
    }
    
    func simulateClick() {
        gestureController?.simulateClick()
    }
    
    func simulateScroll(direction: ScrollDirection, amount: Int = 3) {
        gestureController?.simulateScroll(direction: direction, amount: amount)
    }
    
    func simulateSwipe(direction: SwipeDirection) {
        gestureController?.simulateSwipe(direction: direction)
    }
    
    func simulateZoom(factor: Double) {
        gestureController?.simulateZoom(factor: factor)
    }
    
    // MARK: - Getters pour les propriétés
    
    var isDetecting: Bool {
        cameraManager?.isDetecting ?? false
    }
    
    var currentFPS: Double {
        Double(cameraManager?.currentFPS ?? 0)
    }
    
    var lastDetectedGesture: String {
        gestureController?.lastDetectedGesture ?? "Aucun"
    }
    
    var learnedGestures: [String] {
        aiEngine?.learnedGestures ?? []
    }
    
    var gestureAccuracy: Double {
        aiEngine?.modelAccuracy ?? 0.0
    }
    
    var isLearning: Bool {
        aiEngine?.isLearning ?? false
    }
    
    var isConnected: Bool {
        cloudManager?.isCloudEnabled ?? false
    }
    
    var networkLatency: Double {
        // Simulation de latence réseau
        cloudManager?.isCloudEnabled == true ? Double.random(in: 15...50) : 0.0
    }
}
