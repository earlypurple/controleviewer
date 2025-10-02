import SwiftUI
import AVFoundation
import Vision
import CoreGraphics
import MultipeerConnectivity
#if canImport(RealityKit)
import RealityKit
#endif
#if canImport(ARKit)
import ARKit
#endif

@main
struct ControleViewerApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            SimpleControlView()
                .frame(minWidth: 1200, minHeight: 800)
        }
    }
}
