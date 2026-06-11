# gpi-dltdoa (Swift Package)

본 저장소는 `gpi-dltdoa` 측위 코어 알고리즘의 외부 연동 장착을 위한 **배포 전용 릴리즈 저장소(Release Repository)**이다.  
사전 컴파일(Pre-compiled) 및 난독화가 완료된 정적 `XCFramework` 형태의 바이너리를 SPM(Swift Package Manager) 포맷으로 독립 제공한다.

> **💡 엔진 코어 역량 요약**
> Apple의 **Nearby Interaction (UWB)** 인프라 기반 동작.  
> UWB Anchor 상호 간의 DTM(Downlink TDoA) 패킷 시간차 데이터를 분석하여 기기 단말(Device)의 실시간 (X, Y) 실내 좌표를 초정밀 역산.

---

## 프로젝트 연동 및 사용 방법 (Usage)

외부 애플리케이션 타겟 프로젝트에서 본 라이브러리를 종속성으로 연동하고 내부 객체를 제어하는 표준 절차 명세이다.  
코어 컨트롤러인 `DLTDoAPositioner` 클래스는 `@MainActor` 기반의 `ObservableObject`로 설계되어 있어 SwiftUI 생태계에 최적화되어 있다.  

### 1. Xcode 외부 패키지(SPM) 연동
가장 먼저 대상이 되는 타겟 App 프로젝트에 본 바이너리 프레임워크를 종속성으로 추가해야 한다.
1. 타겟 앱을 연 상태로 Xcode 상단 메뉴에서 **[File] ➡ [Add Package Dependencies...]** 를 클릭한다.
2. 우측 상단의 검색창(Search or Enter Package URL)에 아래의 SPM 배포 전용 저장소 주소를 입력한다.  
   `https://github.com/Geoplan-Mobile/gpi-dltdoa`  
   *(주의: 저장소가 Private인 경우 본인의 깃허브 계정이 해당 저장소의 Collaborator로 사전에 등록되어 있어야 인증이 통과된다.)*
3. **Dependency Rule**을 필요에 맞게 설정한 뒤, **[Add Package]** 버튼을 클릭하여 연동을 완료한다.

### 2. DLTDoAPositioner 인스턴스 생성 및 패킷 주입
DLTDoAPositioner 인스턴스를 하나 생성하고 Apple의 예약된 `NearbyInteraction` 세션에서  
측정값(`NIDLTDOAMeasurement` 이하 DTM)을 수신할 때마다 DLTDoAPositioner의 `update()` 메서드에 그대로 주입만 수행한다.

```swift
import NearbyInteraction
import gpi_dltdoa

class MyPositioningService: NSObject, NISessionDelegate {
    // 1. 엔진 객체 생성
    let positioner = DLTDoAPositioner(minRssi: -90.0)

    func session(_ session: NISession, didUpdateMeasurements measurements: [NIDLTDOAMeasurement]) {
        // 2. UWB 수신 이벤트 발생 시 패킷 배열을 가감 없이 코어 엔진에 주입.
        positioner.update(measurements: measurements)
    }
}
```

### 3. 위치 좌표 모니터링 (`estimatedPosition`)
엔진 내부에 패킷이 연속 공급되면, 실시간 행렬 연산 결과가 옵셔널 3차원 벡터(`simd_double3?`) 형태인 `estimatedPosition` 변수에 즉시 반영된다.  
SwiftUI 환경에서 관찰(Observe)하도록 연결하여 `estimatedPosition` 변수의 변화를 감지 할 수 있다.

```swift
import SwiftUI
import gpi_dltdoa

struct MapView: View {
    // 측정값을 주입받으며 연산을 수행 중인 코어 객체
    @ObservedObject var positioner: DLTDoAPositioner

    var body: some View {
        VStack {
            if let pos = positioner.estimatedPosition {
                // x, y 좌표 추출. (실내 2D 평면 측위 기준 z축은 0.0을 사용한다)
                Text("측위 좌표: [ X: \(String(format: "%.2f", pos.x)), Y: \(String(format: "%.2f", pos.y)) ]")
            }
        }
    }
}
```

> **핵심 속성: `estimatedPosition` 생명주기**
> - **옵셔널(`nil`) 상태 대응**: 시스템 구동 직후 패킷 샘플이 부족하여 교점 연산 방정식 수렴에 실패했거나,  
> 신호(RSSI)를 완전히 잃어버렸을 경우에는 강제로 `nil`을 반환하므로 옵셔널 언래핑 바인딩 처리가 필수적이다.
> - **외부 감지**: `@Published` 이벤트를 방출하기 때문에 값이 변동될 때마다 외부에서 감지가 가능하다.

### 4. 앵커 위치(좌표) 외부 주입 매핑 (Override)
정밀 측위를 위해서는 각 UWB 앵커들이 실제 공간 도면(지도) 상 어디에 좌표 매핑되어 있는지 엔진에 고지해야 한다.   
NISession을 통해 수신된 DTM에는 앵커의 좌표가 포함되지만, 외부 인프라를 이용하는 경우 아래와 같이 주입이 가능하다.  
수신된 DTM의 앵커가 주입된 데이터에 존재 시 DTM의 좌표 대신 주입된 좌표가 사용 된다.
```swift
// MAC 주소(Int) 식별자 기준, 앵커 절대 좌표(미터 단위) 강제 오버라이드.
positioner.anchorCoordinatesOverride = [
    0xAC69: simd_double3(x: 1.0, y: 2.5, z: 2.0),
    0xB4BF: simd_double3(x: 5.0, y: 5.5, z: 2.0),
    0xF4F6: simd_double3(x: 8.0, y: 1.5, z: 2.0)
]
```

### 5. 하드웨어 안테나 지연 오차 보정 (Calibration) 및 오프셋 관리
UWB 앵커 기기들은 장치 제조사의 하드웨어 특성에 따른 태생적 송수신 지연이 존재한다.  
라이브러리는 위치를 이미 정확히 알고 있는 캘리브레이션 테스트 지점(Known Position) 위에  
스마트폰을 잠시 위치시키어 오차값을 역산출 하는 자동화 API를 내장 지원한다.

```swift
// A. 캘리브레이션 시작 명령 하달
// 현재 폰의 물리적 정답 좌표(예: x: 1.0m, y: 1.0m 지점)와 누적 대기할 샘플 카운트(기본 최소 100회) 주입.
let knownPosition = simd_double3(1.0, 1.0, 0.0)
positioner.startCalibration(at: knownPosition, targetCount: 100)

// B. 오차 역산출 (내부 자동 수집)
// 명령 하달 이후 NISession에서 positioner.update() 가 호출될 때 마다, 
// 오차(Bias)를 백그라운드로 누적 수집하고 2-Sigma 통계 필터링으로 튀는 노이즈를 완전 제거한다.
```

**[진행 상태 추적 (`calibrationState`) 및 획득 오프셋(`anchorOffsets`) 세팅 방안]**
startCalibration() 이후 update에 DTM이 주입되면 Calibration이 진행된다.
진행 프로그레스는 `@Published var calibrationState` 로 관찰하여 확인 할 수 있다. 
이를 통해 Anchor Address별 DTM 수신 정보 갯수(`perAnchor`) 및 최종 결과 값(`finalOffsets`)을 제공한다.

```swift
switch positioner.calibrationState {
case .idle:
    print("캘리브레이션 대기 중")
    
case .collecting(let minCount, let perAnchor):
    // [minCount]: 가장 도달 빈도가 낮은 앵커의 누적 횟수. (0~100% Progress Bar UI 게이지 제어 시 유용)
    // [perAnchor]: 앵커 MAC 주소 자원별로 현재 도달한 세부 패킷 카운트 딕셔너리 ([Int: Int])
    print("전체 공통 진행률: \(minCount) / 100")
    for (mac, count) in perAnchor {
        print(" - 앵커(\(String(format: "%04X", mac))) 도달률: \(count)회")
    }
    
case .completed(let finalOffsets):
    print("통계 수집 완료 / 앵커별 캘리브레이션 역산 시간(초): \(finalOffsets)")
    
    // 연산이 완료된 캘리브레이터의 반환값(finalOffsets)을 메인 측위 프로퍼티인 anchorOffsets에 직접 덮어씌운다.
    // ※ 딕셔너리가 주입되면, 이어지는 모든 측위 좌표 계산 시퀀스에서 해당 오차값이 상시 반영되어 보정된다.
    positioner.anchorOffsets = finalOffsets
    
    // (선택) 어플리케이션 구동 시마다 캘리브레이션 절차를 반복 수집하지 않으려면,
    // 해당 finalOffsets 딕셔너리 객체를 로컬(UserDefaults)이나 원격 Backend DB에 영구 저장해두고, 앱 초기화 시점에 Fetch하여 1회만 주입한다.
}

// 캘리브레이션 파이프라인 강제 중단 및 초기화 인터페이스
// positioner.stopCalibration()
```

---

## API 레퍼런스 (API Reference)

라이브러리에서 대외적으로 개방(Public)된 핵심 클래스와 프로퍼티/메서드의 기술 명세서이다.

### 클래스: `DLTDoAPositioner`
엔진의 모든 연산을 주관하는 메인 컨트롤러 객체이다. `@MainActor` 및 `ObservableObject`로 선언되어 있다.

#### 1. 초기화 (Initialization)
* **`init(minRssi: Double = -90.0)`**
  * 엔진 인스턴스를 메모리에 할당한다. 
  * `minRssi`: 연산에 반영할 최소 수신 신호 강도 한계치(Threshold)를 설정한다. 이 한계치보다 약한 신호(dBm)의 패킷은 즉시 필터링 파기된다.

#### 2. 노출 프로퍼티 (Properties)
* **`@Published var estimatedPosition: simd_double3?` (읽기 전용)**
  * 실시간으로 연산이 완료된 태그(스마트폰)의 3D 공간 좌표 정보를 방출한다. (단위: 미터)
  * 패킷 데이터 부족으로 교점이 산출되지 않는 경우 일시적으로 `nil` 상태가 된다.
* **`@Published var calibrationState: CalibrationState` (읽기 전용)**
  * 현재의 오차 보정(Calibration) 데이터 수집 상태 및 진척도를 나타낸다.
* **`var anchorCoordinatesOverride: [Int: simd_double3]`**
  * UWB 앵커의 MAC 주소(Key)에 맵핑되는 물리적 절대 3D 좌표(X, Y, Z) 위치를 강제 오버라이드 주입하는 프로퍼티.
* **`var anchorOffsets: [Int: Double]`**
  * UWB 앵커(MAC 주소)별 하드웨어 안테나 지연 시간(초 단위) 오차값을 교정하기 위한 프로퍼티.  
  완료된 캘리브레이션 딕셔너리 결과를 주입하면, 이후 수행되는 모든 좌표 계산 시 해당 오프셋이 항시 자동 반영되어 정밀 보정된 교점을 산출한다.
* **`var minRssi: Double`**
  * 엔진 구동 중 신호 강도 한계치를 동적으로 변경할 때 사용한다.

#### 3. 핵심 제어 메서드 (Methods)
* **`func update(measurements: [NIDLTDOAMeasurement])`**
  * Apple의 `NISession`으로부터 수신된 원시 형태의 DTM 배열을 엔진 파이프라인에 공급한다. (통신 이벤트 발생 시마다 호출 필수)
* **`func startCalibration(at position: simd_double3, targetCount: Int = 100)`**
  * 특정 좌표(`position`)에 단말기를 두고, 앵커당 지정된 횟수(`targetCount`)만큼 패킷 샘플을 수집하여 앵커별 하드웨어 송신 오차 역산출을 명령한다.
* **`func stopCalibration()`**
  * 진행 중인 수집 절차를 즉시 파기하고 대기 상태(idle)로 롤백(Rollback)한다.

### 데이터 모델: `CalibrationState` (Enum)
캘리브레이션 파이프라인의 생명주기를 관장하는 상태 타입이다.

* **`.idle`**: 초기화 상태 또는 캘리브레이션이 진행 중이 아닌 구간.
* **`.collecting(minCount: Int, perAnchor: [Int: Int])`**: 샘플 수집 절차가 가동 중인 구간.
  * `minCount`: 모든 앵커들 중 가장 패킷 도달 횟수가 적은 지연 앵커의 기준 카운트. (0~100% 프로그레스 바 UI 게이지 목적으로 사용 권장)
  * `perAnchor`: 앵커 MAC 주소별 현재 누적 패킷 측정 샘플 딕셔너리.
* **`.completed([Int: Double])`**: 목표 카운트 수집이 완료되고 내부 2-Sigma 통계 필터링 연산이 종료되어,
최종 도출된 **앵커별 오차 시간(Bias)** 딕셔너리를 반환하는 완료 상태.
