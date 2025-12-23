//
//  BodyTrackingService.swift
//  MotionCapture
//

import Foundation
import ARKit
import Combine

class BodyTrackingService: ObservableObject {
    @Published var isBodyDetected = false
    @Published var jointCount = 0
    @Published var trackingQuality = "Unknown"

    private var isCapturing = false
    private var captureStartTime: Date?
    private var onFrameCaptured: ((MotionFrame) -> Void)?

    private var lastCaptureTime: TimeInterval = 0
    private let targetFPS: Double = 60.0
    private var minFrameInterval: TimeInterval { 1.0 / targetFPS }

    func updateBody(_ bodyAnchor: ARBodyAnchor) {
        DispatchQueue.main.async {
            self.isBodyDetected = bodyAnchor.isTracked
            self.jointCount = self.countTrackedJoints(bodyAnchor.skeleton)
            self.trackingQuality = self.evaluateTrackingQuality(bodyAnchor)
        }

        // Capture frame if recording
        if isCapturing {
            captureFrame(from: bodyAnchor)
        }
    }

    func startCapturing(onFrame: @escaping (MotionFrame) -> Void) {
        isCapturing = true
        captureStartTime = Date()
        lastCaptureTime = 0
        onFrameCaptured = onFrame
    }

    func stopCapturing() {
        isCapturing = false
        captureStartTime = nil
        onFrameCaptured = nil
    }

    private func captureFrame(from bodyAnchor: ARBodyAnchor) {
        guard let startTime = captureStartTime else { return }

        let currentTime = Date().timeIntervalSince(startTime)

        // Limit capture rate to target FPS
        guard currentTime - lastCaptureTime >= minFrameInterval else { return }
        lastCaptureTime = currentTime

        var joints: [String: JointData] = [:]

        let skeleton = bodyAnchor.skeleton
        let bodyTransform = bodyAnchor.transform

        // 먼저 모든 관절의 modelTransform을 캐시
        var modelTransforms: [String: simd_float4x4] = [:]
        for jointName in TrackedJoint.allJointNames {
            if let transform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                modelTransforms[jointName] = transform
            }
        }

        // 실제 추적되는 관절만 캡처
        for jointName in TrackedJoint.allJointNames {
            guard let modelTransform = modelTransforms[jointName] else {
                continue
            }

            // 로컬 회전 계산 (부모 관절 기준)
            let localRotation: simd_quatf
            if let parentName = JointHierarchy.parent(of: jointName),
               let parentTransform = modelTransforms[parentName] {
                // 부모의 역변환 * 현재 변환 = 로컬 변환
                let parentRotation = simd_quatf(parentTransform)
                let currentRotation = simd_quatf(modelTransform)
                localRotation = parentRotation.inverse * currentRotation
            } else {
                // Root(hips)는 modelTransform 그대로 사용
                localRotation = simd_quatf(modelTransform)
            }

            // For position, use world transform (only needed for root/hips)
            let worldTransform = bodyTransform * modelTransform
            let position = SIMD3<Float>(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z
            )

            joints[jointName] = JointData(position: position, rotation: localRotation)
        }

        let frame = MotionFrame(timestamp: currentTime, joints: joints)

        DispatchQueue.main.async {
            self.onFrameCaptured?(frame)
        }
    }

    private func countTrackedJoints(_ skeleton: ARSkeleton3D) -> Int {
        var count = 0

        // 실제 추적 대상 관절만 카운트
        for jointName in TrackedJoint.allJointNames {
            if skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) != nil {
                count += 1
            }
        }

        return count
    }

    private func evaluateTrackingQuality(_ bodyAnchor: ARBodyAnchor) -> String {
        let trackedCount = countTrackedJoints(bodyAnchor.skeleton)
        let totalCount = TrackedJoint.count

        let ratio = Double(trackedCount) / Double(totalCount)

        if ratio > 0.9 {
            return "Excellent"
        } else if ratio > 0.7 {
            return "Good"
        } else if ratio > 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
}
