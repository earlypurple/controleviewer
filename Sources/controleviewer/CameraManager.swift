import AVFoundation
import Vision
import SwiftUI
import CoreImage
import Cocoa

// MARK: - Types de gestes détectés

enum DetectedGesture {
    case pointing       // Index pointé
    case peace         // Signe de paix (index + majeur)
    case pinch         // Pince (pouce + index)
    case fist          // Poing fermé
    case openHand      // Main ouverte
    case thumbsUp      // Pouce levé
    case swipeLeft     // Balayage gauche
    case swipeRight    // Balayage droite
    case swipeUp       // Balayage haut
    case swipeDown     // Balayage bas
    case unknown       // Geste non reconnu
    
    var description: String {
        switch self {
        case .pointing: return "Pointage"
        case .peace: return "Paix"
        case .pinch: return "Pince"
        case .fist: return "Poing"
        case .openHand: return "Main ouverte"
        case .thumbsUp: return "Pouce levé"
        case .swipeLeft: return "Balayage gauche"
        case .swipeRight: return "Balayage droite"
        case .swipeUp: return "Balayage haut"
        case .swipeDown: return "Balayage bas"
        case .unknown: return "Inconnu"
        }
    }
}

final class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isActive = false
    @Published var isRunning = false
    @Published var lastDetectedGesture: DetectedGesture? = nil
    @Published var gestureConfidence: Float = 0.0
    @Published var isGestureDetected = false
    @Published var currentFrame: CGImage? = nil
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // Preview layer pour l'affichage
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var gestureController: GestureController?
    var gestureConfigManager: GestureConfigurationManager?
    var learningEngine: GestureLearningEngine?
    
    // Amélioration de la précision
    private var gestureStabilityBuffer: [DetectedGesture] = []
    private var confidenceBuffer: [Float] = []
    private let bufferSize = 5
    private var lastGestureTime = Date()
    private let minimumGestureInterval: TimeInterval = 0.3
    
    // Propriétés pour l'interface professionnelle
    var currentFPS: Int {
        return 30 // Simulation
    }
    
    var isDetecting: Bool {
        return isActive && isRunning
    }
    
    // Historique des gestes pour la détection de mouvement
    private var handPositionHistory: [CGPoint] = []
    private let maxHistorySize = 10
    
    override init() {
        super.init()
        setupCamera()
    }
    
    // MARK: - Public Methods
    
    public func getSession() -> AVCaptureSession {
        return captureSession
    }
    
    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Impossible d'accéder à la caméra frontale")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
        } catch {
            print("Erreur lors de la configuration de la caméra: \(error)")
        }
    }
    
    func startCamera() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isRunning = true
                self?.isActive = true
                print("📹 Caméra démarrée - Détection de gestes active")
            }
        }
    }
    
    func stopCamera() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.isActive = false
                print("📹 Caméra arrêtée")
            }
        }
    }
    
    func startSession() {
        startCamera()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Mettre à jour l'image affichée
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async { [weak self] in
                self?.currentFrame = cgImage
            }
        }
        
        // Analyser les gestes de la main
        performHandGestureAnalysis(pixelBuffer: pixelBuffer)
    }
    
    private func performHandGestureAnalysis(pixelBuffer: CVPixelBuffer) {
        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let observations = request.results as? [VNHumanHandPoseObservation],
                  let observation = observations.first else { return }
            
            self?.processHandGestures(observation)
        }
        
        request.maximumHandCount = 1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func processHandGestures(_ observation: VNHumanHandPoseObservation) {
        do {
            // Détection des points clés de la main
            let thumbTip = try observation.recognizedPoint(.thumbTip)
            let indexTip = try observation.recognizedPoint(.indexTip)
            let middleTip = try observation.recognizedPoint(.middleTip)
            let ringTip = try observation.recognizedPoint(.ringTip)
            let littleTip = try observation.recognizedPoint(.littleTip)
            let wrist = try observation.recognizedPoint(.wrist)
            
            // Vérifier la confiance des points
            guard thumbTip.confidence > 0.7 && indexTip.confidence > 0.7 && 
                  middleTip.confidence > 0.7 && wrist.confidence > 0.7 else { return }
            
            // Ajouter la position à l'historique pour détecter les mouvements
            updateHandPositionHistory(indexTip.location)
            
            // Détecter différents gestes
            let rawGesture = detectGesture(
                thumbTip: thumbTip,
                indexTip: indexTip,
                middleTip: middleTip,
                ringTip: ringTip,
                littleTip: littleTip,
                wrist: wrist
            )
            
            // Calculer la confiance de base
            let baseConfidence = (thumbTip.confidence + indexTip.confidence + middleTip.confidence + 
                                ringTip.confidence + littleTip.confidence) / 5.0
            
            // Créer une copie sécurisée des landmarks
            let landmarksCopy = [thumbTip, indexTip, middleTip, ringTip, littleTip, wrist]
            let indexLocation = indexTip.location
            
            // Traitement avec apprentissage automatique
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                // Utiliser l'apprentissage automatique pour améliorer la reconnaissance
                let enhancedResult = self.learningEngine?.enhancedGestureRecognition(
                    gesture: rawGesture,
                    handLandmarks: landmarksCopy,
                    baseConfidence: baseConfidence
                ) ?? (rawGesture, baseConfidence)
                
                // Appliquer la stabilisation avec les résultats améliorés
                if let stabilizedResult = self.stabilizeGestureDetectionSync(enhancedResult.gesture, confidence: enhancedResult.confidence) {
                    let (gesture, finalConfidence) = stabilizedResult
                    
                    // Mettre à jour l'état
                    self.lastDetectedGesture = gesture
                    self.gestureConfidence = finalConfidence
                    self.isGestureDetected = finalConfidence > 0.7
                    
                    // Traiter le geste
                    self.gestureController?.processDetectedGesture(gesture, at: indexLocation, confidence: finalConfidence)
                    
                    // Informer l'apprentissage du résultat
                    if finalConfidence > 0.8 {
                        print("🧠 Geste appris: \(gesture.description) (confiance: \(Int(finalConfidence * 100))%)")
                    }
                }
            }
            
        } catch {
            print("Erreur lors de la détection de geste: \(error)")
        }
    }
    
    private func updateHandPositionHistory(_ position: CGPoint) {
        handPositionHistory.append(position)
        if handPositionHistory.count > maxHistorySize {
            handPositionHistory.removeFirst()
        }
    }
    
    private func detectGesture(
        thumbTip: VNRecognizedPoint,
        indexTip: VNRecognizedPoint,
        middleTip: VNRecognizedPoint,
        ringTip: VNRecognizedPoint,
        littleTip: VNRecognizedPoint,
        wrist: VNRecognizedPoint
    ) -> DetectedGesture {
        
        // Calculer les distances entre les doigts avec précision améliorée
        let thumbIndexDistance = distance(from: thumbTip.location, to: indexTip.location)
        
        // Détecter les mouvements de balayage d'abord (priorité aux mouvements dynamiques)
        if let swipeDirection = detectSwipeGesture() {
            return swipeDirection
        }
        
        // Geste de pince (pouce et index proches) - Précision améliorée
        if thumbIndexDistance < 0.04 && thumbTip.confidence > 0.85 && indexTip.confidence > 0.85 {
            return .pinch
        }
        
        // Pouce levé - Vérification plus stricte
        if isThumbUp(thumbTip: thumbTip, indexTip: indexTip, wrist: wrist) {
            return .thumbsUp
        }
        
        // Geste de pointage (index levé, autres baissés) - Précision améliorée
        if isFingerExtended(tip: indexTip, wrist: wrist) &&
           !isFingerExtended(tip: middleTip, wrist: wrist) &&
           !isFingerExtended(tip: ringTip, wrist: wrist) &&
           !isFingerExtended(tip: littleTip, wrist: wrist) &&
           indexTip.confidence > 0.8 {
            return .pointing
        }
        
        // Geste de paix (index et majeur levés) - Vérification stricte
        if isFingerExtended(tip: indexTip, wrist: wrist) &&
           isFingerExtended(tip: middleTip, wrist: wrist) &&
           !isFingerExtended(tip: ringTip, wrist: wrist) &&
           !isFingerExtended(tip: littleTip, wrist: wrist) &&
           indexTip.confidence > 0.8 && middleTip.confidence > 0.8 {
            return .peace
        }
        
        // Poing fermé (tous les doigts baissés) - Seuil strict
        if !isFingerExtended(tip: indexTip, wrist: wrist) &&
           !isFingerExtended(tip: middleTip, wrist: wrist) &&
           !isFingerExtended(tip: ringTip, wrist: wrist) &&
           !isFingerExtended(tip: littleTip, wrist: wrist) &&
           wrist.confidence > 0.8 {
            return .fist
        }
        
        // Main ouverte (tous les doigts levés) - Confiance élevée requise
        if isFingerExtended(tip: thumbTip, wrist: wrist) &&
           isFingerExtended(tip: indexTip, wrist: wrist) &&
           isFingerExtended(tip: middleTip, wrist: wrist) &&
           isFingerExtended(tip: ringTip, wrist: wrist) &&
           isFingerExtended(tip: littleTip, wrist: wrist) &&
           (thumbTip.confidence + indexTip.confidence + middleTip.confidence + 
            ringTip.confidence + littleTip.confidence) / 5.0 > 0.85 {
            return .openHand
        }
        
        return .unknown
    }
    
    private func detectSwipeGesture() -> DetectedGesture? {
        guard handPositionHistory.count >= 6 else { return nil } // Plus d'échantillons pour plus de précision
        
        let recent = Array(handPositionHistory.suffix(6))
        let startPoint = recent.first!
        let endPoint = recent.last!
        
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        
        // Seuil minimum pour considérer un mouvement comme un balayage (plus strict)
        guard distance > 0.08 else { return nil }
        
        // Vérifier la consistance du mouvement (tous les points vont dans la même direction)
        var consistentDirection = true
        for i in 1..<recent.count {
            let currentDeltaX = recent[i].x - recent[i-1].x
            let currentDeltaY = recent[i].y - recent[i-1].y
            
            // Vérifier si la direction est cohérente
            if (deltaX > 0 && currentDeltaX < 0) || (deltaX < 0 && currentDeltaX > 0) ||
               (deltaY > 0 && currentDeltaY < 0) || (deltaY < 0 && currentDeltaY > 0) {
                consistentDirection = false
                break
            }
        }
        
        guard consistentDirection else { return nil }
        
        // Déterminer la direction du balayage avec plus de précision
        if abs(deltaX) > abs(deltaY) * 1.5 { // Mouvement principalement horizontal
            return deltaX > 0 ? .swipeRight : .swipeLeft
        } else if abs(deltaY) > abs(deltaX) * 1.5 { // Mouvement principalement vertical
            return deltaY > 0 ? .swipeUp : .swipeDown
        }
        
        return nil // Mouvement diagonal ou ambigu
    }
    
    private func isThumbUp(thumbTip: VNRecognizedPoint, indexTip: VNRecognizedPoint, wrist: VNRecognizedPoint) -> Bool {
        // Pouce levé : pouce plus haut que l'index et le poignet
        return thumbTip.location.y > indexTip.location.y + 0.05 &&
               thumbTip.location.y > wrist.location.y + 0.15
    }
    
    private func isFingerExtended(tip: VNRecognizedPoint, wrist: VNRecognizedPoint) -> Bool {
        // Un doigt est considéré comme étendu si la pointe est plus haute que le poignet
        return tip.location.y > wrist.location.y + 0.1
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Stabilisation des Gestes pour Améliorer la Précision
    
    private func stabilizeGestureDetectionSync(_ gesture: DetectedGesture, confidence: Float) -> (DetectedGesture, Float)? {
        // Vérifier l'intervalle minimum entre gestes
        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) >= minimumGestureInterval else {
            return nil
        }
        
        // Ajouter au buffer de stabilité
        gestureStabilityBuffer.append(gesture)
        confidenceBuffer.append(confidence)
        
        // Maintenir la taille du buffer
        if gestureStabilityBuffer.count > bufferSize {
            gestureStabilityBuffer.removeFirst()
            confidenceBuffer.removeFirst()
        }
        
        // Nécessite au moins 3 échantillons pour la stabilisation
        guard gestureStabilityBuffer.count >= 3 else { return nil }
        
        // Analyser la consistance du geste
        let recentGestures = Array(gestureStabilityBuffer.suffix(3))
        let recentConfidences = Array(confidenceBuffer.suffix(3))
        
        // Vérifier si le geste est consistant
        let consistentGesture = findConsistentGesture(recentGestures)
        let averageConfidence = recentConfidences.reduce(0, +) / Float(recentConfidences.count)
        
        // Fallback sans gestionnaire de configuration
        if averageConfidence > 0.75 && consistentGesture != .unknown {
            lastGestureTime = now
            return (consistentGesture, averageConfidence)
        }
        
        return nil
    }
    
    private func stabilizeGestureDetection(_ gesture: DetectedGesture, confidence: Float) -> (DetectedGesture, Float)? {
        // Vérifier l'intervalle minimum entre gestes
        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) >= minimumGestureInterval else {
            return nil
        }
        
        // Ajouter au buffer de stabilité
        gestureStabilityBuffer.append(gesture)
        confidenceBuffer.append(confidence)
        
        // Maintenir la taille du buffer
        if gestureStabilityBuffer.count > bufferSize {
            gestureStabilityBuffer.removeFirst()
            confidenceBuffer.removeFirst()
        }
        
        // Nécessite au moins 3 échantillons pour la stabilisation
        guard gestureStabilityBuffer.count >= 3 else { return nil }
        
        // Analyser la consistance du geste
        let recentGestures = Array(gestureStabilityBuffer.suffix(3))
        let recentConfidences = Array(confidenceBuffer.suffix(3))
        
        // Vérifier si le geste est consistant
        let consistentGesture = findConsistentGesture(recentGestures)
        let averageConfidence = recentConfidences.reduce(0, +) / Float(recentConfidences.count)
        
        // Appliquer le filtre de configuration si disponible
        if let configManager = gestureConfigManager {
            Task { @MainActor in
                let adjustedConfidence = configManager.calculateAdjustedConfidence(
                    baseConfidence: averageConfidence,
                    for: consistentGesture
                )
                
                if configManager.shouldTriggerGesture(confidence: adjustedConfidence, for: consistentGesture) {
                    self.lastGestureTime = now
                    // Retourner le résultat de manière asynchrone
                    DispatchQueue.main.async {
                        self.processStabilizedGesture(consistentGesture, confidence: adjustedConfidence)
                    }
                }
            }
            return nil // Traitement asynchrone
        } else {
            // Fallback sans gestionnaire de configuration
            if averageConfidence > 0.75 && consistentGesture != .unknown {
                lastGestureTime = now
                return (consistentGesture, averageConfidence)
            }
        }
        
        return nil
    }
    
    private func findConsistentGesture(_ gestures: [DetectedGesture]) -> DetectedGesture {
        // Compter les occurrences de chaque geste
        var gestureCount: [DetectedGesture: Int] = [:]
        for gesture in gestures {
            gestureCount[gesture, default: 0] += 1
        }
        
        // Trouver le geste le plus fréquent
        let mostFrequent = gestureCount.max { $0.value < $1.value }
        
        // Retourner le geste le plus fréquent s'il représente au moins 60% des échantillons
        if let (gesture, count) = mostFrequent, count >= Int(Double(gestures.count) * 0.6) {
            return gesture
        }
        
        return .unknown
    }
    
    @MainActor
    private func processStabilizedGesture(_ gesture: DetectedGesture, confidence: Float) {
        lastDetectedGesture = gesture
        gestureConfidence = confidence
        isGestureDetected = confidence > 0.7
        
        // Traiter le geste avec le contrôleur si disponible
        if let indexLocation = handPositionHistory.last {
            gestureController?.processDetectedGesture(gesture, at: indexLocation, confidence: confidence)
        }
    }
}
