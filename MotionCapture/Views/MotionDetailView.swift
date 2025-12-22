//
//  MotionDetailView.swift
//  MotionCapture
//

import SwiftUI

struct MotionDetailView: View {
    let recording: MotionRecording

    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false
    @State private var playbackTimer: Timer?
    @State private var showingExportSheet = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 3D Preview
                skeletonPreview
                    .frame(height: 300)

                // Playback Controls
                playbackControls
                    .padding(.horizontal)

                // Info Section
                infoSection
                    .padding(.horizontal)

                // Export Options
                exportSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(recording.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        deleteRecording()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }

    private var skeletonPreview: some View {
        SkeletonPreviewView(recording: recording, currentTime: $currentTime)
            .padding(.horizontal)
    }

    private var playbackControls: some View {
        VStack(spacing: 16) {
            // Timeline
            VStack(spacing: 8) {
                Slider(
                    value: $currentTime,
                    in: 0...recording.duration,
                    onEditingChanged: { editing in
                        if editing {
                            stopPlayback()
                        }
                    }
                )
                .tint(.blue)

                HStack {
                    Text(formatTime(currentTime))
                    Spacer()
                    Text(formatTime(recording.duration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }

            // Controls
            HStack(spacing: 40) {
                // Previous Frame
                Button {
                    previousFrame()
                } label: {
                    Image(systemName: "backward.frame.fill")
                        .font(.title2)
                }

                // Play/Pause
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                }

                // Next Frame
                Button {
                    nextFrame()
                } label: {
                    Image(systemName: "forward.frame.fill")
                        .font(.title2)
                }
            }
            .foregroundStyle(.primary)
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)

            VStack(spacing: 12) {
                InfoRow(icon: "calendar", title: "Created", value: recording.createdAt.formatted(date: .long, time: .shortened))
                InfoRow(icon: "timer", title: "Duration", value: formatDuration(recording.duration))
                InfoRow(icon: "film.stack", title: "Frames", value: "\(recording.frameCount)")
                InfoRow(icon: "speedometer", title: "FPS", value: String(format: "%.1f", recording.fps))

                if let memo = recording.memo, !memo.isEmpty {
                    Divider()
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text(memo)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export")
                .font(.headline)

            VStack(spacing: 12) {
                ExportButton(
                    title: "Export for Blender",
                    subtitle: "JSON format with joint data",
                    icon: "cube.transparent",
                    action: exportForBlender
                )

                ExportButton(
                    title: "Copy JSON",
                    subtitle: "Copy to clipboard",
                    icon: "doc.on.doc",
                    action: copyJSON
                )

                ExportButton(
                    title: "Share File",
                    subtitle: "Share .json file",
                    icon: "square.and.arrow.up",
                    action: shareFile
                )
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard !recording.frames.isEmpty else { return }

        isPlaying = true
        let frameDuration = 1.0 / recording.fps

        playbackTimer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            currentTime += frameDuration
            if currentTime >= recording.duration {
                currentTime = 0
            }
        }
    }

    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func previousFrame() {
        guard !recording.frames.isEmpty else { return }
        let frameDuration = 1.0 / recording.fps
        currentTime = max(0, currentTime - frameDuration)
    }

    private func nextFrame() {
        guard !recording.frames.isEmpty else { return }
        let frameDuration = 1.0 / recording.fps
        currentTime = min(recording.duration, currentTime + frameDuration)
    }

    private func exportForBlender() {
        let exportData = MotionExportData(from: recording)
        if let jsonData = try? JSONEncoder().encode(exportData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UIPasteboard.general.string = jsonString
        }
    }

    private func copyJSON() {
        let exportData = MotionExportData(from: recording)
        if let jsonData = try? JSONEncoder().encode(exportData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UIPasteboard.general.string = jsonString
        }
    }

    private func shareFile() {
        let exportData = MotionExportData(from: recording)
        guard let jsonData = try? JSONEncoder().encode(exportData) else { return }

        let fileName = "\(recording.name.replacingOccurrences(of: " ", with: "_")).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: tempURL)
            exportURL = tempURL
            showingShareSheet = true
        } catch {
            print("Failed to write file: \(error)")
        }
    }

    private func deleteRecording() {
        MotionStorageService.shared.deleteRecording(recording)
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds) seconds"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct ExportButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        MotionDetailView(recording: MotionRecording(
            name: "Walking Motion",
            memo: "A simple walking animation captured in the living room.",
            duration: 30.5,
            frames: []
        ))
    }
}
