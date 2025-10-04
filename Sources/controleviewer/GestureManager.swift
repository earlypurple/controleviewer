//
//  GestureManager.swift
//  GestureControl Pro
//
//  Gestionnaire principal de détection gestuelle avec Vision Framework
//

import Foundation
import AVFoundation
import Vision
import Combine

class GestureManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isRunning = false
    @Published var currentFPS: Double = 0
    @Published var latency: Double = 0
    @Published var currentGesture: DetectedGesture?
    @Published var handsDetected: Int = 0
    @Published var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var handPoseRequest: VNDetectHumanHandPoseRequest?
    private let videoDataOutputQueue = DispatchQueue(label: "videoDataOutputQueue")

    // Performance tracking
    private var lastFrameTime = CFAbsoluteTimeGetCurrent()
    private var frameCount = 0
    private var fpsCalculationTimer: Timer?

    // Gesture recognition
    private var gestureClassifier = HandGestureClassifier()
    private var calibrationData: CalibrationData?

    // Configuration
    @Published var settings = GestureSettings()

    override init() {
        super.init()
        setupHandPoseRequest()
    }

    // MARK: - Public Methods
    func start() {
        guard !isRunning else { return }

        Task { @MainActor in
            await setupCamera()
            startFPSTracking()
            isRunning = true
        }
    }

    func stop() {
        guard isRunning else { return }

        captureSession?.stopRunning()
        fpsCalculationTimer?.invalidate()
        isRunning = false
        currentGesture = nil
        handsDetected = 0
    }

    func calibrate() {
        calibrationData = CalibrationData()
        // Commencer le processus de calibration
    }

    func updateSettings(_ newSettings: GestureSettings) {
        settings = newSettings
        handPoseRequest?.maximumHandCount = newSettings.maxHandCount
    }

    // MARK: - Private Methods
    private func setupHandPoseRequest() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest?.maximumHandCount = settings.maxHandCount
        handPoseRequest?.revision = VNDetectHumanHandPoseRequestRevision1
    }

    @MainActor
    private func setupCamera() async {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        guard let captureSession = captureSession else { return }

        // Configuration de la caméra
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            print("Erreur: Impossible de configurer la caméra")
            return
        }

        captureSession.addInput(videoDeviceInput)

        // Configuration de la sortie vidéo
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Configuration du preview layer
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = .resizeAspectFill

        captureSession.startRunning()
    }

    private func startFPSTracking() {
        fpsCalculationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.currentFPS = Double(self.frameCount)
                self.frameCount = 0
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension GestureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let handPoseRequest = handPoseRequest else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([handPoseRequest])

            if let results = handPoseRequest.results, !results.isEmpty {
                processHandPoseResults(results)
            }

            frameCount += 1

            let processingTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            DispatchQueue.main.async {
                self.latency = processingTime
                self.handsDetected = handPoseRequest.results?.count ?? 0
            }

        } catch {
            print("Erreur de détection de pose: \(error)")
        }
    }

    private func processHandPoseResults(_ results: [VNHumanHandPoseObservation]) {
        guard let observation = results.first else { return }

        // Classification du geste
        if let gesture = gestureClassifier.classifyGesture(from: observation, settings: settings) {
            DispatchQueue.main.async {
                self.currentGesture = gesture
            }

            // Notification pour le système de contrôle
            NotificationCenter.default.post(
                name: .gestureDetected,
                object: gesture
            )
        }
    }
}

// MARK: - Supporting Types
struct DetectedGesture {
    let type: GestureType
    let confidence: Float
    let landmarks: [CGPoint]
    let timestamp: Date
}

enum GestureType: CaseIterable {
    case pointingIndex
    case closedFist
    case peaceSign
    case thumbsUp
    case thumbsDown
    case openHand
    case pinch

    var displayName: String {
        switch self {
        case .pointingIndex: return "Index Pointé"
        case .closedFist: return "Poing Fermé"
        case .peaceSign: return "Peace Sign"
        case .thumbsUp: return "Pouce Levé"
        case .thumbsDown: return "Pouce Baissé"
        case .openHand: return "Main Ouverte"
        case .pinch: return "Pincement"
        }
    }

    var defaultAction: SystemAction {
        switch self {
        case .pointingIndex: return .moveMouse
        case .closedFist: return .leftClick
        case .peaceSign: return .rightClick
        case .thumbsUp: return .scrollUp
        case .thumbsDown: return .scrollDown
        case .openHand: return .pauseMode
        case .pinch: return .zoom
        }
    }
}

struct GestureSettings {
    var maxHandCount: Int = 1
    var confidenceThreshold: Float = 0.7
    var trackingEnabled: Bool = true
    var smoothingEnabled: Bool = true
    var calibrationEnabled: Bool = true
}

struct CalibrationData {
    var workspaceRect: CGRect = .zero
    var screenMapping: CGAffineTransform = .identity
    var gestureThresholds: [GestureType: Float] = [:]
}

extension Notification.Name {
    static let gestureDetected = Notification.Name("gestureDetected")
}