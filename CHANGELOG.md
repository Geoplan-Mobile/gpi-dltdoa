# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [1.2.0] - 2026-06-22

### ⚠️ Breaking Change — 기존 캘리브레이션 데이터 폐기 필수
- 내부 TDoA 계산식이 iOS 27 의 API 변경으로 인해 변경되었습니다.
- **v1.1.x 까지의 캘리브레이션으로 산출한 `anchorOffsets` 데이터는 더이상 사용할 수 없습니다.**
- **마이그레이션**: 기존에 `positioner.anchorOffsets` 에 사용하던 코드 제거.
- `positioner.anchorOffsets` 프로퍼티 및 관련 캘리 API 는 **추후 버전에서 deprecate 될 예정** 입니다 (당분간 호환을 위해 유지).

### 변경됨
- 캘리브레이션 단계가 **선택 사항**으로 바뀌었습니다. 일반 운영에서는 호출 불필요.(한다해도 거의 0에 수렴)
  - 기존 `startCalibration` / `stopCalibration` API 는 호환을 위해 유지됩니다.
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
