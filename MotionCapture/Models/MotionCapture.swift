//
//  MotionCapture.swift
//  MotionCapture
//

import Foundation
import simd

struct MotionRecording: Identifiable, Codable, Hashable {
    static func == (lhs: MotionRecording, rhs: MotionRecording) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    var name: String
    var memo: String?
    let createdAt: Date
    let duration: TimeInterval
    let frameCount: Int
    let fps: Double
    var frames: [MotionFrame]

    init(
        id: UUID = UUID(),
        name: String,
        memo: String? = nil,
        createdAt: Date = Date(),
        duration: TimeInterval,
        fps: Double = 60.0,
        frames: [MotionFrame]
    ) {
        self.id = id
        self.name = name
        self.memo = memo
        self.createdAt = createdAt
        self.duration = duration
        self.frameCount = frames.count
        self.fps = fps
        self.frames = frames
    }
}

struct MotionFrame: Codable {
    let timestamp: TimeInterval
    let joints: [String: JointData]
}

struct JointData: Codable {
    let position: SIMD3<Float>
    let rotation: Quaternion

    init(position: SIMD3<Float>, rotation: simd_quatf) {
        self.position = position
        self.rotation = Quaternion(from: rotation)
    }
}

// Quaternion wrapper for Codable support
struct Quaternion: Codable {
    let x: Float
    let y: Float
    let z: Float
    let w: Float

    init(from quatf: simd_quatf) {
        self.x = quatf.vector.x
        self.y = quatf.vector.y
        self.z = quatf.vector.z
        self.w = quatf.vector.w
    }

    var simdQuatf: simd_quatf {
        simd_quatf(ix: x, iy: y, iz: z, r: w)
    }
}

// Export format for Blender
struct MotionExportData: Codable {
    let version: String
    let fps: Double
    let frameCount: Int
    let duration: TimeInterval
    let joints: [String]
    let frames: [ExportFrame]

    init(from recording: MotionRecording) {
        self.version = "1.0"
        self.fps = recording.fps
        self.frameCount = recording.frameCount
        self.duration = recording.duration
        self.joints = recording.frames.first?.joints.keys.sorted() ?? []
        self.frames = recording.frames.map { ExportFrame(from: $0) }
    }
}

struct ExportFrame: Codable {
    let timestamp: TimeInterval
    let joints: [String: ExportJoint]

    init(from frame: MotionFrame) {
        self.timestamp = frame.timestamp
        self.joints = frame.joints.mapValues { ExportJoint(from: $0) }
    }
}

struct ExportJoint: Codable {
    let position: [Float]
    let rotation: [Float]

    init(from joint: JointData) {
        self.position = [joint.position.x, joint.position.y, joint.position.z]
        self.rotation = [joint.rotation.x, joint.rotation.y, joint.rotation.z, joint.rotation.w]
    }
}
