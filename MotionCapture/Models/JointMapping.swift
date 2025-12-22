//
//  JointMapping.swift
//  MotionCapture
//

import Foundation

/// ARKit Body Tracking에서 실제로 추적되는 주요 관절들
/// 손가락, 눈 등 추정값만 제공되는 관절은 제외
enum TrackedJoint: String, CaseIterable {
    // Root
    case hips = "hips_joint"

    // Spine (주요 3개만 - 나머지는 보간값)
    case spine2 = "spine_2_joint"
    case spine4 = "spine_4_joint"
    case spine7 = "spine_7_joint"

    // Neck & Head
    case neck1 = "neck_1_joint"
    case head = "head_joint"

    // Left Arm
    case leftShoulder1 = "left_shoulder_1_joint"
    case leftArm = "left_arm_joint"
    case leftForearm = "left_forearm_joint"
    case leftHand = "left_hand_joint"

    // Right Arm
    case rightShoulder1 = "right_shoulder_1_joint"
    case rightArm = "right_arm_joint"
    case rightForearm = "right_forearm_joint"
    case rightHand = "right_hand_joint"

    // Left Leg
    case leftUpLeg = "left_upLeg_joint"
    case leftLeg = "left_leg_joint"
    case leftFoot = "left_foot_joint"
    case leftToes = "left_toes_joint"

    // Right Leg
    case rightUpLeg = "right_upLeg_joint"
    case rightLeg = "right_leg_joint"
    case rightFoot = "right_foot_joint"
    case rightToes = "right_toes_joint"

    /// 모든 추적 관절 이름 (String 배열)
    static var allJointNames: [String] {
        allCases.map { $0.rawValue }
    }

    /// 관절 수
    static var count: Int {
        allCases.count
    }
}

/// Mapping between ARKit joints and Blender armature bones (Mixamo 호환)
struct BlenderJointMapping {
    static let arkitToBlender: [String: String] = [
        "hips_joint": "Hips",
        "spine_2_joint": "Spine",
        "spine_4_joint": "Spine1",
        "spine_7_joint": "Spine2",
        "neck_1_joint": "Neck",
        "head_joint": "Head",
        "left_shoulder_1_joint": "LeftShoulder",
        "left_arm_joint": "LeftArm",
        "left_forearm_joint": "LeftForeArm",
        "left_hand_joint": "LeftHand",
        "right_shoulder_1_joint": "RightShoulder",
        "right_arm_joint": "RightArm",
        "right_forearm_joint": "RightForeArm",
        "right_hand_joint": "RightHand",
        "left_upLeg_joint": "LeftUpLeg",
        "left_leg_joint": "LeftLeg",
        "left_foot_joint": "LeftFoot",
        "left_toes_joint": "LeftToeBase",
        "right_upLeg_joint": "RightUpLeg",
        "right_leg_joint": "RightLeg",
        "right_foot_joint": "RightFoot",
        "right_toes_joint": "RightToeBase"
    ]

    /// Blender 본 이름으로 ARKit 관절 이름 찾기
    static let blenderToArkit: [String: String] = {
        Dictionary(uniqueKeysWithValues: arkitToBlender.map { ($1, $0) })
    }()
}

/// 관절 간 연결 정보 (스켈레톤 시각화용)
struct JointConnection {
    let from: TrackedJoint
    let to: TrackedJoint

    static let connections: [JointConnection] = [
        // Spine
        JointConnection(from: .hips, to: .spine2),
        JointConnection(from: .spine2, to: .spine4),
        JointConnection(from: .spine4, to: .spine7),
        JointConnection(from: .spine7, to: .neck1),
        JointConnection(from: .neck1, to: .head),

        // Left Arm
        JointConnection(from: .spine7, to: .leftShoulder1),
        JointConnection(from: .leftShoulder1, to: .leftArm),
        JointConnection(from: .leftArm, to: .leftForearm),
        JointConnection(from: .leftForearm, to: .leftHand),

        // Right Arm
        JointConnection(from: .spine7, to: .rightShoulder1),
        JointConnection(from: .rightShoulder1, to: .rightArm),
        JointConnection(from: .rightArm, to: .rightForearm),
        JointConnection(from: .rightForearm, to: .rightHand),

        // Left Leg
        JointConnection(from: .hips, to: .leftUpLeg),
        JointConnection(from: .leftUpLeg, to: .leftLeg),
        JointConnection(from: .leftLeg, to: .leftFoot),
        JointConnection(from: .leftFoot, to: .leftToes),

        // Right Leg
        JointConnection(from: .hips, to: .rightUpLeg),
        JointConnection(from: .rightUpLeg, to: .rightLeg),
        JointConnection(from: .rightLeg, to: .rightFoot),
        JointConnection(from: .rightFoot, to: .rightToes),
    ]
}
