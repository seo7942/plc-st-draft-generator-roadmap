# 비정형 수주서 기반 PLC 설계 검토 패키지 자동 생성 샘플

## 1. 프로젝트 개요

이 저장소는 비정형 수주서 메모를 입력으로 받아, PLC 설계 검토에 필요한 1차 산출물을 자동 구성한 포트폴리오 샘플입니다.

본 샘플은 폐수처리 설비를 대상으로 한 IO200급 공개용 검토 패키지이며, 실제 현장 투입용 확정본이 아니라 선임 엔지니어 검토를 위한 **REVIEW ONLY** 자료입니다.

생성 대상은 **LS XGT / XG5000 기준의 검토용 자료**입니다.

---

## 2. 입력 예시

입력은 상세 설계서가 아니라, 현장에서 받을 수 있는 간단 메모형 수주서입니다.

```text
2공장 세척라인 폐수 집수조 자동제어를 구성하려고 합니다.
집수조는 2개이고, 1번 집수조에는 배수펌프 3대,
2번 집수조에는 이송펌프 2대가 있습니다.

각 펌프는 교번운전이 필요하고,
수위에 따라 1대/2대/3대 단계 운전이 되었으면 합니다.
펌프 한 대 고장 시 나머지 펌프가 자동으로 대체 운전되면 좋겠습니다.

Low, Mid, High, High-High 수위센서와
아날로그 수위계를 HMI에 표시하고 싶습니다.

펌프 운전 상태, 고장, 과부하, MCC 차단기 상태,
밸브 열림/닫힘 피드백, 누수감지, 경광등/부저,
복전 후 재기동 확인, Maintenance Mode도 필요합니다.

LS XGT / XG5000 기준으로
IO List, HMI 태그, 알람표, 인터락표, ST/Ladder 초안,
도면 후보, XG5000 Import CSV까지 정리되면 좋겠습니다.
```

---

## 3. 생성 결과 요약

| 항목 | 내용 |
|---|---|
| Case ID | PLC-20260512-WASTEWATER-IO200-001 |
| 설비 유형 | 폐수처리 집수조 자동제어 |
| 입력 유형 | 간단 메모형 비정형 수주서 |
| IO 규모 | 약 200점 |
| 벤더 기준 | LS XGT / XG5000 |
| 결과물 성격 | 설계 검토용 초안 |
| 사용 목적 | 선임 엔지니어 검토 보조 |
| 현장 투입 여부 | confirmed_for_plc_run=false |
| 검토 필요 여부 | review_required=true |

---

## 4. 산출물 구성

```text
README.md
sample_order.txt

01_summary/
  package_summary.json

02_io_hmi/
  io_list.csv
  hmi_tag_table_sample.csv
  hmi_alarm_table_sample.csv

03_logic_review/
  st_draft_sample.txt
  ladder_draft_sample.md
  ladder_draft_visual.pdf
  ladder_visual_qa_report.json
  checklist.md
  risk_flags.md

04_electrical_review/
  terminal_list_sample.csv
  cable_list_sample.csv
  bom_sample.csv
  rule_check_report_sample.csv

05_drawings/
  P04_DO_001_020_sample.pdf
  P99_SAFETY_CIRCUIT_WIRING_CANDIDATE.svg
  drawing_qa_report_sample.json

05_xg5000_import_ready/
  xg5000_variable_description_import_sample.csv
  xg5000_import_ready_final_verdict.md
  xg5000_import_ready_manifest.json
  xg5000_import_checklist.md

07_screenshots/
  xg5000_import_success_001.png
  xg5000_import_success_002.png
```

---

## 5. 주요 기능

### 5.1 IO 목록 생성

비정형 수주서 내용을 기반으로 IO 후보를 구성합니다.

포함 항목:

- 입력 신호
- 출력 신호
- 안전 관련 신호
- HMI 표시 후보
- Spare IO
- 설명문
- XG5000 반입용 변수 설명 CSV

---

### 5.2 XG5000 Import 후보 파일 생성

XG5000에서 변수 설명 Import를 시도할 수 있는 CSV 후보 파일을 생성합니다.

포함 항목:

- 변수명
- 타입
- 디바이스 주소
- 사용 여부
- HMI 표시 여부
- 설명문

본 샘플은 실제 `.xgw` 또는 `.xgp` 프로젝트 파일을 생성하지 않습니다.
XG5000 테스트 프로젝트에서 Import, Build, Compile 검토를 수행하기 전 단계의 후보 파일세트입니다.

---

### 5.3 ST Draft 생성

ST 초안에는 다음 흐름이 포함됩니다.

- Master Safety 조건
- Auto / Manual Mode Gate
- Maintenance Mode Gate
- Fault Latch SET / RESET
- 펌프 교번운전 후보
- 수위 단계별 펌프 투입 후보
- 누수 감지 시 구역별 정지 후보
- 복전 후 HMI 재기동 확인 조건
- 타임아웃 기반 Fault 전이

예시 구조:

```pascal
SAFETY_OK :=
  ESTOP_OK
  AND MCC_MAIN_POWER_OK
  AND UPS_POWER_OK
  AND NOT LEAK_DETECTED_ANY
  AND NOT OVERLOAD_ANY;

IF POWER_RECOVERY_DETECTED THEN
    RESUME_REQUIRED := TRUE;
END_IF;

IF HMI_RESUME_CONFIRM_PB AND ALARM_RESET_PB THEN
    RESUME_REQUIRED := FALSE;
END_IF;
```

---

### 5.4 Ladder Draft 생성

Ladder Draft는 사람이 읽을 수 있는 네트워크 단위 검토 문서로 생성됩니다.

예시:

```text
N001 - Master Safety Permit
ESTOP_OK AND MCC_MAIN_POWER_OK AND UPS_POWER_OK -> SAFETY_OK

N002 - Power Recovery Hold
POWER_RECOVERY_DETECTED -> SET RESUME_REQUIRED
HMI_RESUME_CONFIRM_PB AND ALARM_RESET_PB -> RESET RESUME_REQUIRED

N007 - T1 Stage Demand
MID=1 pump, HIGH=2 pumps, HIGH_HIGH=3 pumps candidate

N019 - Pump Start Fail Timer
RUN_CMD AND NOT RUN_FB -> T_PUMP_START_FAIL -> alarm
```

---

### 5.5 Ladder Visual PDF 생성

Ladder Draft를 PDF 형태로 시각화하여, XG5000 반입 전 로직 흐름을 사전 검토할 수 있도록 구성했습니다.

포함 내용:

- Master Safety Permit
- Power Recovery Hold
- Auto / Manual Mode Interlock
- Maintenance Mode
- Pump Availability
- Pump Alternation Counter
- Pump Run Command
- Dry Run Protection
- Leak Stop Zone
- Pump Start Fail Timer
- No Flow Timer
- Valve Open / Close Fail Timer
- Tower Lamp / Buzzer
- Alarm Reset / Acknowledge
- HMI Manual Output Gate
- Runtime Counter
- Communication Alarm
- Level Transmitter Fault
- Emergency Drain Review Flag
- Spare IO Isolation

---

### 5.6 전장 도면 후보 생성

IO 목록을 기반으로 검토용 전장 도면 후보 PDF/SVG를 생성합니다.

포함 예시:

- DI/DO 주소 후보
- 펌프 운전 명령
- 밸브 열림/닫힘 명령
- 경광등/부저 출력
- DO COM 그룹
- PLC Panel 후보
- Spare 미결선 표시
- REVIEW ONLY 표시

---

### 5.7 QA 리포트 생성

도면과 Ladder 시각화 결과에 대해 QA 리포트를 생성합니다.

검토 항목 예시:

- IO 개수 정합성
- 페이지별 장치 수 제한
- 연결 수 검토
- DO COM 그룹 표시
- Spare 미결선 표시
- REVIEW ONLY 표시
- Ladder Network 수
- 출력 Coil 수
- 긴 라벨 줄바꿈 처리
- Negative Contact 표시

---

## 6. 안전 및 검수 원칙

이 저장소의 모든 산출물은 실제 설비 RUN 또는 다운로드 확정본이 아닙니다.

반드시 다음 절차가 필요합니다.

1. 현장 IO 실사
2. 실제 PLC 모듈 및 슬롯 확인
3. XG5000 Import 테스트
4. Build / Compile 수행
5. 오프라인 시뮬레이션
6. 선임 엔지니어 검토
7. 전기/안전 담당자 검토
8. 현장 시운전 전 최종 승인

---

## 7. 주요 Risk Flag

| 코드 | 등급 | 내용 |
|---|---|---|
| RF-001 | critical | 실제 펌프/밸브/센서 수량은 현장 실사 필요 |
| RF-002 | critical | 안전회로는 후보이며 실제 안전 릴레이/배선 확정 아님 |
| RF-003 | high | Spare IO가 실제 동작 로직에 잘못 연결될 위험 |
| RF-004 | high | 아날로그 수위계 스케일링 및 상하한 기준 미확정 |
| RF-005 | high | 저수위 공회전 방지와 초고수위 비상배수 조건 충돌 가능성 검토 필요 |
| RF-006 | medium | X/Y/M/D 주소는 실제 카드 구성에 따라 변경 필요 |
| RF-007 | medium | 복전 후 자동 재기동 금지 조건은 현장 운전 정책 확인 필요 |

---

## 8. 본 저장소에 포함하지 않는 것

본 저장소에는 아래 항목을 포함하지 않습니다.

- 원본 PLC Package JSON 전체
- 도메인맵 원본
- 스키마 원본
- 생성기 원본 코드
- 랩핑기 원본 코드
- 어댑터 원본 코드
- 내부 평가 로직
- 전체 ZIP 원본
- 백업 폴더
- Turn별 내부 개발 리포트

이 저장소는 엔진 원본 공개가 아니라, 엔진이 생성한 검토용 산출물 샘플을 보여주기 위한 포트폴리오입니다.

---

## 9. 포트폴리오 설명 문장

비정형 간단 메모형 수주서를 기준으로 폐수처리 집수조 자동제어 IO200급 PLC 설계 검토 패키지를 구성했습니다. 산출물은 IO List, HMI Tag/Alarm Table, XG5000 변수 설명 Import CSV, ST/Ladder 초안, Ladder 시각화 PDF, 인터락·알람 검토표, 전장 도면 후보, Drawing QA 리포트, 체크리스트와 리스크 플래그로 구성했으며, 모든 결과물은 실제 RUN 확정본이 아닌 선임 엔지니어 검토용 REVIEW ONLY 자료로 정리했습니다.

---

## 10. 사용 목적

이 프로젝트는 다음 역량을 보여주기 위한 포트폴리오입니다.

- 비정형 수주서 해석
- PLC 설계 자료 구조화
- IO/HMI/알람/인터락 정리
- XG5000 Import 후보 파일 생성
- ST/Ladder 초안 생성
- Ladder 시각화
- 전장 도면 후보 생성
- QA 리포트 구성
- REVIEW ONLY 기준의 안전한 검토 패키지 구성

---

## 11. 주의

본 샘플은 학습 및 포트폴리오 목적의 검토용 자료입니다.
실제 설비에 적용하기 위해서는 반드시 현장 엔지니어, 전기 담당자, 안전 담당자의 검토와 XG5000 Build/Compile, 오프라인 테스트, 현장 시운전 절차가 필요합니다.
