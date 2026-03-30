# PLC ST 설계 자동화 — 샘플 포트폴리오

> \*\*스펙 문서 + IO 주소표 → IEC 61131-3 ST 코드\*\*  
> 당일 초안 납품 가능합니다.

\---

## 이 저장소는 무엇인가

본 저장소는 **자체 개발한 PLC ST 자동 생성 엔진의 출력 샘플**을 공개하는 포트폴리오입니다.

엔진 본체(생성 파이프라인, IR 구조, 레시피 시스템)는 비공개 자산입니다.  
샘플 코드는 실제 엔진이 생성한 결과물입니다.

\---

## 생성 파이프라인 구조

```
자연어 사양 (spec.txt)
+ IO 주소표 (address.txt)
        ↓
   \[ 비공개 엔진 ]
        ↓
   IO 정규화 + IR 생성
        ↓
   상태머신 / 인터락 / 알람 / 타이머 구조 자동 구성
        ↓
   Validation (검증 실패 시 생성 차단)
        ↓
ST 코드 생성 + 미쓰비시 주소 변환
        ↓
   final\_output.st
```

\---

## 샘플 출력물

|파일|도메인|복잡도|주요 구현 내용|
|-|-|-|-|
|`Solenoid\_Valve.st`|유체 제어|SIMPLE|자동/수동 전환, 압력 인터락, 알람 래치|
|`heater\_control.st`|열처리 공정|SIMPLE|아날로그 온도 제어, 과온 인터락, Fail-Safe|
|`Multi\_Conveyor.st`|반송 설비|NORMAL|3대 동기 연동, Jam 타임아웃 래치, N.C 정지|
|`Press\_Machine.st`|프레스 기계|COMPLEX|양수버튼 안전, 6상태 머신, 하강/상승 타임아웃|
|`Heating\_Mixing\_Batch\_System.st`|식품/화학 공정|COMPLEX|3단 배치 시퀀스, 모드 전환 블랭킹, 분리 알람|

\---

## 자동 반영되는 안전 설계 항목

모든 출력물에 아래 항목이 자동 구성됩니다.

* **Fail-Safe 출력 구조** — 기본값 차단 후 조건 만족 시에만 출력 활성화
* **알람 래치 (Latch)** — 이상 발생 시 유지, reset 조건 만족 시에만 해제
* **상태 머신 기반 설계** — IDLE / RUN / FAULT 등 명시적 상태 전이
* **인터락 조건 분리** — estop, pressure, timeout 등 원인별 fault 분리
* **AUTO / MANUAL 상호 배타** — 동시 활성 방지 및 전환 순간 출력 차단

\---

## 지원 도메인 (60개)

### SIMPLE — 단일 장비 기본 제어

Conveyor, Motor, Pump, Water Tank, Fan, Heater, Mixer, Valve, Lift, Compressor, Cylinder, Door, Alarm, Drum, Filter, Blower 외

### NORMAL — 인터락 / 상태 확장

Conveyor + Jam Detection, Pump 교번 운전, Mixing 공정, Boiler, 포장기, 냉각 순환, 세척 공정, Batch Tank, Dryer, Alarm + Reset + Latch 외

### COMPLEX — 라인 / 공정 제어

Multi Conveyor Line, 생산 라인 시퀀스, Tank+Pump+Valve 통합, Mixing+Heating+Discharge, 포장 라인, HVAC, 열처리 공정, Sorting Conveyor, 병입 공정, Safety Interlock 중심 시스템 외

\---

## 납품 방식

|항목|내용|
|-|-|
|입력|자연어 사양서 + IO 주소표|
|출력|ST 초안 + 미쓰비시 주소 변환본 + 주석 완료본|
|납기|도메인 난이도에 따라 당일 \~ 익일|
|대상|PLC 업체, 설비 제작사, 자동화 설계 외주|

\---

## 문의

스펙 일부를 주시면 샘플 ST를 무상으로 생성해드립니다.  
결과물로 판단해 주십시오.

📧 **deeodo@naver.com**

\---

> ※ `.st` 확장자는 IEC 61131-3 Structured Text 파일입니다. Smalltalk과 무관합니다.  
> ※ 생성 엔진 및 파이프라인 코드는 비공개 자산입니다.

