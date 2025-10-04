//
//  ContentView.swift
//  GestureControl Pro
//
//  Interface principale avec caméra et contrôles
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var gestureManager = GestureManager()
    @StateObject private var systemController = SystemController()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var isCalibrating = false

    var body: some View {
        NavigationSplitView {
            // Sidebar avec navigation
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "hand.wave.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("GestureControl Pro")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    StatusIndicator(
                        isConnected: gestureManager.isRunning,
                        fps: gestureManager.currentFPS,
                        latency: gestureManager.latency
                    )
                }
                .padding()
                .background(Color(.controlBackgroundColor))

                Divider()

                // Navigation
                List(selection: $selectedTab) {
                    NavigationItem(
                        icon: "video.fill",
                        title: "Contrôle Caméra",
                        tag: 0
                    )

                    NavigationItem(
                        icon: "hand.point.up.left.fill",
                        title: "Configuration Gestes",
                        tag: 1
                    )

                    NavigationItem(
                        icon: "slider.horizontal.3",
                        title: "Réglages",
                        tag: 2
                    )

                    NavigationItem(
                        icon: "target",
                        title: "Calibration",
                        tag: 3
                    )

                    NavigationItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Statistiques",
                        tag: 4
                    )
                }
                .listStyle(.sidebar)

                Spacer()

                // Controls rapides
                VStack(spacing: 12) {
                    Button(action: {
                        if gestureManager.isRunning {
                            gestureManager.stop()
                        } else {
                            gestureManager.start()
                        }
                    }) {
                        HStack {
                            Image(systemName: gestureManager.isRunning ? "stop.fill" : "play.fill")
                            Text(gestureManager.isRunning ? "Arrêter" : "Démarrer")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Calibrer") {
                        isCalibrating = true
                    }
                    .buttonStyle(.bordered)
                    .disabled(!gestureManager.isRunning)
                }
                .padding()
            }
        } detail: {
            // Contenu principal
            Group {
                switch selectedTab {
                case 0:
                    CameraControlView(gestureManager: gestureManager, systemController: systemController)
                case 1:
                    GestureConfigView(gestureManager: gestureManager)
                case 2:
                    SettingsView(gestureManager: gestureManager)
                case 3:
                    CalibrationView(gestureManager: gestureManager, isCalibrating: $isCalibrating)
                case 4:
                    StatisticsView(gestureManager: gestureManager, systemController: systemController)
                default:
                    CameraControlView(gestureManager: gestureManager, systemController: systemController)
                }
            }
        }
        .navigationTitle("")
        .sheet(isPresented: $isCalibrating) {
            CalibrationSheet(gestureManager: gestureManager, isPresented: $isCalibrating)
        }
    }
}

struct NavigationItem: View {
    let icon: String
    let title: String
    let tag: Int

    var body: some View {
        Label(title, systemImage: icon)
            .tag(tag)
    }
}

struct StatusIndicator: View {
    let isConnected: Bool
    let fps: Double
    let latency: Double

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(isConnected ? "Actif" : "Inactif")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if isConnected {
                HStack(spacing: 8) {
                    Text("\(Int(fps)) FPS")
                        .font(.caption)
                        .monospaced()

                    Text("\(Int(latency))ms")
                        .font(.caption)
                        .monospaced()
                }
                .foregroundColor(.secondary)
            }
        }
    }
}