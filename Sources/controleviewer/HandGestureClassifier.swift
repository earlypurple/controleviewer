//
//  HandGestureClassifier.swift
//  GestureControl Pro
//
//  Classificateur de gestes basé sur Vision Framework
//

import Foundation
import Vision

class HandGestureClassifier {
    private let confidenceThreshold: Float = 0.7

    func classifyGesture(from observation: VNHumanHandPoseObservation, settings: GestureSettings) -> DetectedGesture? {
        guard observation.confidence >= settings.confidenceThreshold else { return nil }

        // Extraction des points de repère
        guard let landmarks = try? extractLandmarks(from: observation) else { return nil }

        // Classification du geste
        let gestureType = detectGestureType(landmarks: landmarks)

        return DetectedGesture(
            type: gestureType,
            confidence: observation.confidence,
            landmarks: landmarks.map { CGPoint(x: $0.x, y: $0.y) },
            timestamp: Date()
        )
    }

    private func extractLandmarks(from observation: VNHumanHandPoseObservation) throws -> [CGPoint] {
        let handLandmarks: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
            .indexTip, .indexDIP, .indexPIP, .indexMCP,
            .middleTip, .middleDIP, .middlePIP, .middleMCP,
            .ringTip, .ringDIP, .ringPIP, .ringMCP,
            .littleTip, .littleDIP, .littlePIP, .littleMCP
        ]

        var points: [CGPoint] = []

        for joint in handLandmarks {
            guard let point = try? observation.recognizedPoint(joint),
                  point.confidence > 0.3 else {
                continue
            }
            points.append(CGPoint(x: point.location.x, y: point.location.y))
        }

        return points
    }

    private func detectGestureType(landmarks: [CGPoint]) -> GestureType {
        guard landmarks.count >= 21 else { return .openHand }

        // Indices des points de repère importants
        let wrist = landmarks[0]
        let thumbTip = landmarks[1]
        let indexTip = landmarks[5]
        let indexMCP = landmarks[8]
        let middleTip = landmarks[9]
        let middleMCP = landmarks[12]
        let ringTip = landmarks[13]
        let ringMCP = landmarks[16]
        let littleTip = landmarks[17]
        let littleMCP = landmarks[20]

        // Compter les doigts vraiment étendus
        let extendedFingers = countExtendedFingers(landmarks)
        
        // Vérifier les doigts individuels
        let thumbExtended = isFingerExtended(landmarks, finger: .thumb)
        let indexExtended = isFingerExtended(landmarks, finger: .index)
        let middleExtended = isFingerExtended(landmarks, finger: .middle)
        let ringExtended = isFingerExtended(landmarks, finger: .ring)
        let littleExtended = isFingerExtended(landmarks, finger: .little)
        
        // Distance index-middle pour peace sign
        let indexMiddleDist = distance(indexTip, middleTip)
        let indexThumbDist = distance(indexTip, thumbTip)
        
        // 👆 POINTING INDEX - Seul l'index est levé
        if indexExtended && !middleExtended && !ringExtended && !littleExtended {
            print("👆 Pointing détecté")
            return .pointingIndex
        }
        
        // ✌️ PEACE SIGN - Index et middle levés, proches l'un de l'autre
        if indexExtended && middleExtended && !ringExtended && !littleExtended && indexMiddleDist < 0.15 {
            print("✌️ Peace Sign détecté")
            return .peaceSign
        }
        
        // ✊ FIST - Tous les doigts fermés (0 ou 1 doigt étendu)
        if extendedFingers <= 1 && !indexExtended && !middleExtended {
            print("✊ Fist détecté (doigts étendus: \(extendedFingers))")
            return .closedFist
        }
        
        // 👍 THUMBS UP - Seul le pouce levé
        if thumbExtended && extendedFingers == 1 {
            // Vérifier que le pouce est au-dessus
            if thumbTip.y < indexMCP.y {
                print("👍 Thumbs Up détecté")
                return .thumbsUp
            }
        }
        
        // 👎 THUMBS DOWN - Seul le pouce baissé
        if thumbExtended && extendedFingers == 1 {
            if thumbTip.y > indexMCP.y {
                print("👎 Thumbs Down détecté")
                return .thumbsDown
            }
        }
        
        // 🤏 PINCH - Pouce et index très proches
        if indexThumbDist < 0.08 {
            print("🤏 Pinch détecté")
            return .pinch
        }
        
        // ✋ OPEN HAND - 4 ou 5 doigts étendus
        if extendedFingers >= 4 {
            print("✋ Open Hand détecté (doigts: \(extendedFingers))")
            return .openHand
        }
        
        // Par défaut, retourner le geste le plus probable selon le nombre de doigts
        print("⚠️ Geste ambigu - doigts étendus: \(extendedFingers)")
        return extendedFingers >= 3 ? .openHand : .closedFist
    }

    private func countExtendedFingers(_ landmarks: [CGPoint]) -> Int {
        var count = 0

        // Vérifier chaque doigt
        if isFingerExtended(landmarks, finger: .thumb) { count += 1 }
        if isFingerExtended(landmarks, finger: .index) { count += 1 }
        if isFingerExtended(landmarks, finger: .middle) { count += 1 }
        if isFingerExtended(landmarks, finger: .ring) { count += 1 }
        if isFingerExtended(landmarks, finger: .little) { count += 1 }

        return count
    }

    private func isFingerExtended(_ landmarks: [CGPoint], finger: FingerType) -> Bool {
        let indices = getFingerIndices(finger)

        guard indices.count >= 4,
              indices.allSatisfy({ $0 < landmarks.count }) else { return false }

        let tip = landmarks[indices[0]]
        let _ = landmarks[indices[1]] // dip
        let pip = landmarks[indices[2]]
        let mcp = landmarks[indices[3]]

        // Vérifier si le doigt est étendu
        // Méthode 1: Le tip doit être significativement plus loin du mcp que le pip
        let tipDistance = distance(tip, mcp)
        let pipDistance = distance(pip, mcp)
        
        // Méthode 2: Le tip doit être au-dessus (y plus petit) du pip pour la plupart des doigts
        let heightCheck = tip.y < pip.y + 0.02 // Tolérance de 2%
        
        // Un doigt est étendu si les deux conditions sont remplies
        let distanceCheck = tipDistance > pipDistance * 1.1 // Le tip doit être au moins 10% plus loin
        
        return distanceCheck && heightCheck
    }

    private func getFingerIndices(_ finger: FingerType) -> [Int] {
        switch finger {
        case .thumb: return [1, 2, 3, 4] // tip, ip, mp, cmc
        case .index: return [5, 6, 7, 8] // tip, dip, pip, mcp
        case .middle: return [9, 10, 11, 12]
        case .ring: return [13, 14, 15, 16]
        case .little: return [17, 18, 19, 20]
        }
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
}

enum FingerType {
    case thumb, index, middle, ring, little
}