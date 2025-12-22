//
//  SaveCaptureView.swift
//  MotionCapture
//

import SwiftUI

struct SaveCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    let frames: [MotionFrame]
    let duration: TimeInterval

    @State private var name: String = ""
    @State private var memo: String = ""
    @State private var isSaving = false

    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Preview Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.blue)
                                }

                            VStack(spacing: 4) {
                                Text(formatDuration(duration))
                                    .font(.headline)
                                Text("\(frames.count) frames")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Name Section
                Section("Name") {
                    TextField("Enter motion name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // Memo Section
                Section("Memo (Optional)") {
                    TextField("Add a description...", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Info Section
                Section("Details") {
                    LabeledContent("Duration", value: formatDuration(duration))
                    LabeledContent("Frames", value: "\(frames.count)")
                    LabeledContent("FPS", value: String(format: "%.1f", Double(frames.count) / duration))
                    if let firstFrame = frames.first {
                        LabeledContent("Joints", value: "\(firstFrame.joints.count)")
                    }
                }
            }
            .navigationTitle("Save Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecording()
                    }
                    .disabled(!isValidInput || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func saveRecording() {
        isSaving = true

        let recording = MotionRecording(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memo.isEmpty ? nil : memo,
            duration: duration,
            fps: Double(frames.count) / duration,
            frames: frames
        )

        MotionStorageService.shared.saveRecording(recording)
        dismiss()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)

        if minutes > 0 {
            return String(format: "%d:%02d.%d", minutes, seconds, tenths)
        } else {
            return String(format: "%d.%ds", seconds, tenths)
        }
    }
}

#Preview {
    SaveCaptureView(
        frames: [],
        duration: 30.5
    )
}
