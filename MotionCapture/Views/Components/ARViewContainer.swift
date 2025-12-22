//
//  ARViewContainer.swift
//  MotionCapture
//

import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var trackingService: BodyTrackingService

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR Session for body tracking
        guard ARBodyTrackingConfiguration.isSupported else {
            print("Body tracking is not supported on this device")
            return arView
        }

        let configuration = ARBodyTrackingConfiguration()
        configuration.automaticSkeletonScaleEstimationEnabled = true

        arView.session.delegate = context.coordinator
        arView.session.run(configuration)

        // Add skeleton visualization
        context.coordinator.arView = arView
        context.coordinator.setupSkeletonVisualization()

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(trackingService: trackingService)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        let trackingService: BodyTrackingService
        private var skeletonEntity: Entity?
        private var jointEntities: [String: ModelEntity] = [:]

        init(trackingService: BodyTrackingService) {
            self.trackingService = trackingService
            super.init()
        }

        func setupSkeletonVisualization() {
            guard let arView = arView else { return }

            // Create anchor for skeleton
            let anchor = AnchorEntity()
            arView.scene.addAnchor(anchor)

            // Create entity to hold all joint spheres
            let skeleton = Entity()
            anchor.addChild(skeleton)
            self.skeletonEntity = skeleton
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }

                // Update tracking service
                trackingService.updateBody(bodyAnchor)

                // Update visualization
                updateSkeletonVisualization(bodyAnchor: bodyAnchor)
            }
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if anchor is ARBodyAnchor {
                    trackingService.isBodyDetected = true
                }
            }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if anchor is ARBodyAnchor {
                    trackingService.isBodyDetected = false
                }
            }
        }

        private func updateSkeletonVisualization(bodyAnchor: ARBodyAnchor) {
            guard let skeleton = skeletonEntity else { return }

            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)

            // 실제 추적되는 관절만 시각화
            for jointName in TrackedJoint.allJointNames {
                guard let jointTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) else {
                    continue
                }

                let jointPosition = bodyPosition + simd_make_float3(jointTransform.columns.3)

                if let existingEntity = jointEntities[jointName] {
                    existingEntity.position = jointPosition
                } else {
                    // Create new joint sphere
                    let sphere = MeshResource.generateSphere(radius: 0.025)
                    let material = SimpleMaterial(color: jointColor(for: jointName), isMetallic: false)
                    let entity = ModelEntity(mesh: sphere, materials: [material])
                    entity.position = jointPosition

                    skeleton.addChild(entity)
                    jointEntities[jointName] = entity
                }
            }
        }

        private func jointColor(for jointName: String) -> UIColor {
            if jointName.contains("left") {
                return .systemBlue
            } else if jointName.contains("right") {
                return .systemGreen
            } else if jointName.contains("spine") || jointName.contains("hips") {
                return .systemYellow
            } else if jointName.contains("head") || jointName.contains("neck") {
                return .systemOrange
            } else {
                return .systemPurple
            }
        }
    }
}
