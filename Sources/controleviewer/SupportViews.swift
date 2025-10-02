import SwiftUI
import AVFoundation
import AppKit

// MARK: - CameraView pour macOS

struct CameraView: NSViewRepresentable {
    let cameraManager: CameraManager
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        // Créer la preview layer
        let session = cameraManager.getSession()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer?.addSublayer(previewLayer)
        
        // Stocker la preview layer dans le camera manager
        cameraManager.previewLayer = previewLayer
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Mettre à jour la taille de la preview layer
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
}

// MARK: - Vues de Support

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GestureCard: View {
    let name: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct ControlButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 120, height: 80)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
