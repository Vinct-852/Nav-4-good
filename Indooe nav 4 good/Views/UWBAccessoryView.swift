//
//  UWBAccessoryView.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 6/11/2025.
//
import simd
import SwiftUI

struct UWBAccessoryView: View {
    @State private var viewModel = UWBAccessoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                statusSection
                
                // Distance Display
                if let distance = viewModel.distance {
                    distanceDisplay(distance)
                }
                
                // Direction Display
                if let direction = viewModel.direction {
                    directionDisplay(direction)
                }
                
                Spacer()
                
                // Accessories List or Scan Button
                if viewModel.isScanning || !viewModel.discoveredAccessories.isEmpty {
                    accessoriesList
                } else {
                    scanButton
                }
                
                // Error Message
                if let error = viewModel.errorMessage {
                    errorView(error)
                }
            }
            .padding()
            .navigationTitle("UWB Discovery")
            .navigationBarItems(trailing: connectionButton)
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 8) {
            statusIcon
            
            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)
            
            if let accessory = viewModel.connectedAccessory {
                Text(accessory.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusIcon: some View {
        Group {
            switch viewModel.connectionStatus {
            case .disconnected:
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
            case .scanning:
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
            case .connecting, .exchangingConfig:
                ProgressView()
                    .scaleEffect(1.5)
            case .ranging:
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var statusText: String {
        switch viewModel.connectionStatus {
        case .disconnected:
            return "Disconnected"
        case .scanning:
            return "Scanning for UWB devices..."
        case .connecting:
            return "Connecting..."
        case .exchangingConfig:
            return "Exchanging configuration..."
        case .ranging:
            return "Ranging Active"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var statusColor: Color {
        switch viewModel.connectionStatus {
        case .disconnected:
            return .gray
        case .scanning, .connecting, .exchangingConfig:
            return .blue
        case .ranging:
            return .green
        case .error:
            return .red
        }
    }
    
    // MARK: - Distance Display
    private func distanceDisplay(_ distance: Float) -> some View {
        VStack(spacing: 8) {
            Text("Distance")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.2f m", distance))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Distance indicator
            DistanceIndicator(distance: distance)
                .frame(height: 80)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Direction Display
    private func directionDisplay(_ direction: simd_float3) -> some View {
        VStack(spacing: 8) {
            Text("Direction Vector")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("X")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", direction.x))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                }
                
                VStack {
                    Text("Y")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", direction.y))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                }
                
                VStack {
                    Text("Z")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", direction.z))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                }
            }
            
            // Visual direction indicator
            DirectionIndicator(direction: direction)
                .frame(width: 150, height: 150)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Accessories List
    private var accessoriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discovered Devices")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.isScanning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.discoveredAccessories) { accessory in
                        AccessoryRow(accessory: accessory) {
                            viewModel.connect(to: accessory)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            
            Button(action: {
                if viewModel.isScanning {
                    viewModel.stopScanning()
                } else {
                    viewModel.startScanning()
                }
            }) {
                Text(viewModel.isScanning ? "Stop Scanning" : "Scan Again")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Scan Button
    private var scanButton: some View {
        Button(action: {
            viewModel.startScanning()
        }) {
            Label("Scan for UWB Devices", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Connection Button
    private var connectionButton: some View {
        Group {
            if case .ranging = viewModel.connectionStatus {
                Button("Disconnect") {
                    viewModel.disconnect()
                }
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Views

struct AccessoryRow: View {
    let accessory: UWBAccessoryViewModel.AccessoryInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(accessory.name)
                        .font(.headline)
                    Text("RSSI: \(accessory.rssi)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DistanceIndicator: View {
    let distance: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                
                // Progress (inverse - closer = more filled)
                RoundedRectangle(cornerRadius: 8)
                    .fill(distanceColor)
                    .frame(width: progressWidth(for: geometry.size.width))
            }
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        // Max distance of 10 meters for visualization
        let maxDistance: Float = 10.0
        let clampedDistance = min(distance, maxDistance)
        let progress = 1.0 - (clampedDistance / maxDistance)
        return totalWidth * CGFloat(progress)
    }
    
    private var distanceColor: Color {
        if distance < 1.0 {
            return .green
        } else if distance < 3.0 {
            return .yellow
        } else {
            return .orange
        }
    }
}

struct DirectionIndicator: View {
    let direction: simd_float3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Circle background
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                
                // Center point
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                
                // Direction pointer (X and Z for 2D representation)
                Path { path in
                    let center = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    
                    // Scale direction vector for visualization
                    let scale: CGFloat = 50
                    let endPoint = CGPoint(
                        x: center.x + CGFloat(direction.x) * scale,
                        y: center.y - CGFloat(direction.z) * scale // Negative for screen coordinates
                    )
                    
                    path.move(to: center)
                    path.addLine(to: endPoint)
                }
                .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                
                // Arrow head
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .offset(
                        x: CGFloat(direction.x) * 50,
                        y: -CGFloat(direction.z) * 50
                    )
            }
        }
    }
}

#Preview {
    UWBAccessoryView()
}
