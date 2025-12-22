//
//  SkeletonPreviewView.swift
//  MotionCapture
//

import SwiftUI
import RealityKit
import simd

struct SkeletonPreviewView: View {
    let recording: MotionRecording
    @Binding var currentTime: TimeInterval

    var body: some View {
        SkeletonRealityView(recording: recording, currentTime: currentTime)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SkeletonRealityView: UIViewRepresentable {
    let recording: MotionRecording
    let currentTime: TimeInterval

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.systemGray6)
        arView.cameraMode = .nonAR

        // Setup camera
        let cameraAnchor = AnchorEntity(world: .zero)
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = 60
        camera.position = [0, 0.85, 3.2]
        camera.look(at: [0, 0.75, 0], from: camera.position, relativeTo: nil)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        // Add ambient light
        let lightAnchor = AnchorEntity(world: .zero)
        let light = DirectionalLight()
        light.light.intensity = 1000
        light.light.color = .white
        light.position = [2, 3, 2]
        light.look(at: .zero, from: light.position, relativeTo: nil)
        lightAnchor.addChild(light)
        arView.scene.addAnchor(lightAnchor)

        // Create skeleton anchor
        let skeletonAnchor = AnchorEntity(world: .zero)
        skeletonAnchor.name = "skeletonAnchor"
        arView.scene.addAnchor(skeletonAnchor)

        // Setup initial skeleton
        context.coordinator.setupSkeleton(in: skeletonAnchor)
        context.coordinator.arView = arView

        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(panGesture)
        arView.addGestureRecognizer(pinchGesture)

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        guard let skeletonAnchor = arView.scene.findEntity(named: "skeletonAnchor") as? AnchorEntity else { return }

        // Find the current frame based on currentTime
        let frame = findFrame(at: currentTime)
        context.coordinator.updateSkeleton(in: skeletonAnchor, with: frame)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func findFrame(at time: TimeInterval) -> MotionFrame? {
        guard !recording.frames.isEmpty else { return nil }

        // Find the frame closest to the current time
        let frameIndex = Int(time * recording.fps)
        let clampedIndex = min(max(0, frameIndex), recording.frames.count - 1)
        return recording.frames[clampedIndex]
    }

    class Coordinator: NSObject {
        weak var arView: ARView?
        private var jointEntities: [String: Entity] = [:]
        private var boneEntities: [String: Entity] = [:]
        private var cameraYaw: Float = 0
        private var cameraPitch: Float = 0
        private var cameraDistance: Float = 3.2
        private var lastPanLocation: CGPoint = .zero

        // Joint sphere properties
        private let jointRadius: Float = 0.02
        private let jointColor = UIColor.systemBlue

        // Bone cylinder properties
        private let boneRadius: Float = 0.008
        private let boneColor = UIColor.systemCyan

        func setupSkeleton(in anchor: AnchorEntity) {
            // Create joint spheres
            let jointMaterial = SimpleMaterial(color: jointColor, isMetallic: false)
            let jointMesh = MeshResource.generateSphere(radius: jointRadius)

            for joint in TrackedJoint.allCases {
                let entity = ModelEntity(mesh: jointMesh, materials: [jointMaterial])
                entity.name = joint.rawValue
                entity.position = .zero
                anchor.addChild(entity)
                jointEntities[joint.rawValue] = entity
            }

            // Create bone cylinders
            let boneMaterial = SimpleMaterial(color: boneColor, isMetallic: false)

            for (index, connection) in JointConnection.connections.enumerated() {
                let boneEntity = ModelEntity()
                boneEntity.name = "bone_\(index)"
                boneEntity.model = ModelComponent(
                    mesh: .generateCylinder(height: 0.1, radius: boneRadius),
                    materials: [boneMaterial]
                )
                anchor.addChild(boneEntity)
                boneEntities["bone_\(index)"] = boneEntity
            }

        }

        func updateSkeleton(in anchor: AnchorEntity, with frame: MotionFrame?) {
            guard let frame = frame else {
                // Hide all entities if no frame
                for entity in jointEntities.values {
                    entity.isEnabled = false
                }
                for entity in boneEntities.values {
                    entity.isEnabled = false
                }
                return
            }

            // Update joint positions
            for joint in TrackedJoint.allCases {
                guard let jointData = frame.joints[joint.rawValue],
                      let entity = jointEntities[joint.rawValue] else { continue }

                entity.isEnabled = true
                entity.position = jointData.position
            }

            // Update bone positions and orientations
            for (index, connection) in JointConnection.connections.enumerated() {
                guard let fromJoint = frame.joints[connection.from.rawValue],
                      let toJoint = frame.joints[connection.to.rawValue],
                      let boneEntity = boneEntities["bone_\(index)"] as? ModelEntity else { continue }

                boneEntity.isEnabled = true

                let startPos = fromJoint.position
                let endPos = toJoint.position
                let midPoint = (startPos + endPos) / 2
                let direction = endPos - startPos
                let length = simd_length(direction)

                if length > 0.001 {
                    // Update bone mesh with correct length
                    boneEntity.model?.mesh = .generateCylinder(height: length, radius: boneRadius)
                    boneEntity.position = midPoint

                    // Orient the cylinder to point from start to end
                    let normalizedDirection = simd_normalize(direction)
                    let up = SIMD3<Float>(0, 1, 0)

                    if abs(simd_dot(normalizedDirection, up)) > 0.999 {
                        // Handle case where direction is nearly parallel to up vector
                        if normalizedDirection.y > 0 {
                            boneEntity.orientation = simd_quatf(angle: 0, axis: [1, 0, 0])
                        } else {
                            boneEntity.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                        }
                    } else {
                        let rotationAxis = simd_normalize(simd_cross(up, normalizedDirection))
                        let angle = acos(simd_dot(up, normalizedDirection))
                        boneEntity.orientation = simd_quatf(angle: angle, axis: rotationAxis)
                    }
                } else {
                    boneEntity.isEnabled = false
                }
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }

            let location = gesture.location(in: arView)

            switch gesture.state {
            case .began:
                lastPanLocation = location
            case .changed:
                let deltaX = Float(location.x - lastPanLocation.x) * 0.01
                let deltaY = Float(location.y - lastPanLocation.y) * 0.01

                cameraYaw -= deltaX
                cameraPitch -= deltaY
                cameraPitch = max(-.pi/3, min(.pi/3, cameraPitch))

                updateCameraPosition()
                lastPanLocation = location
            default:
                break
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .changed:
                cameraDistance /= Float(gesture.scale)
                cameraDistance = max(1.5, min(6.0, cameraDistance))
                gesture.scale = 1.0
                updateCameraPosition()
            default:
                break
            }
        }

        private func updateCameraPosition() {
            guard let arView = arView else { return }

            // Find the camera entity
            for anchor in arView.scene.anchors {
                for child in anchor.children {
                    if child is PerspectiveCamera {
                        let x = cameraDistance * sin(cameraYaw) * cos(cameraPitch)
                        let y = 0.85 + cameraDistance * sin(cameraPitch)
                        let z = cameraDistance * cos(cameraYaw) * cos(cameraPitch)

                        child.position = [x, y, z]
                        child.look(at: [0, 0.75, 0], from: child.position, relativeTo: nil)
                        return
                    }
                }
            }
        }
    }
}

#Preview {
    SkeletonPreviewView(
        recording: MotionRecording(
            name: "Test",
            duration: 10,
            frames: []
        ),
        currentTime: .constant(0)
    )
    .frame(height: 300)
    .padding()
}
