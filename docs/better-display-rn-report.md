# BetterDisplay RN 오픈소스 3차 보고서

## 1. 목표

BetterDisplay의 핵심 디스플레이 제어 경험을 React Native macOS로 재구현한다.
앱은 Dock/일반 윈도우가 아니라 macOS 메뉴바에만 존재하는 컨트롤러로 동작한다.

## 2. 범위

### 1차: 메뉴바 앱 기반

- 메뉴바 전용 macOS 앱 셸
- React Native macOS 패널 UI
- TurboModule 기반 네이티브 display control 모듈
- 표시 장치 목록, 주 모니터, 내장/외장, HDR 가능 여부 조회

### 2차: 직접 제어

- 소프트웨어 디밍 오버레이
- 외장 모니터 DDC/CI 제어
- 밝기, 대비, 볼륨, 입력 소스 제어
- 해상도/주사율 모드 조회 및 적용

### 3차: 운영 기능

- 디스플레이 배치 origin 이동
- 현재 상태 프리셋 저장/적용/삭제
- 구현 상태와 제한 사항 문서화

## 3. 커밋 계획

1. `feat: add menu bar only app shell`
2. `feat: scaffold display control native module`
3. `feat: build display overview popover UI`
4. `feat: enumerate macOS displays`
5. `feat: add brightness and dimming controls`
6. `feat: add DDC hardware controls`
7. `feat: add display mode controls`
8. `feat: add display arrangement controls`
9. `feat: add display presets`
10. `docs: add BetterDisplay RN phase report`

## 4. 구현 현황

- 메뉴바 전용 앱: 구현 완료
- RN 메뉴 패널: 구현 완료
- 메뉴 설정 UI: 구현 완료, auto refresh 간격과 advanced metadata 표시를 NSUserDefaults 기반 native 설정으로 저장
- 디스플레이 스냅샷: 구현 완료, UUID/vendor/model/serial/product/online/active/asleep/mirror/architecture/machine model/Apple Silicon 여부 포함
- CoreGraphics display reconfiguration 감지: 구현 완료
- IOKit native brightness 조회/설정: 구현 완료
- 소프트웨어 디밍: 구현 완료
- DDC/CI VCP 조회/제어: 구현 완료, 모니터/케이블/어댑터 지원 여부에 의존
- DDC input source preset: VGA/DVI/DP/HDMI/USB-C 구현 완료
- 해상도/주사율 변경과 적용 결과 표시: 구현 완료
- favorite modes 저장/삭제: 구현 완료
- ColorSync color profile 선택/초기화와 적용 결과 표시: 구현 완료
- HDR/XDR headroom probe: 구현 완료
- 디스플레이 배치 origin 변경: 구현 완료
- display rotation request queue: 구현 완료
- layout protection 저장/복구/해제와 drift 감지: 구현 완료
- display sync group 저장/적용/삭제: 구현 완료
- EDID export: 구현 완료
- EDID override request queue: 구현 완료
- HiDPI/custom resolution request queue와 사용자 입력 UI: 구현 완료
- display override bundle plist 생성: 구현 완료
- advanced display operation 결과/시각 기록: 구현 완료
- HDR/XDR upscale entrypoint: 구현 완료
- soft disconnect/reconnect: DDC power mode 기반 요청 구현 완료
- 프리셋 저장/적용/삭제: 구현 완료

## 5. 제한 사항

- macOS 공개 API에서 display rotation 쓰기 API가 확인되지 않아 회전은 요청 큐와 상태 표시로 구현했다. 실제 OS 회전 적용은 별도 저수준/권한 흐름이 필요하다.
- HDR 강제 토글과 XDR preset 직접 변경은 공개 API로 안정 구현하지 않았다. 현재 HDR/EDR headroom과 reference capability를 조회한다.
- native brightness는 IOKit `kIODisplayBrightnessKey`를 노출하는 display에서만 동작한다. 미지원 외장 모니터는 DDC brightness 경로를 사용한다.
- DDC/CI VCP 조회/제어는 외장 모니터, 케이블, 허브, GPU 경로에 따라 실패할 수 있다. 실패 메시지와 live/cache 상태는 메뉴 UI에 노출한다.
- 프리셋/레이아웃 적용은 display ID를 우선 사용하고, ID가 바뀌면 CoreGraphics display UUID를 우선 사용해 현재 연결 display를 매칭한다. 기존 저장값 호환을 위해 vendor/model/serial identity key도 계속 허용한다. UUID가 비어 있고 serial이 0이거나 동일 모델이 중복 연결되면 오인식 가능성이 있다.
- Color profile 변경은 ColorSync에 등록된 프로필 URL 기준으로 적용한다. 시스템 권한/프로필 등록 상태에 따라 적용이 거부될 수 있다.
- sync group scale matching은 기준 display의 현재 mode와 가장 가까운 mode를 대상 display에서 찾는다. 패널별 지원 mode가 다르면 완전 일치하지 않을 수 있다.
- layout drift 감지는 display ID와 CoreGraphics display UUID, legacy vendor/model/serial identity fallback, frame 기준이다. 동일 모델 중복 연결에서는 drift 판단이 제한될 수 있다.
- custom resolution은 요청 큐와 override bundle plist로 저장한다. 시스템 override 디렉터리 설치와 재로그인/재부팅 적용은 별도 권한 흐름이 필요하다.
- EDID override는 export된 EDID를 override 요청으로 큐잉하고 bundle plist에 포함한다. 시스템 override 파일 설치와 재로그인/재부팅 적용은 별도 권한 흐름이 필요하다.
- HDR/XDR upscale은 공개 API 한계 때문에 실제 밝기 강제 증폭이 아니라 지원 여부를 확인한 뒤 entrypoint 상태를 관리한다.
- soft disconnect/reconnect는 공개 macOS disconnect API가 아니라 DDC VCP `0xD6` power mode 요청으로 구현했다. DDC 미지원 모니터에서는 동작하지 않는다.
- display control 구현은 `DisplayCore/RCTDisplayCore`로 분리했다. TurboModule 파일은 RN bridge wrapper 역할만 한다.

## 6. 검증

- `pod install --project-directory=macos`
- `yarn format:check App.tsx specs/NativeDisplayControl.ts`
- `yarn lint`
- `yarn test`
- sample native snapshot 기반 RN popover 주요 제어 렌더를 `__tests__/App.test.tsx`에서 자동 확인
- 메뉴바 전용 bundle/AppDelegate invariant를 `__tests__/MenuBarShell.test.ts`에서 자동 확인
- NativeDisplayControl spec/bridge/DisplayCore/App UI/snapshot field 계약을 `__tests__/NativeDisplayContract.test.ts`에서 자동 확인
- `xcodebuild -workspace macos/com.jingjing2222.macdisplaybar.xcworkspace -scheme com.jingjing2222.macdisplaybar-macOS -configuration Debug -derivedDataPath macos/build/XcodeBuild build`
- 빌드 산출물 `com.jingjing2222.macdisplaybar.app` 실행 확인
- 빌드 산출물 `Info.plist`에서 `LSUIElement=true` 확인
- `System Events`에서 실행 프로세스가 `background only=true`, `visible=false`임을 확인
- 일반 foreground process 목록에 앱 이름이 없음을 확인
- 실행 직후 일반 app window 수가 `0`임을 확인
- display snapshot에 display UUID, vendor ID, model ID, serial number, product name, online/active/asleep/mirror status, machine architecture, machine model, Apple Silicon 여부가 포함됨을 빌드로 확인

## 7. 최신 런타임 검증

- 검증 시각: `2026-05-22 16:58:28 KST`
- 대상 산출물: `macos/build/XcodeBuild/Build/Products/Debug/com.jingjing2222.macdisplaybar.app`
- `Info.plist` `LSUIElement=true`
- `System Events`: `backgroundOnly=true`, `visible=false`, `windows=0`
- foreground process 목록: `foreground-absent`

## 8. 하드웨어 검증 매트릭스

| 항목 | 현재 증거 | 상태 |
| --- | --- | --- |
| Apple Silicon | MacBook Pro `Mac15,6`, Apple M3 Pro, `arm64` | 확인 완료 |
| 내장 디스플레이 | Color LCD, built-in Liquid Retina XDR, 3024 x 1964 Retina, main/online | 확인 완료 |
| 외장 HDMI/USB-C | 현재 `system_profiler SPDisplaysDataType`에 외장 display 없음 | 별도 장비 필요 |
| DDC 지원 모니터 | 현재 외장 DDC 대상 없음 | 별도 장비 필요 |
| DDC 미지원 모니터 | 현재 외장 미지원 대상 없음 | 별도 장비 필요 |
| Intel Mac | 현재 장비가 Apple Silicon | 별도 장비 필요 |
