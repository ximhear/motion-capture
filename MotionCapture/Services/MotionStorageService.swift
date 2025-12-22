//
//  MotionStorageService.swift
//  MotionCapture
//

import Foundation
import Combine

class MotionStorageService: ObservableObject {
    static let shared = MotionStorageService()

    @Published var recordings: [MotionRecording] = []

    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var recordingsDirectory: URL {
        documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
    }

    private var indexFileURL: URL {
        recordingsDirectory.appendingPathComponent("index.json")
    }

    private init() {
        createDirectoryIfNeeded()
        loadRecordings()
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }

    func loadRecordings() {
        guard fileManager.fileExists(atPath: indexFileURL.path) else {
            recordings = []
            return
        }

        do {
            let data = try Data(contentsOf: indexFileURL)
            let index = try JSONDecoder().decode([RecordingIndex].self, from: data)

            recordings = index.compactMap { indexItem in
                loadRecording(id: indexItem.id)
            }.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Failed to load recordings index: \(error)")
            recordings = []
        }
    }

    func saveRecording(_ recording: MotionRecording) {
        // Save individual recording file
        let recordingURL = recordingsDirectory.appendingPathComponent("\(recording.id.uuidString).json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(recording)
            try data.write(to: recordingURL)

            // Update index
            updateIndex()

            // Reload recordings
            DispatchQueue.main.async {
                self.recordings.insert(recording, at: 0)
            }
        } catch {
            print("Failed to save recording: \(error)")
        }
    }

    func deleteRecording(_ recording: MotionRecording) {
        let recordingURL = recordingsDirectory.appendingPathComponent("\(recording.id.uuidString).json")

        do {
            try fileManager.removeItem(at: recordingURL)

            DispatchQueue.main.async {
                self.recordings.removeAll { $0.id == recording.id }
            }

            updateIndex()
        } catch {
            print("Failed to delete recording: \(error)")
        }
    }

    func updateRecording(_ recording: MotionRecording) {
        let recordingURL = recordingsDirectory.appendingPathComponent("\(recording.id.uuidString).json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(recording)
            try data.write(to: recordingURL)

            if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                DispatchQueue.main.async {
                    self.recordings[index] = recording
                }
            }
        } catch {
            print("Failed to update recording: \(error)")
        }
    }

    private func loadRecording(id: UUID) -> MotionRecording? {
        let recordingURL = recordingsDirectory.appendingPathComponent("\(id.uuidString).json")

        guard fileManager.fileExists(atPath: recordingURL.path) else { return nil }

        do {
            let data = try Data(contentsOf: recordingURL)
            return try JSONDecoder().decode(MotionRecording.self, from: data)
        } catch {
            print("Failed to load recording \(id): \(error)")
            return nil
        }
    }

    private func updateIndex() {
        // Scan directory for all recording files
        guard let files = try? fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        let index: [RecordingIndex] = files.compactMap { url in
            guard url.pathExtension == "json",
                  url.lastPathComponent != "index.json",
                  let uuidString = url.deletingPathExtension().lastPathComponent.components(separatedBy: ".").first,
                  let uuid = UUID(uuidString: uuidString) else {
                return nil
            }
            return RecordingIndex(id: uuid)
        }

        do {
            let data = try JSONEncoder().encode(index)
            try data.write(to: indexFileURL)
        } catch {
            print("Failed to update index: \(error)")
        }
    }

    // MARK: - Export

    func exportRecording(_ recording: MotionRecording, format: ExportFormat = .json) -> Data? {
        switch format {
        case .json:
            let exportData = MotionExportData(from: recording)
            return try? JSONEncoder().encode(exportData)
        case .bvh:
            // TODO: Implement BVH export
            return nil
        }
    }

    func getExportURL(for recording: MotionRecording, format: ExportFormat = .json) -> URL? {
        guard let data = exportRecording(recording, format: format) else { return nil }

        let fileName = "\(recording.name.replacingOccurrences(of: " ", with: "_")).\(format.fileExtension)"
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to create export file: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

private struct RecordingIndex: Codable {
    let id: UUID
}

enum ExportFormat {
    case json
    case bvh

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .bvh: return "bvh"
        }
    }
}
