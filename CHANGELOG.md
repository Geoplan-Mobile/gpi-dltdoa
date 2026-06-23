# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [2.0.0] - 2026-06-23

### ⚠️ Breaking Change — 캘리브레이션 API 전면 제거
- 내부 TDoA 계산식이 iOS 27 의 API 변경에 맞춰 다시 작성되었습니다. 그 결과 캘리값이 더이상 사용되지 않아 관련 API 를 모두 제거했습니다.
- 제거된 API:
  - `DLTDoAPositioner.anchorOffsets`
  - `DLTDoAPositioner.calibrationState`
  - `DLTDoAPositioner.startCalibration(at:targetCount:)`
  - `DLTDoAPositioner.stopCalibration()`
  - `CalibrationState` enum 전체
- **마이그레이션**: 위 API 를 참조하는 호스트 앱 코드를 모두 제거하세요. UserDefaults 등에 영속화한 옛 `anchorOffsets` 데이터도 사용처가 없어졌으므로 함께 정리하시면 됩니다.

### 변경됨
- 측위 요구사항: **iOS 27.0+ 기기** 에서만 측위 가능. framework 의 deployment target 은 iOS 18 그대로 유지되므로 SPM 추가는 낮은 베이스라인 앱에서도 가능하나, 측위 호출은 `if #available(iOS 27.0, *)` 가드가 필요합니다.

## [1.1.1] - 2026-06-12

### 수정됨
- **SDK 버전 반환 오류 수정**: `DLTDoAPositioner.sdkVersion` 호출 시 라이브러리를 포함한 앱의 버전이 나오던 문제를 수정하여, 라이브러리의 실제 버전이 나오도록 수정되었습니다.

## [1.1.0] - 2026-06-12

### 추가됨
- **iOS Simulator 지원**: `xcframework` 내에 `ios-arm64_x86_64-simulator` 슬라이스를 추가하여 시뮬레이터 환경에서도 빌드 및 실행이 가능합니다.
- **SDK 버전 확인 프로퍼티**: `DLTDoAPositioner.sdkVersion` (static) 프로퍼티를 추가하여 코드상에서 현재 라이브러리 버전을 확인할 수 있습니다.
- **버전 식별 파일**: 루트 디렉토리에 `VERSION_1.1.0` 파일이 추가되어, 프로젝트 연동 없이도 배포 버전을 쉽게 확인할 수 있습니다.

### 변경됨
- `README.md` 가 v1.1.0 기준으로 업데이트 되었습니다.
