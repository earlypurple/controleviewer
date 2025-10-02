import Foundation
import Vision
import SwiftUI
import CoreML

// MARK: - Système d'Apprentissage Automatique des Gestes

@MainActor
class GestureLearningEngine: ObservableObject {
    @Published var isLearning = false
    @Published var learningProgress: Double = 0.0
    @Published var learnedGestures: [String: GesturePattern] = [:]
    @Published var recognitionAccuracy: Double = 0.85
    @Published var trainingDataCount: Int = 0
    
    private var gestureTrainingData: [GestureTrainingData] = []
    private var adaptiveThresholds: [DetectedGesture: AdaptiveThreshold] = [:]
    private let maxTrainingDataSize = 1000
    private var learningTimer: Timer?
    
    init() {
        setupAdaptiveThresholds()
        loadLearnedData()
        startContinuousLearning()
    }
    
    // MARK: - Configuration Initiale
    
    private func setupAdaptiveThresholds() {
        for gesture in [DetectedGesture.pointing, .pinch, .fist, .peace, .thumbsUp, .openHand, .swipeLeft, .swipeRight, .swipeUp, .swipeDown] {
            adaptiveThresholds[gesture] = AdaptiveThreshold(
                baseThreshold: 0.7,
                minThreshold: 0.5,
                maxThreshold: 0.95,
                adaptationRate: 0.01
            )
        }
    }
    
    // MARK: - Apprentissage Continu
    
    func startContinuousLearning() {
        learningTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processLearningCycle()
            }
        }
    }
    
    func stopLearning() {
        learningTimer?.invalidate()
        learningTimer = nil
        isLearning = false
    }
    
    private func processLearningCycle() {
        guard !gestureTrainingData.isEmpty else { return }
        
        isLearning = true
        
        // Analyser les données récentes
        let recentData = Array(gestureTrainingData.suffix(50))
        updateAdaptiveThresholds(with: recentData)
        updateGesturePatterns(with: recentData)
        
        // Calculer la précision
        calculateRecognitionAccuracy()
        
        // Mettre à jour le progrès
        learningProgress = min(1.0, Double(trainingDataCount) / 100.0)
        
        // Sauvegarder les données apprises
        saveLearnedData()
        
        isLearning = false
        
        print("🧠 Cycle d'apprentissage terminé - Précision: \(Int(recognitionAccuracy * 100))%")
    }
    
    // MARK: - Collecte de Données d'Entraînement
    
    func recordGestureData(
        gesture: DetectedGesture,
        handLandmarks: [VNRecognizedPoint],
        confidence: Float,
        userConfirmed: Bool = false
    ) {
        let trainingData = GestureTrainingData(
            gesture: gesture,
            handLandmarks: handLandmarks.map { HandLandmark(point: $0) },
            confidence: confidence,
            timestamp: Date(),
            userConfirmed: userConfirmed
        )
        
        gestureTrainingData.append(trainingData)
        trainingDataCount += 1
        
        // Limiter la taille des données
        if gestureTrainingData.count > maxTrainingDataSize {
            gestureTrainingData.removeFirst(gestureTrainingData.count - maxTrainingDataSize)
        }
        
        print("📊 Données d'entraînement collectées: \(gesture.description)")
    }
    
    // MARK: - Mise à Jour des Seuils Adaptatifs
    
    private func updateAdaptiveThresholds(with data: [GestureTrainingData]) {
        var gestureAccuracy: [DetectedGesture: (correct: Int, total: Int)] = [:]
        
        // Analyser la précision par geste
        for trainingData in data {
            let gesture = trainingData.gesture
            
            if gestureAccuracy[gesture] == nil {
                gestureAccuracy[gesture] = (0, 0)
            }
            
            gestureAccuracy[gesture]!.total += 1
            
            if trainingData.userConfirmed || trainingData.confidence > 0.8 {
                gestureAccuracy[gesture]!.correct += 1
            }
        }
        
        // Ajuster les seuils
        for (gesture, stats) in gestureAccuracy {
            guard let threshold = adaptiveThresholds[gesture] else { continue }
            
            let accuracy = Double(stats.correct) / Double(stats.total)
            
            if accuracy < 0.7 {
                // Précision faible, réduire le seuil
                threshold.adjustThreshold(delta: -threshold.adaptationRate)
            } else if accuracy > 0.9 {
                // Précision élevée, augmenter le seuil
                threshold.adjustThreshold(delta: threshold.adaptationRate)
            }
            
            print("🎯 Seuil ajusté pour \(gesture.description): \(String(format: "%.3f", threshold.currentThreshold))")
        }
    }
    
    // MARK: - Mise à Jour des Modèles de Gestes
    
    private func updateGesturePatterns(with data: [GestureTrainingData]) {
        var gestureGroups: [DetectedGesture: [GestureTrainingData]] = [:]
        
        // Grouper par type de geste
        for trainingData in data {
            if gestureGroups[trainingData.gesture] == nil {
                gestureGroups[trainingData.gesture] = []
            }
            gestureGroups[trainingData.gesture]!.append(trainingData)
        }
        
        // Créer ou mettre à jour les modèles
        for (gesture, gestureData) in gestureGroups {
            let pattern = createGesturePattern(from: gestureData)
            learnedGestures[gesture.description] = pattern
            print("📝 Modèle mis à jour pour: \(gesture.description)")
        }
    }
    
    private func createGesturePattern(from data: [GestureTrainingData]) -> GesturePattern {
        // Calculer les caractéristiques moyennes du geste
        var avgConfidence: Float = 0
        var landmarkVariations: [String: Double] = [:]
        
        for trainingData in data {
            avgConfidence += trainingData.confidence
            
            // Analyser les variations des points de repère
            for (index, landmark) in trainingData.handLandmarks.enumerated() {
                let key = "landmark_\(index)"
                if landmarkVariations[key] == nil {
                    landmarkVariations[key] = 0
                }
                landmarkVariations[key]! += Double(landmark.x + landmark.y) / 2.0
            }
        }
        
        avgConfidence /= Float(data.count)
        
        for key in landmarkVariations.keys {
            landmarkVariations[key]! /= Double(data.count)
        }
        
        return GesturePattern(
            averageConfidence: avgConfidence,
            landmarkPattern: landmarkVariations,
            sampleCount: data.count,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Calcul de Précision
    
    private func calculateRecognitionAccuracy() {
        guard !gestureTrainingData.isEmpty else { return }
        
        let recentData = Array(gestureTrainingData.suffix(100))
        let correctPredictions = recentData.filter { $0.userConfirmed || $0.confidence > 0.8 }.count
        
        recognitionAccuracy = Double(correctPredictions) / Double(recentData.count)
    }
    
    // MARK: - Prédiction Améliorée
    
    func enhancedGestureRecognition(
        gesture: DetectedGesture,
        handLandmarks: [VNRecognizedPoint],
        baseConfidence: Float
    ) -> (gesture: DetectedGesture, confidence: Float) {
        
        guard let threshold = adaptiveThresholds[gesture] else {
            return (gesture, baseConfidence)
        }
        
        // Vérifier le seuil adaptatif
        if baseConfidence < Float(threshold.currentThreshold) {
            return (.unknown, baseConfidence)
        }
        
        // Améliorer la confiance avec le modèle appris
        var enhancedConfidence = baseConfidence
        
        if let pattern = learnedGestures[gesture.description] {
            let patternMatch = calculatePatternMatch(handLandmarks: handLandmarks, pattern: pattern)
            enhancedConfidence = (baseConfidence + Float(patternMatch)) / 2.0
        }
        
        // Enregistrer pour l'apprentissage
        recordGestureData(gesture: gesture, handLandmarks: handLandmarks, confidence: enhancedConfidence)
        
        return (gesture, enhancedConfidence)
    }
    
    private func calculatePatternMatch(handLandmarks: [VNRecognizedPoint], pattern: GesturePattern) -> Double {
        var similarity: Double = 0
        let landmarkCount = min(handLandmarks.count, pattern.landmarkPattern.count)
        
        for (index, landmark) in handLandmarks.enumerated() {
            if index >= landmarkCount { break }
            
            let key = "landmark_\(index)"
            if let expectedValue = pattern.landmarkPattern[key] {
                let currentValue = Double(landmark.location.x + landmark.location.y) / 2.0
                let difference = abs(currentValue - expectedValue)
                similarity += max(0, 1.0 - difference)
            }
        }
        
        return similarity / Double(landmarkCount)
    }
    
    // MARK: - Feedback Utilisateur
    
    func confirmGestureCorrect(gesture: DetectedGesture) {
        // Mettre à jour les dernières données avec confirmation utilisateur
        if let lastIndex = gestureTrainingData.lastIndex(where: { $0.gesture == gesture }) {
            gestureTrainingData[lastIndex].userConfirmed = true
            print("✅ Geste confirmé: \(gesture.description)")
        }
    }
    
    func reportIncorrectGesture(detectedGesture: DetectedGesture, actualGesture: DetectedGesture) {
        // Ajuster négativement le seuil du geste incorrect
        if let threshold = adaptiveThresholds[detectedGesture] {
            threshold.adjustThreshold(delta: -threshold.adaptationRate * 2)
        }
        
        print("❌ Correction: \(detectedGesture.description) → \(actualGesture.description)")
    }
    
    // MARK: - Persistance
    
    private func saveLearnedData() {
        do {
            let data = try JSONEncoder().encode(learnedGestures)
            UserDefaults.standard.set(data, forKey: "LearnedGestures")
            
            let thresholdData = try JSONEncoder().encode(adaptiveThresholds)
            UserDefaults.standard.set(thresholdData, forKey: "AdaptiveThresholds")
            
            UserDefaults.standard.set(recognitionAccuracy, forKey: "RecognitionAccuracy")
            UserDefaults.standard.set(trainingDataCount, forKey: "TrainingDataCount")
        } catch {
            print("Erreur lors de la sauvegarde: \(error)")
        }
    }
    
    private func loadLearnedData() {
        if let data = UserDefaults.standard.data(forKey: "LearnedGestures") {
            do {
                learnedGestures = try JSONDecoder().decode([String: GesturePattern].self, from: data)
            } catch {
                print("Erreur lors du chargement des gestes: \(error)")
            }
        }
        
        if let thresholdData = UserDefaults.standard.data(forKey: "AdaptiveThresholds") {
            do {
                adaptiveThresholds = try JSONDecoder().decode([DetectedGesture: AdaptiveThreshold].self, from: thresholdData)
            } catch {
                print("Erreur lors du chargement des seuils: \(error)")
            }
        }
        
        recognitionAccuracy = UserDefaults.standard.double(forKey: "RecognitionAccuracy")
        if recognitionAccuracy == 0 { recognitionAccuracy = 0.85 }
        
        trainingDataCount = UserDefaults.standard.integer(forKey: "TrainingDataCount")
    }
    
    // MARK: - Statistiques
    
    func getGestureStatistics() -> [String: Any] {
        return [
            "learned_gestures": learnedGestures.count,
            "training_samples": trainingDataCount,
            "recognition_accuracy": recognitionAccuracy,
            "adaptive_thresholds": adaptiveThresholds.mapValues { $0.currentThreshold }
        ]
    }
    
    func resetLearning() {
        gestureTrainingData.removeAll()
        learnedGestures.removeAll()
        trainingDataCount = 0
        recognitionAccuracy = 0.85
        setupAdaptiveThresholds()
        print("🔄 Apprentissage réinitialisé")
    }
}

// MARK: - Structures de Données

struct GestureTrainingData: Codable {
    let gesture: DetectedGesture
    let handLandmarks: [HandLandmark]
    let confidence: Float
    let timestamp: Date
    var userConfirmed: Bool
}

struct HandLandmark: Codable {
    let x: Float
    let y: Float
    let confidence: Float
    
    init(point: VNRecognizedPoint) {
        self.x = Float(point.location.x)
        self.y = Float(point.location.y)
        self.confidence = point.confidence
    }
}

struct GesturePattern: Codable {
    let averageConfidence: Float
    let landmarkPattern: [String: Double]
    let sampleCount: Int
    let lastUpdated: Date
}

class AdaptiveThreshold: Codable {
    var currentThreshold: Double
    let minThreshold: Double
    let maxThreshold: Double
    let adaptationRate: Double
    
    init(baseThreshold: Double, minThreshold: Double, maxThreshold: Double, adaptationRate: Double) {
        self.currentThreshold = baseThreshold
        self.minThreshold = minThreshold
        self.maxThreshold = maxThreshold
        self.adaptationRate = adaptationRate
    }
    
    func adjustThreshold(delta: Double) {
        currentThreshold = max(minThreshold, min(maxThreshold, currentThreshold + delta))
    }
}
