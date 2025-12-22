//
//  CaptureView.swift
//  MotionCapture
//

import SwiftUI
import ARKit
import RealityKit

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var trackingService = BodyTrackingService()

    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showingSaveSheet = false
    @State private var recordedFrames: [MotionFrame] = []
    @State private var recordingStartTime: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                // AR View
                ARViewContainer(trackingService: trackingService)
                    .ignoresSafeArea()

                // Overlay UI
                VStack {
                    Spacer()

                    // Status Panel
                    statusPanel
                        .padding(.horizontal)

                    // Recording Controls
                    recordingControls
                        .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        stopRecording()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("New Capture")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSaveSheet) {
                SaveCaptureView(
                    frames: recordedFrames,
                    duration: recordingTime
                )
            }
        }
    }

    private var statusPanel: some View {
        VStack(spacing: 12) {
            // Body Detection Status
            HStack {
                Circle()
                    .fill(trackingService.isBodyDetected ? .green : .red)
                    .frame(width: 10, height: 10)

                Text(trackingService.isBodyDetected ? "Body Detected" : "No Body Detected")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if trackingService.isBodyDetected {
                    Text("Quality: \(trackingService.trackingQuality)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Joint Count
            if trackingService.isBodyDetected {
                HStack {
                    Image(systemName: "figure.walk")
                    Text("\(trackingService.jointCount) joints tracked")
                        .font(.caption)
                    Spacer()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var recordingControls: some View {
        VStack(spacing: 20) {
            // Timer Display
            Text(formatTime(recordingTime))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(.white)

            // Record Button
            Button {
                if isRecording {
                    stopRecording()
                    showingSaveSheet = true
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    if isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 64, height: 64)
                    }
                }
            }
            .disabled(!trackingService.isBodyDetected && !isRecording)
            .opacity(trackingService.isBodyDetected || isRecording ? 1.0 : 0.5)

            Text(isRecording ? "Tap to Stop" : "Tap to Record")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding()
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 20))
    }

    private func startRecording() {
        isRecording = true
        recordingTime = 0
        recordedFrames = []
        recordingStartTime = Date()

        // Start timer for display
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingTime += 0.1
        }

        // Start capturing frames
        trackingService.startCapturing { frame in
            recordedFrames.append(frame)
        }
    }

    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        trackingService.stopCapturing()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

#Preview {
    CaptureView()
}
