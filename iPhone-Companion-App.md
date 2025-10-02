# Application iPhone Compagnon - ControleViewer

## Vue d'ensemble
Cette application iPhone permet de contrôler votre Mac à distance en envoyant des commandes via MultipeerConnectivity.

## Code Swift pour l'iPhone (exemple simplifié)

```swift
import SwiftUI
import MultipeerConnectivity

struct iPhoneControllerView: View {
    @StateObject private var multipeerManager = iPhoneMultipeerManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Contrôleur Mac")
                .font(.largeTitle)
                .padding()
            
            HStack {
                Circle()
                    .fill(multipeerManager.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(multipeerManager.isConnected ? "Connecté au Mac" : "Déconnecté")
            }
            
            // Zone tactile pour mouvement du curseur
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 300)
                .overlay(Text("Zone tactile - Trackpad"))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let x = value.location.x / UIScreen.main.bounds.width
                            let y = value.location.y / 300 // Hauteur de la zone tactile
                            multipeerManager.sendMessage("move:\(x),\(y)")
                        }
                )
            
            // Boutons de contrôle
            HStack(spacing: 20) {
                Button("Clic Gauche") {
                    multipeerManager.sendMessage("click:left")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clic Droit") {
                    multipeerManager.sendMessage("click:right")
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 20) {
                Button("Scroll ↑") {
                    multipeerManager.sendMessage("scroll:up")
                }
                
                Button("Scroll ↓") {
                    multipeerManager.sendMessage("scroll:down")
                }
            }
            
            Button("Se connecter") {
                multipeerManager.startBrowsing()
            }
            .padding()
        }
        .padding()
    }
}

class iPhoneMultipeerManager: NSObject, ObservableObject {
    @Published var isConnected = false
    
    private let serviceType = "mac-controller"
    private let myPeerID = MCPeerID(displayName: "iPhone-Controller")
    private var session: MCSession
    private var browser: MCNearbyServiceBrowser?
    
    override init() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }
    
    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }
    
    func sendMessage(_ message: String) {
        guard !session.connectedPeers.isEmpty,
              let data = message.data(using: .utf8) else { return }
        
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Erreur envoi: \(error)")
        }
    }
}

extension iPhoneMultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.isConnected = (state == .connected)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension iPhoneMultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
```

## Instructions de déploiement

1. Créez un nouveau projet iOS dans Xcode
2. Ajoutez le code ci-dessus
3. Configurez les permissions dans Info.plist :
   - NSLocalNetworkUsageDescription
   - NSBonjourServices

## Protocole de communication

L'iPhone envoie des messages au Mac au format "commande:valeur" :

- `click:left` - Clic gauche
- `click:right` - Clic droit  
- `scroll:up` - Scroll vers le haut
- `scroll:down` - Scroll vers le bas
- `move:x,y` - Déplacer curseur (coordonnées normalisées 0-1)

## Configuration requise

- iPhone avec iOS 13+
- Mac avec macOS 13+
- Même réseau WiFi ou Bluetooth activé
