//
//  ExportService.swift
//  MotionCapture
//

import Foundation

class ExportService {
    static let shared = ExportService()

    private init() {}

    /// Export recording to JSON format suitable for Blender import
    func exportToBlenderJSON(_ recording: MotionRecording) -> String? {
        let exportData = MotionExportData(from: recording)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let jsonData = try? encoder.encode(exportData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }

    /// Export recording to BVH format (Biovision Hierarchy)
    /// This is a standard motion capture format that Blender can import directly
    func exportToBVH(_ recording: MotionRecording) -> String? {
        var bvh = ""

        // HIERARCHY section (already includes "HIERARCHY\n")
        bvh += buildBVHHierarchy()

        // MOTION section
        bvh += "MOTION\n"
        bvh += "Frames: \(recording.frameCount)\n"
        bvh += "Frame Time: \(String(format: "%.6f", 1.0 / recording.fps))\n"

        // Frame data
        for frame in recording.frames {
            bvh += buildBVHFrameData(frame: frame)
            bvh += "\n"
        }

        return bvh
    }

    private func buildBVHHierarchy() -> String {
        // Hierarchy matching TrackedJoint (22 joints)
        // ARKit Y-up -> BVH Y-up (compatible)
        return """
HIERARCHY
ROOT Hips
{
    OFFSET 0.0 0.0 0.0
    CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
    JOINT Spine
    {
        OFFSET 0.0 0.1 0.0
        CHANNELS 3 Zrotation Xrotation Yrotation
        JOINT Spine1
        {
            OFFSET 0.0 0.15 0.0
            CHANNELS 3 Zrotation Xrotation Yrotation
            JOINT Neck
            {
                OFFSET 0.0 0.2 0.0
                CHANNELS 3 Zrotation Xrotation Yrotation
                JOINT Head
                {
                    OFFSET 0.0 0.1 0.0
                    CHANNELS 3 Zrotation Xrotation Yrotation
                    End Site
                    {
                        OFFSET 0.0 0.15 0.0
                    }
                }
            }
            JOINT LeftShoulder
            {
                OFFSET 0.05 0.15 0.0
                CHANNELS 3 Zrotation Xrotation Yrotation
                JOINT LeftArm
                {
                    OFFSET 0.1 0.0 0.0
                    CHANNELS 3 Zrotation Xrotation Yrotation
                    JOINT LeftForeArm
                    {
                        OFFSET 0.28 0.0 0.0
                        CHANNELS 3 Zrotation Xrotation Yrotation
                        JOINT LeftHand
                        {
                            OFFSET 0.25 0.0 0.0
                            CHANNELS 3 Zrotation Xrotation Yrotation
                            End Site
                            {
                                OFFSET 0.1 0.0 0.0
                            }
                        }
                    }
                }
            }
            JOINT RightShoulder
            {
                OFFSET -0.05 0.15 0.0
                CHANNELS 3 Zrotation Xrotation Yrotation
                JOINT RightArm
                {
                    OFFSET -0.1 0.0 0.0
                    CHANNELS 3 Zrotation Xrotation Yrotation
                    JOINT RightForeArm
                    {
                        OFFSET -0.28 0.0 0.0
                        CHANNELS 3 Zrotation Xrotation Yrotation
                        JOINT RightHand
                        {
                            OFFSET -0.25 0.0 0.0
                            CHANNELS 3 Zrotation Xrotation Yrotation
                            End Site
                            {
                                OFFSET -0.1 0.0 0.0
                            }
                        }
                    }
                }
            }
        }
    }
    JOINT LeftUpLeg
    {
        OFFSET 0.1 0.0 0.0
        CHANNELS 3 Zrotation Xrotation Yrotation
        JOINT LeftLeg
        {
            OFFSET 0.0 -0.45 0.0
            CHANNELS 3 Zrotation Xrotation Yrotation
            JOINT LeftFoot
            {
                OFFSET 0.0 -0.43 0.0
                CHANNELS 3 Zrotation Xrotation Yrotation
                JOINT LeftToeBase
                {
                    OFFSET 0.0 -0.05 0.1
                    CHANNELS 3 Zrotation Xrotation Yrotation
                    End Site
                    {
                        OFFSET 0.0 0.0 0.08
                    }
                }
            }
        }
    }
    JOINT RightUpLeg
    {
        OFFSET -0.1 0.0 0.0
        CHANNELS 3 Zrotation Xrotation Yrotation
        JOINT RightLeg
        {
            OFFSET 0.0 -0.45 0.0
            CHANNELS 3 Zrotation Xrotation Yrotation
            JOINT RightFoot
            {
                OFFSET 0.0 -0.43 0.0
                CHANNELS 3 Zrotation Xrotation Yrotation
                JOINT RightToeBase
                {
                    OFFSET 0.0 -0.05 0.1
                    CHANNELS 3 Zrotation Xrotation Yrotation
                    End Site
                    {
                        OFFSET 0.0 0.0 0.08
                    }
                }
            }
        }
    }
}

"""
    }

    private func buildBVHFrameData(frame: MotionFrame) -> String {
        // Order must match the CHANNELS definition in hierarchy
        // TrackedJoint에 정의된 실제 추적 관절만 사용 (22개)
        let jointOrder = [
            "hips_joint",               // Root: 6 channels (position + rotation)
            "spine_2_joint",            // Spine: 3 channels (rotation only)
            "spine_4_joint",            // Spine1
            "neck_1_joint",             // Neck
            "head_joint",               // Head
            "left_shoulder_1_joint",    // LeftShoulder
            "left_arm_joint",           // LeftArm
            "left_forearm_joint",       // LeftForeArm
            "left_hand_joint",          // LeftHand
            "right_shoulder_1_joint",   // RightShoulder
            "right_arm_joint",          // RightArm
            "right_forearm_joint",      // RightForeArm
            "right_hand_joint",         // RightHand
            "left_upLeg_joint",         // LeftUpLeg
            "left_leg_joint",           // LeftLeg
            "left_foot_joint",          // LeftFoot
            "left_toes_joint",          // LeftToeBase
            "right_upLeg_joint",        // RightUpLeg
            "right_leg_joint",          // RightLeg
            "right_foot_joint",         // RightFoot
            "right_toes_joint"          // RightToeBase
        ]

        var values: [String] = []

        for (index, jointName) in jointOrder.enumerated() {
            if let joint = frame.joints[jointName] {
                // Root joint includes position
                if index == 0 {
                    values.append(String(format: "%.6f", joint.position.x))
                    values.append(String(format: "%.6f", joint.position.y))
                    values.append(String(format: "%.6f", joint.position.z))
                }

                // Convert quaternion to Euler angles (ZXY order for BVH)
                let euler = quaternionToEuler(joint.rotation)
                values.append(String(format: "%.6f", euler.z))
                values.append(String(format: "%.6f", euler.x))
                values.append(String(format: "%.6f", euler.y))
            } else {
                // Default values if joint not found
                if index == 0 {
                    values.append(contentsOf: ["0.0", "0.0", "0.0"])
                }
                values.append(contentsOf: ["0.0", "0.0", "0.0"])
            }
        }

        return values.joined(separator: " ")
    }

    private func quaternionToEuler(_ q: Quaternion) -> (x: Float, y: Float, z: Float) {
        // Convert quaternion to Euler angles in degrees
        let sinr_cosp = 2 * (q.w * q.x + q.y * q.z)
        let cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y)
        let x = atan2(sinr_cosp, cosr_cosp)

        let sinp = 2 * (q.w * q.y - q.z * q.x)
        let y: Float
        if abs(sinp) >= 1 {
            y = copysign(.pi / 2, sinp)
        } else {
            y = asin(sinp)
        }

        let siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        let cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        let z = atan2(siny_cosp, cosy_cosp)

        // Convert to degrees
        let toDegrees: Float = 180.0 / .pi
        return (x * toDegrees, y * toDegrees, z * toDegrees)
    }
}
