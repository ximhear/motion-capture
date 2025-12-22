//
//  MotionListView.swift
//  MotionCapture
//

import SwiftUI

struct MotionListView: View {
    @StateObject private var storageService = MotionStorageService.shared
    @State private var showingCaptureView = false
    @State private var selectedRecording: MotionRecording?

    var body: some View {
        NavigationStack {
            Group {
                if storageService.recordings.isEmpty {
                    emptyStateView
                } else {
                    recordingsList
                }
            }
            .navigationTitle("Motion Capture")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCaptureView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCaptureView) {
                CaptureView()
            }
            .navigationDestination(item: $selectedRecording) { recording in
                MotionDetailView(recording: recording)
            }
        }
        .onAppear {
            storageService.loadRecordings()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Motion Captures")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap + to start capturing\nyour first motion")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCaptureView = true
            } label: {
                Label("New Capture", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .padding()
    }

    private var recordingsList: some View {
        List {
            ForEach(storageService.recordings) { recording in
                MotionRowView(recording: recording)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecording = recording
                    }
            }
            .onDelete(perform: deleteRecordings)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = storageService.recordings[index]
            storageService.deleteRecording(recording)
        }
    }
}

#Preview {
    MotionListView()
}
