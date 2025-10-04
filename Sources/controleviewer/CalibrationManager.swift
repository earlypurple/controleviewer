//
//  CalibrationManager.swift
//  GestureControl Pro
//
//  Gestionnaire de calibration pour optimiser la détection et le contrôle
//

import Foundation
import Vision
import SwiftUI
import Combine

@MainActor
class CalibrationManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isCalibrating = false
    @Published var currentStep: CalibrationStep = .introduction
    @Published var progress: Double = 0.0
    @Published var calibrationData = CalibrationData()
    @Published var statusMessage = ""
    @Published var samplesCollected = 0
    
    // MARK: - Private Properties
    private var cornerSamples: [ScreenCorner: [CGPoint]] = [:]
    private var gestureSamples: [GestureType: [Float]] = [:]
    private let requiredSamplesPerCorner = 10
    private let requiredSamplesPerGesture = 5
    private var calibrationCancellables = Set<AnyCancellable>()
    
    // MARK: - Calibration Steps
    enum CalibrationStep: Int, CaseIterable {
        case introduction = 0
        case handPosition
        case topLeftCorner
        case topRightCorner
        case bottomLeftCorner
        case bottomRightCorner
        case centerPoint
        case gestureTest
        case completed
        
        var title: String {
            switch self {
            case .introduction: return "Introduction"
            case .handPosition: return "Position de la Main"
            case .topLeftCorner: return "Coin Supérieur Gauche"
            case .topRightCorner: return "Coin Supérieur Droit"
            case .bottomLeftCorner: return "Coin Inférieur Gauche"
            case .bottomRightCorner: return "Coin Inférieur Droit"
            case .centerPoint: return "Centre de l'Écran"
            case .gestureTest: return "Test des Gestes"
            case .completed: return "Calibration Terminée"
            }
        }
        
        var instructions: String {
            switch self {
            case .introduction:
                return "Cette calibration va optimiser la détection pour votre configuration. Durée estimée: 2 minutes."
            case .handPosition:
                return "Placez votre main ouverte au centre de la caméra, à environ 50cm de distance. Gardez cette position pendant 3 secondes."
            case .topLeftCorner:
                return "Pointez avec votre index vers le COIN SUPÉRIEUR GAUCHE de votre écran. Maintenez la position."
            case .topRightCorner:
                return "Pointez avec votre index vers le COIN SUPÉRIEUR DROIT de votre écran. Maintenez la position."
            case .bottomLeftCorner:
                return "Pointez avec votre index vers le COIN INFÉRIEUR GAUCHE de votre écran. Maintenez la position."
            case .bottomRightCorner:
                return "Pointez avec votre index vers le COIN INFÉRIEUR DROIT de votre écran. Maintenez la position."
            case .centerPoint:
                return "Pointez avec votre index vers le CENTRE de votre écran. Maintenez la position."
            case .gestureTest:
                return "Effectuez successivement: Poing fermé ✊, Peace sign ✌️, Pouce levé 👍. Maintenez chaque geste 2 secondes."
            case .completed:
                return "Calibration terminée avec succès! Les paramètres ont été optimisés pour votre utilisation."
            }
        }
        
        var icon: String {
            switch self {
            case .introduction: return "info.circle"
            case .handPosition: return "hand.raised"
            case .topLeftCorner, .topRightCorner, .bottomLeftCorner, .bottomRightCorner, .centerPoint:
                return "scope"
            case .gestureTest: return "hand.point.up.left"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    enum ScreenCorner {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    // MARK: - Public Methods
    func startCalibration() {
        isCalibrating = true
        currentStep = .introduction
        progress = 0.0
        cornerSamples.removeAll()
        gestureSamples.removeAll()
        samplesCollected = 0
        statusMessage = "Préparation de la calibration..."
        
        // Réinitialiser les données de calibration
        calibrationData = CalibrationData()
    }
    
    func nextStep() {
        guard let nextStep = CalibrationStep(rawValue: currentStep.rawValue + 1) else {
            completeCalibration()
            return
        }
        
        currentStep = nextStep
        samplesCollected = 0
        updateProgress()
        statusMessage = nextStep.instructions
    }
    
    func previousStep() {
        guard currentStep.rawValue > 0,
              let prevStep = CalibrationStep(rawValue: currentStep.rawValue - 1) else { return }
        
        currentStep = prevStep
        samplesCollected = 0
        updateProgress()
        statusMessage = prevStep.instructions
    }
    
    func cancelCalibration() {
        isCalibrating = false
        currentStep = .introduction
        progress = 0.0
        statusMessage = "Calibration annulée"
    }
    
    func processCalibrationSample(gesture: DetectedGesture) {
        guard isCalibrating else { return }
        
        switch currentStep {
        case .handPosition:
            // Collecter les données de position de référence
            if gesture.type == .openHand {
                calibrationData.referenceHandPosition = gesture.landmarks
                samplesCollected += 1
                statusMessage = "Échantillons collectés: \(samplesCollected)/30"
                
                if samplesCollected >= 30 {
                    nextStep()
                }
            }
            
        case .topLeftCorner:
            collectCornerSample(gesture: gesture, corner: .topLeft)
            
        case .topRightCorner:
            collectCornerSample(gesture: gesture, corner: .topRight)
            
        case .bottomLeftCorner:
            collectCornerSample(gesture: gesture, corner: .bottomLeft)
            
        case .bottomRightCorner:
            collectCornerSample(gesture: gesture, corner: .bottomRight)
            
        case .centerPoint:
            collectCornerSample(gesture: gesture, corner: .center)
            
        case .gestureTest:
            collectGestureSample(gesture: gesture)
            
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func collectCornerSample(gesture: DetectedGesture, corner: ScreenCorner) {
        guard gesture.type == .pointingIndex else { return }
        
        // Extraire la position de l'index tip (point 5)
        guard gesture.landmarks.count > 5 else { return }
        let indexTip = gesture.landmarks[5]
        
        if cornerSamples[corner] == nil {
            cornerSamples[corner] = []
        }
        
        cornerSamples[corner]?.append(indexTip)
        samplesCollected = cornerSamples[corner]?.count ?? 0
        
        statusMessage = "Échantillons collectés: \(samplesCollected)/\(requiredSamplesPerCorner)"
        
        if samplesCollected >= requiredSamplesPerCorner {
            // Calculer la moyenne des positions
            if let samples = cornerSamples[corner] {
                let avgPoint = averagePoint(samples)
                updateCalibrationDataForCorner(corner, point: avgPoint)
            }
            nextStep()
        }
    }
    
    private func collectGestureSample(gesture: DetectedGesture) {
        if gestureSamples[gesture.type] == nil {
            gestureSamples[gesture.type] = []
        }
        
        gestureSamples[gesture.type]?.append(gesture.confidence)
        
        // Compter le total d'échantillons de tous les gestes
        let totalSamples = gestureSamples.values.reduce(0) { $0 + $1.count }
        samplesCollected = totalSamples
        
        let requiredTotal = requiredSamplesPerGesture * 3 // 3 gestes principaux
        statusMessage = "Gestes testés: \(samplesCollected)/\(requiredTotal)"
        
        if samplesCollected >= requiredTotal {
            calculateGestureThresholds()
            nextStep()
        }
    }
    
    private func updateCalibrationDataForCorner(_ corner: ScreenCorner, point: CGPoint) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        switch corner {
        case .topLeft:
            calibrationData.topLeftMapping = (point, CGPoint(x: 0, y: 0))
        case .topRight:
            calibrationData.topRightMapping = (point, CGPoint(x: screenFrame.width, y: 0))
        case .bottomLeft:
            calibrationData.bottomLeftMapping = (point, CGPoint(x: 0, y: screenFrame.height))
        case .bottomRight:
            calibrationData.bottomRightMapping = (point, CGPoint(x: screenFrame.width, y: screenFrame.height))
        case .center:
            calibrationData.centerMapping = (point, CGPoint(x: screenFrame.width / 2, y: screenFrame.height / 2))
        }
        
        // Recalculer la transformation affine
        calculateAffineTransform()
    }
    
    private func calculateAffineTransform() {
        // Utiliser les 4 coins pour calculer une transformation affine précise
        guard let topLeft = calibrationData.topLeftMapping,
              let topRight = calibrationData.topRightMapping,
              let bottomLeft = calibrationData.bottomLeftMapping,
              let bottomRight = calibrationData.bottomRightMapping else { return }
        
        // Calculer la transformation basée sur les points de calibration
        let sourcePoints = [topLeft.0, topRight.0, bottomLeft.0, bottomRight.0]
        let destPoints = [topLeft.1, topRight.1, bottomLeft.1, bottomRight.1]
        
        // Calcul de la transformation (perspective homography simplifiée)
        calibrationData.screenMapping = computePerspectiveTransform(
            sourcePoints: sourcePoints,
            destinationPoints: destPoints
        )
        
        // Calculer les facteurs de mise à l'échelle
        calibrationData.scalingFactor = calculateScalingFactor(sourcePoints: sourcePoints, destPoints: destPoints)
        calibrationData.translationOffset = calculateTranslationOffset(sourcePoints: sourcePoints, destPoints: destPoints)
    }
    
    private func calculateGestureThresholds() {
        // Calculer les seuils optimaux pour chaque geste
        for (gestureType, confidences) in gestureSamples {
            let avgConfidence = confidences.reduce(0, +) / Float(confidences.count)
            let minConfidence = confidences.min() ?? 0.7
            
            // Utiliser un seuil légèrement inférieur au minimum observé
            calibrationData.gestureThresholds[gestureType] = max(minConfidence * 0.9, 0.6)
        }
    }
    
    private func completeCalibration() {
        calibrationData.isCalibrated = true
        calibrationData.calibrationDate = Date()
        
        // Sauvegarder les données de calibration
        saveCalibrationData()
        
        isCalibrating = false
        statusMessage = "Calibration terminée avec succès!"
        
        // Notifier que la calibration est terminée
        NotificationCenter.default.post(name: .calibrationCompleted, object: calibrationData)
    }
    
    private func updateProgress() {
        let totalSteps = Double(CalibrationStep.allCases.count - 1) // -1 pour l'introduction
        progress = Double(currentStep.rawValue) / totalSteps
    }
    
    // MARK: - Utility Methods
    private func averagePoint(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        
        return CGPoint(
            x: sumX / Double(points.count),
            y: sumY / Double(points.count)
        )
    }
    
    private func computePerspectiveTransform(sourcePoints: [CGPoint], destinationPoints: [CGPoint]) -> CGAffineTransform {
        // Transformation affine simplifiée (pour une transformation complète, utiliser vDSP ou Accelerate)
        // Ici on utilise une transformation linéaire basée sur les coins
        
        guard sourcePoints.count >= 2, destinationPoints.count >= 2 else {
            return .identity
        }
        
        let src0 = sourcePoints[0]
        let src1 = sourcePoints[1]
        let dst0 = destinationPoints[0]
        let dst1 = destinationPoints[1]
        
        // Calcul de la mise à l'échelle
        let scaleX = (dst1.x - dst0.x) / (src1.x - src0.x)
        let scaleY = (dst1.y - dst0.y) / (src1.y - src0.y)
        
        // Calcul de la translation
        let tx = dst0.x - src0.x * scaleX
        let ty = dst0.y - src0.y * scaleY
        
        return CGAffineTransform(a: scaleX, b: 0, c: 0, d: scaleY, tx: tx, ty: ty)
    }
    
    private func calculateScalingFactor(sourcePoints: [CGPoint], destPoints: [CGPoint]) -> CGPoint {
        guard sourcePoints.count >= 2, destPoints.count >= 2 else {
            return CGPoint(x: 1.0, y: 1.0)
        }
        
        // Calculer le facteur d'échelle moyen
        let srcWidth = abs(sourcePoints[1].x - sourcePoints[0].x)
        let srcHeight = abs(sourcePoints[2].y - sourcePoints[0].y)
        let dstWidth = abs(destPoints[1].x - destPoints[0].x)
        let dstHeight = abs(destPoints[2].y - destPoints[0].y)
        
        return CGPoint(
            x: dstWidth / max(srcWidth, 0.01),
            y: dstHeight / max(srcHeight, 0.01)
        )
    }
    
    private func calculateTranslationOffset(sourcePoints: [CGPoint], destPoints: [CGPoint]) -> CGPoint {
        guard !sourcePoints.isEmpty, !destPoints.isEmpty else {
            return .zero
        }
        
        // Utiliser le premier point comme référence
        return CGPoint(
            x: destPoints[0].x - sourcePoints[0].x,
            y: destPoints[0].y - sourcePoints[0].y
        )
    }
    
    private func saveCalibrationData() {
        // Sauvegarder dans UserDefaults ou un fichier
        if let encoded = try? JSONEncoder().encode(calibrationData) {
            UserDefaults.standard.set(encoded, forKey: "CalibrationData")
        }
    }
    
    func loadCalibrationData() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: "CalibrationData"),
              let decoded = try? JSONDecoder().decode(CalibrationData.self, from: data) else {
            return false
        }
        
        calibrationData = decoded
        return decoded.isCalibrated
    }
}

// MARK: - CalibrationData Structure
struct CalibrationData: Codable {
    var isCalibrated = false
    var calibrationDate: Date?
    
    // Position de référence
    var referenceHandPosition: [CGPoint] = []
    
    // Mapping des coins
    var topLeftMapping: (CGPoint, CGPoint)?
    var topRightMapping: (CGPoint, CGPoint)?
    var bottomLeftMapping: (CGPoint, CGPoint)?
    var bottomRightMapping: (CGPoint, CGPoint)?
    var centerMapping: (CGPoint, CGPoint)?
    
    // Transformation
    var screenMapping: CGAffineTransform = .identity
    var scalingFactor: CGPoint = CGPoint(x: 1.0, y: 1.0)
    var translationOffset: CGPoint = .zero
    
    // Seuils de détection des gestes
    var gestureThresholds: [GestureType: Float] = [:]
    
    // Paramètres de lissage
    var smoothingFactor: Double = 0.3
    var movementSensitivity: Double = 1.0
    
    // Zones mortes (dead zones) pour éviter les micro-mouvements
    var deadZoneRadius: Double = 5.0
    
    // Codable conformance pour les tuples
    enum CodingKeys: String, CodingKey {
        case isCalibrated, calibrationDate, referenceHandPosition
        case screenMapping, scalingFactor, translationOffset
        case gestureThresholds, smoothingFactor, movementSensitivity, deadZoneRadius
        case topLeftCameraPoint, topLeftScreenPoint
        case topRightCameraPoint, topRightScreenPoint
        case bottomLeftCameraPoint, bottomLeftScreenPoint
        case bottomRightCameraPoint, bottomRightScreenPoint
        case centerCameraPoint, centerScreenPoint
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isCalibrated = try container.decode(Bool.self, forKey: .isCalibrated)
        calibrationDate = try container.decodeIfPresent(Date.self, forKey: .calibrationDate)
        referenceHandPosition = try container.decode([CGPoint].self, forKey: .referenceHandPosition)
        scalingFactor = try container.decode(CGPoint.self, forKey: .scalingFactor)
        translationOffset = try container.decode(CGPoint.self, forKey: .translationOffset)
        smoothingFactor = try container.decode(Double.self, forKey: .smoothingFactor)
        movementSensitivity = try container.decode(Double.self, forKey: .movementSensitivity)
        deadZoneRadius = try container.decode(Double.self, forKey: .deadZoneRadius)
        
        // Décoder les mappings de coins
        if let tlCam = try? container.decode(CGPoint.self, forKey: .topLeftCameraPoint),
           let tlScr = try? container.decode(CGPoint.self, forKey: .topLeftScreenPoint) {
            topLeftMapping = (tlCam, tlScr)
        }
        if let trCam = try? container.decode(CGPoint.self, forKey: .topRightCameraPoint),
           let trScr = try? container.decode(CGPoint.self, forKey: .topRightScreenPoint) {
            topRightMapping = (trCam, trScr)
        }
        if let blCam = try? container.decode(CGPoint.self, forKey: .bottomLeftCameraPoint),
           let blScr = try? container.decode(CGPoint.self, forKey: .bottomLeftScreenPoint) {
            bottomLeftMapping = (blCam, blScr)
        }
        if let brCam = try? container.decode(CGPoint.self, forKey: .bottomRightCameraPoint),
           let brScr = try? container.decode(CGPoint.self, forKey: .bottomRightScreenPoint) {
            bottomRightMapping = (brCam, brScr)
        }
        if let cCam = try? container.decode(CGPoint.self, forKey: .centerCameraPoint),
           let cScr = try? container.decode(CGPoint.self, forKey: .centerScreenPoint) {
            centerMapping = (cCam, cScr)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isCalibrated, forKey: .isCalibrated)
        try container.encodeIfPresent(calibrationDate, forKey: .calibrationDate)
        try container.encode(referenceHandPosition, forKey: .referenceHandPosition)
        try container.encode(scalingFactor, forKey: .scalingFactor)
        try container.encode(translationOffset, forKey: .translationOffset)
        try container.encode(smoothingFactor, forKey: .smoothingFactor)
        try container.encode(movementSensitivity, forKey: .movementSensitivity)
        try container.encode(deadZoneRadius, forKey: .deadZoneRadius)
        
        // Encoder les mappings de coins
        if let (cam, scr) = topLeftMapping {
            try container.encode(cam, forKey: .topLeftCameraPoint)
            try container.encode(scr, forKey: .topLeftScreenPoint)
        }
        if let (cam, scr) = topRightMapping {
            try container.encode(cam, forKey: .topRightCameraPoint)
            try container.encode(scr, forKey: .topRightScreenPoint)
        }
        if let (cam, scr) = bottomLeftMapping {
            try container.encode(cam, forKey: .bottomLeftCameraPoint)
            try container.encode(scr, forKey: .bottomLeftScreenPoint)
        }
        if let (cam, scr) = bottomRightMapping {
            try container.encode(cam, forKey: .bottomRightCameraPoint)
            try container.encode(scr, forKey: .bottomRightScreenPoint)
        }
        if let (cam, scr) = centerMapping {
            try container.encode(cam, forKey: .centerCameraPoint)
            try container.encode(scr, forKey: .centerScreenPoint)
        }
    }
}

// Notification pour la fin de calibration
extension Notification.Name {
    static let calibrationCompleted = Notification.Name("calibrationCompleted")
}
