"""
Motion Capture Import Script for Blender
=========================================
Imports motion capture data from the iOS MotionCapture app.

Usage:
1. Open Blender with a rigged character (Mixamo compatible)
2. Run this script from Blender's Text Editor or Scripting workspace
3. Select your JSON file when the file browser opens

Supported formats:
- JSON export from MotionCapture iOS app

Requirements:
- Blender 3.0 or higher
- Armature with Mixamo-compatible bone names
"""

import bpy
import json
import math
from mathutils import Quaternion, Vector, Matrix
from bpy_extras.io_utils import ImportHelper
from bpy.props import StringProperty, BoolProperty, FloatProperty
from bpy.types import Operator


# ARKit joint names to Blender/Mixamo bone names mapping
ARKIT_TO_BLENDER = {
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
    "right_toes_joint": "RightToeBase",
}


class MotionCaptureImporter:
    """Handles importing motion capture data to Blender armature."""

    def __init__(self, armature_obj, scale=1.0, apply_root_motion=True):
        self.armature = armature_obj
        self.scale = scale
        self.apply_root_motion = apply_root_motion
        self.bone_mapping = {}
        self._build_bone_mapping()

    def _build_bone_mapping(self):
        """Build mapping from ARKit joints to actual armature bones."""
        if not self.armature or self.armature.type != 'ARMATURE':
            return

        pose_bones = self.armature.pose.bones

        # Common prefixes used by various rigs
        PREFIXES = ['', 'mixamorig:', 'mixamorig9:', 'Armature|', 'Character|']

        for arkit_name, blender_name in ARKIT_TO_BLENDER.items():
            found = False

            # Try with various prefixes
            for prefix in PREFIXES:
                full_name = prefix + blender_name
                if full_name in pose_bones:
                    self.bone_mapping[arkit_name] = full_name
                    found = True
                    break

            if not found:
                # Fallback: case-insensitive search
                for bone in pose_bones:
                    # Remove any prefix and compare
                    bone_name_clean = bone.name.split(':')[-1] if ':' in bone.name else bone.name
                    if bone_name_clean.lower() == blender_name.lower():
                        self.bone_mapping[arkit_name] = bone.name
                        found = True
                        break

        # Debug: print mapping results
        print(f"Bone mapping results ({len(self.bone_mapping)}/{len(ARKIT_TO_BLENDER)} matched):")
        for arkit, blender in self.bone_mapping.items():
            print(f"  {arkit} -> {blender}")

    def import_json(self, filepath):
        """Import motion data from JSON file."""
        with open(filepath, 'r') as f:
            data = json.load(f)

        fps = data.get('fps', 60.0)
        frames = data.get('frames', [])

        if not frames:
            print("No frames found in motion data")
            return False

        # Set scene FPS
        bpy.context.scene.render.fps = int(fps)
        bpy.context.scene.render.fps_base = 1.0

        # Set frame range
        bpy.context.scene.frame_start = 1
        bpy.context.scene.frame_end = len(frames)

        # Import animation
        self._apply_animation(frames, fps)

        return True

    def _apply_animation(self, frames, fps):
        """Apply motion data to armature bones."""
        if not self.armature:
            print("No armature selected")
            return

        # Ensure we're in pose mode
        bpy.context.view_layer.objects.active = self.armature
        bpy.ops.object.mode_set(mode='POSE')

        pose_bones = self.armature.pose.bones

        for frame_idx, frame_data in enumerate(frames):
            frame_num = frame_idx + 1  # Blender frames start at 1
            bpy.context.scene.frame_set(frame_num)

            joints = frame_data.get('joints', {})

            for arkit_name, joint_data in joints.items():
                blender_bone_name = self.bone_mapping.get(arkit_name)
                if not blender_bone_name or blender_bone_name not in pose_bones:
                    continue

                pose_bone = pose_bones[blender_bone_name]

                # Apply local rotation (quaternion)
                # Data from iOS app is already local rotation (relative to parent bone)
                rotation = joint_data.get('rotation', [0, 0, 0, 1])
                local_quat = self._convert_quaternion(rotation)

                pose_bone.rotation_mode = 'QUATERNION'
                pose_bone.rotation_quaternion = local_quat
                pose_bone.keyframe_insert(data_path='rotation_quaternion', frame=frame_num)

                # Apply root position (only for hips)
                if arkit_name == 'hips_joint' and self.apply_root_motion:
                    position = joint_data.get('position', [0, 0, 0])
                    loc = self._convert_position(position)
                    pose_bone.location = loc
                    pose_bone.keyframe_insert(data_path='location', frame=frame_num)

        # Return to object mode
        bpy.ops.object.mode_set(mode='OBJECT')

        print(f"Imported {len(frames)} frames at {fps} FPS")

    def _convert_quaternion(self, rotation):
        """Convert ARKit quaternion to Blender quaternion.

        ARKit coordinate system: X-right, Y-up, Z-toward camera (right-handed)
        Blender coordinate system: X-right, Y-forward, Z-up (right-handed)

        Trying simpler axis remapping without sign change on Z:
        - ARKit X -> Blender X
        - ARKit Y -> Blender Z
        - ARKit Z -> Blender Y
        """
        x, y, z, w = rotation

        # Remap axes: swap Y and Z
        remapped = Quaternion((w, x, z, y))

        # Apply +90 degrees around X axis to stand up the character
        correction = Quaternion((0.7071068, 0.7071068, 0, 0))

        return correction @ remapped

    def _convert_position(self, position):
        """Convert ARKit position to Blender position.

        ARKit: X-right, Y-up, Z-toward camera
        Blender: X-right, Y-forward, Z-up

        Axis mapping (same as quaternion):
        - ARKit X -> Blender X
        - ARKit Y -> Blender Z
        - ARKit Z -> Blender Y
        """
        x, y, z = position
        return Vector((x * self.scale, z * self.scale, y * self.scale))


class IMPORT_OT_motion_capture(Operator, ImportHelper):
    """Import motion capture data from iOS app"""
    bl_idname = "import_anim.motion_capture"
    bl_label = "Import Motion Capture"
    bl_options = {'REGISTER', 'UNDO'}

    # File browser filter
    filename_ext = ".json"
    filter_glob: StringProperty(
        default="*.json",
        options={'HIDDEN'},
        maxlen=255,
    )

    # Import options
    scale: FloatProperty(
        name="Scale",
        description="Scale factor for position data",
        default=1.0,
        min=0.01,
        max=100.0,
    )

    apply_root_motion: BoolProperty(
        name="Apply Root Motion",
        description="Apply hip/root position animation",
        default=True,
    )

    def execute(self, context):
        # Find armature
        armature = None

        # First check if an armature is selected
        if context.active_object and context.active_object.type == 'ARMATURE':
            armature = context.active_object
        else:
            # Find first armature in scene
            for obj in context.scene.objects:
                if obj.type == 'ARMATURE':
                    armature = obj
                    break

        if not armature:
            self.report({'ERROR'}, "No armature found in scene. Please add a rigged character first.")
            return {'CANCELLED'}

        # Import motion
        importer = MotionCaptureImporter(
            armature,
            scale=self.scale,
            apply_root_motion=self.apply_root_motion
        )

        success = importer.import_json(self.filepath)

        if success:
            self.report({'INFO'}, f"Motion imported successfully to {armature.name}")
            return {'FINISHED'}
        else:
            self.report({'ERROR'}, "Failed to import motion data")
            return {'CANCELLED'}

    def draw(self, context):
        layout = self.layout
        layout.prop(self, "scale")
        layout.prop(self, "apply_root_motion")


def menu_func_import(self, context):
    self.layout.operator(IMPORT_OT_motion_capture.bl_idname, text="Motion Capture (.json)")


def register():
    bpy.utils.register_class(IMPORT_OT_motion_capture)
    bpy.types.TOPBAR_MT_file_import.append(menu_func_import)


def unregister():
    bpy.utils.unregister_class(IMPORT_OT_motion_capture)
    bpy.types.TOPBAR_MT_file_import.remove(menu_func_import)


if __name__ == "__main__":
    register()

    # If run directly, open file browser
    bpy.ops.import_anim.motion_capture('INVOKE_DEFAULT')
