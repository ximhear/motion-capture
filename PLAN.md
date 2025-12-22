# ARKit Body Tracking → Blender 모션 캡처 프로젝트

## 프로젝트 개요

ARKit의 Body Tracking 기능을 활용하여 사람의 동작을 캡처하고,
해당 데이터를 Blender로 전달하여 3D 캐릭터에 애니메이션을 적용하는 시스템 구축

## 아키텍처

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│   iOS 앱        │────▶│  데이터 전송  │────▶│   Blender   │
│ (ARKit Body     │     │  (JSON/BVH)  │     │ (Python     │
│  Tracking)      │     │              │     │  Script)    │
└─────────────────┘     └──────────────┘     └─────────────┘
```

---

## iOS 앱 화면 구성

### 1. 홈 화면 (MotionListView)
- 저장된 모션 캡처 목록 표시
- 스와이프로 삭제
- [+] 버튼으로 새 캡처 시작

### 2. 캡처 화면 (CaptureView)
- AR 카메라 + 실시간 스켈레톤 표시
- Body 감지 상태 표시
- 녹화 시작/중지 버튼
- 녹화 시간 표시

### 3. 저장 화면 (SaveCaptureView)
- 녹화 이름 입력
- 메모 추가 (선택)
- 녹화 정보 표시 (시간, 프레임 수, FPS)

### 4. 상세 화면 (MotionDetailView)
- 3D 스켈레톤 재생 뷰
- 타임라인 스크러빙
- 재생/일시정지/프레임 이동
- 내보내기 옵션 (JSON, 파일 공유)

---

## 구현 단계

### Phase 1: iOS 앱 - ARKit Body Tracking 기본 구현
- [x] 프로젝트 구조 설정
- [x] ARBodyTrackingConfiguration 설정
- [x] ARView를 사용한 카메라 뷰 표시
- [x] ARBodyAnchor 데이터 수신 및 처리
- [x] 화면에 스켈레톤 실시간 시각화
- [x] Info.plist 카메라 권한 설정

**기술 스펙:**
- 최소 iOS 13.0+
- A12 Bionic 이상 (iPhone XS, XR 이상)
- ARKit 3.0+

### Phase 2: 모션 데이터 녹화 기능
- [x] 녹화 시작/중지 UI 구현
- [x] 프레임별 관절 데이터 저장
- [x] JSON 형식으로 데이터 직렬화
- [x] 파일 저장 및 공유 기능
- [x] 녹화 목록 관리

**데이터 포맷 (JSON):**
```json
{
  "version": "1.0",
  "fps": 60,
  "frameCount": 1800,
  "duration": 30.0,
  "joints": ["hips_joint", "spine_1_joint", ...],
  "frames": [
    {
      "timestamp": 0.0,
      "joints": {
        "hips_joint": {
          "position": [x, y, z],
          "rotation": [x, y, z, w]
        }
      }
    }
  ]
}
```

### Phase 3: Blender 데이터 임포트
- [ ] JSON 파서 Python 스크립트 작성
- [ ] ARKit 관절 → Blender 아마추어 매핑 테이블 정의
- [ ] 키프레임 애니메이션 생성
- [ ] MCP 통합 테스트

**ARKit 주요 관절 목록:**
- hips_joint (루트)
- spine_1_joint ~ spine_7_joint
- left/right_shoulder_1_joint
- left/right_arm_joint
- left/right_forearm_joint
- left/right_hand_joint
- left/right_upLeg_joint
- left/right_leg_joint
- left/right_foot_joint
- head_joint
- neck_1_joint ~ neck_4_joint

### Phase 4: 캐릭터 애니메이션 적용
- [ ] 기본 인체 모델 준비 (Mixamo 또는 직접 제작)
- [ ] 리깅 및 본 구조 설정
- [ ] 모션 리타겟팅
- [ ] 최종 애니메이션 렌더링

### Phase 5 (선택): 실시간 스트리밍
- [ ] WebSocket 서버 구현 (Blender 측)
- [ ] iOS 앱에 WebSocket 클라이언트 추가
- [ ] 실시간 데이터 전송 및 적용
- [ ] 지연 시간 최적화

---

## 진행 상황

| 날짜 | 작업 내용 | 상태 |
|------|----------|------|
| 2024-12-22 | 프로젝트 초기 설정, 계획 수립 | ✅ 완료 |
| 2024-12-22 | iOS 앱 화면 구조 및 파일 생성 | ✅ 완료 |
| 2024-12-22 | Phase 1 & 2 기본 코드 작성 | ✅ 완료 |
| | 실제 디바이스 테스트 | ⏳ 대기 |
| | Phase 3 Blender 스크립트 | ⏳ 대기 |

---

## 참고 자료

- [ARKit Body Tracking - Apple Developer](https://developer.apple.com/documentation/arkit/arkit_in_ios/content_anchors/validating_a_model_for_motion_capture)
- [ARBodyAnchor](https://developer.apple.com/documentation/arkit/arbodyanchor)
- [ARSkeleton](https://developer.apple.com/documentation/arkit/arskeleton)
- [Blender Python API](https://docs.blender.org/api/current/)

---

## 기술적 고려사항

### ARKit Body Tracking 제약
1. 전신이 카메라 시야에 들어와야 함
2. 한 번에 한 사람만 추적 가능
3. 조명이 충분해야 정확도 향상

### 데이터 변환 시 주의점
1. ARKit: Y-up, 미터 단위
2. Blender: Z-up (기본), 미터 단위
3. 좌표계 변환 필요 (Y ↔ Z)
4. 쿼터니언 회전 순서 확인

---

## 파일 구조

```
MotionCapture/
├── MotionCapture/
│   ├── MotionCaptureApp.swift          # 앱 진입점
│   ├── Models/
│   │   ├── MotionCapture.swift         # 데이터 모델
│   │   └── JointMapping.swift          # ARKit 관절 매핑
│   ├── Views/
│   │   ├── MotionListView.swift        # 홈/리스트 화면
│   │   ├── CaptureView.swift           # 캡처 화면
│   │   ├── SaveCaptureView.swift       # 저장 화면
│   │   ├── MotionDetailView.swift      # 상세 보기
│   │   └── Components/
│   │       ├── MotionRowView.swift     # 리스트 셀
│   │       └── ARViewContainer.swift   # AR 뷰 래퍼
│   ├── Services/
│   │   ├── BodyTrackingService.swift   # ARKit 트래킹
│   │   ├── MotionStorageService.swift  # 파일 저장
│   │   └── ExportService.swift         # 내보내기
│   └── Assets.xcassets/
├── BlenderScripts/                      # (예정)
│   ├── import_motion.py
│   └── realtime_receiver.py
└── PLAN.md
```
