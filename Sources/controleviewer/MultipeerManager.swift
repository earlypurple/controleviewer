import Foundation
@preconcurrency import MultipeerConnectivity
import SwiftUI

@MainActor
class MultipeerManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var connectedPeers: [MCPeerID] = []
    
    private let serviceType = "mac-controller"
    private let myPeerID = MCPeerID(displayName: "Mac-ControleViewer")
    private var session: MCSession
    private var browser: MCNearbyServiceBrowser?
    private var advertiser: MCNearbyServiceAdvertiser?
    
    weak var gestureController: GestureController?
    
    override init() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
        startAdvertising()
    }
    
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }
    
    private func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }
    
    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }
    
    func sendMessage(_ message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        
        if let data = message.data(using: .utf8) {
            do {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                print("Erreur lors de l'envoi du message: \(error)")
            }
        }
    }
    
    private func processReceivedMessage(_ data: Data) {
        guard let message = String(data: data, encoding: .utf8),
              let gestureController = gestureController else { return }
        
        let components = message.components(separatedBy: ":")
        guard components.count >= 2 else { return }
        
        let command = components[0]
        let value = components[1]
        
        switch command {
        case "click":
            if value == "left" {
                gestureController.performLeftClick()
            } else if value == "right" {
                gestureController.performRightClick()
            }
            
        case "scroll":
            if value == "up" {
                gestureController.performScroll(direction: .up)
            } else if value == "down" {
                gestureController.performScroll(direction: .down)
            }
            
        case "move":
            let coords = value.components(separatedBy: ",")
            if coords.count == 2,
               let x = Double(coords[0]),
               let y = Double(coords[1]),
               let screen = NSScreen.main {
                
                let screenX = x * screen.frame.width
                let screenY = y * screen.frame.height
                let point = CGPoint(x: screenX, y: screenY)
                
                gestureController.moveCursor(to: point)
            }
            
        default:
            print("Commande inconnue: \(command)")
        }
    }
}

extension MultipeerManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("Connecté à: \(peerID.displayName)")
                self.isConnected = true
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                
            case .connecting:
                print("Connexion en cours à: \(peerID.displayName)")
                
            case .notConnected:
                print("Déconnecté de: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0 == peerID }
                self.isConnected = !self.connectedPeers.isEmpty
                
            @unknown default:
                print("État de session inconnu")
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.processReceivedMessage(data)
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("Peer trouvé: \(peerID.displayName)")
        Task { @MainActor in
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Peer perdu: \(peerID.displayName)")
    }
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Invitation reçue de: \(peerID.displayName)")
        // Accepter automatiquement l'invitation
        invitationHandler(true, nil)
    }
}
