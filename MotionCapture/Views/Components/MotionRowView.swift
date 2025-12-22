//
//  MotionRowView.swift
//  MotionCapture
//

import SwiftUI

struct MotionRowView: View {
    let recording: MotionRecording

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))

                    Text("·")

                    Text(formatDuration(recording.duration))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

#Preview {
    List {
        MotionRowView(recording: MotionRecording(
            name: "Walking Motion",
            duration: 30.5,
            frames: []
        ))
        MotionRowView(recording: MotionRecording(
            name: "Jump Animation",
            duration: 125.0,
            frames: []
        ))
    }
}
