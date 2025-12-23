# Blender Scripts for Motion Capture

iOS MotionCapture 앱에서 캡처한 모션 데이터를 Blender로 가져오기 위한 스크립트입니다.

## 요구사항

- Blender 3.0 이상
- Mixamo 호환 Armature가 있는 3D 캐릭터

## 설치 방법

### 방법 1: Add-on으로 설치 (권장)

1. Blender 열기
2. `Edit` → `Preferences` → `Add-ons`
3. `Install...` 버튼 클릭
4. `import_motion.py` 파일 선택
5. 설치된 add-on 체크박스 활성화

### 방법 2: 직접 실행

1. Blender에서 `Scripting` 워크스페이스로 이동
2. `import_motion.py` 파일 열기
3. `Run Script` 버튼 클릭 (또는 Alt+P)

## 사용 방법

### 1단계: 캐릭터 준비

Mixamo에서 캐릭터 다운로드:
1. [Mixamo](https://www.mixamo.com) 접속
2. 원하는 캐릭터 선택
3. `Download` 클릭
   - Format: FBX Binary
   - Pose: T-Pose
4. Blender에서 `File` → `Import` → `FBX` 로 가져오기

### 2단계: 모션 데이터 가져오기

1. 캐릭터의 Armature 선택
2. `File` → `Import` → `Motion Capture (.json)`
3. iOS 앱에서 export한 JSON 파일 선택
4. 옵션 설정:
   - **Scale**: 위치 데이터 스케일 (기본값: 1.0)
   - **Apply Root Motion**: 루트 위치 애니메이션 적용 여부

### 3단계: 확인 및 조정

- Timeline에서 애니메이션 재생
- 필요시 Graph Editor에서 커브 조정
- NLA Editor로 여러 모션 클립 조합 가능

## 지원되는 관절

| ARKit 관절 | Blender 본 |
|-----------|-----------|
| hips_joint | Hips |
| spine_2_joint | Spine |
| spine_4_joint | Spine1 |
| spine_7_joint | Spine2 |
| neck_1_joint | Neck |
| head_joint | Head |
| left_shoulder_1_joint | LeftShoulder |
| left_arm_joint | LeftArm |
| left_forearm_joint | LeftForeArm |
| left_hand_joint | LeftHand |
| right_shoulder_1_joint | RightShoulder |
| right_arm_joint | RightArm |
| right_forearm_joint | RightForeArm |
| right_hand_joint | RightHand |
| left_upLeg_joint | LeftUpLeg |
| left_leg_joint | LeftLeg |
| left_foot_joint | LeftFoot |
| left_toes_joint | LeftToeBase |
| right_upLeg_joint | RightUpLeg |
| right_leg_joint | RightLeg |
| right_foot_joint | RightFoot |
| right_toes_joint | RightToeBase |

## JSON 데이터 형식

```json
{
  "version": "1.0",
  "fps": 60.0,
  "frameCount": 120,
  "duration": 2.0,
  "joints": ["hips_joint", "spine_2_joint", ...],
  "frames": [
    {
      "timestamp": 0.0,
      "joints": {
        "hips_joint": {
          "position": [0.0, 1.0, 0.0],
          "rotation": [0.0, 0.0, 0.0, 1.0]
        }
      }
    }
  ]
}
```

## 문제 해결

### "No armature found" 오류
- 씬에 Armature가 있는지 확인
- Armature 오브젝트를 선택한 상태에서 import 실행

### 애니메이션이 이상하게 보임
- 캐릭터가 T-Pose 상태인지 확인
- Scale 값 조정 시도
- 좌표계 변환 문제일 수 있음 (ARKit: Y-up, Blender: Z-up)

### 일부 관절이 움직이지 않음
- 본 이름이 Mixamo 규칙을 따르는지 확인
- 커스텀 리그의 경우 스크립트의 `ARKIT_TO_BLENDER` 매핑 수정 필요
