# PLC ST Draft Generator

자연어 기반 사양(spec)과 IO 맵을 입력으로 받아  
IEC 61131-3 Structured Text(ST) 제어 로직을 생성하는  
PLC 설계 자동화 엔진 포트폴리오 프로젝트입니다.

---

## 프로젝트 개요

본 프로젝트는 PLC 제어 로직을 사람이 직접 작성하는 방식에서 벗어나,  
**자연어 기반 입력을 구조화하여 ST 코드로 변환하는 설계 자동화 엔진**을 구현하는 것을 목표로 합니다.

단순 코드 생성기가 아니라,  
설계 과정을 다음과 같은 단계로 분리하고 자동화한 구조를 가지고 있습니다.

- 자연어 사양(spec) 해석
- IO 데이터 정규화
- 중간 표현(IR) 기반 설계 구조 생성
- 상태(State) / 전이(Transition) 기반 로직 구성
- 인터락 / 타이머 / 알람 모델링
- Structured Text(ST) 코드 생성

---

## 핵심 개념

본 프로젝트의 핵심은 다음 3가지입니다.

### 1. 자연어 기반 설계 입력

- 사용자는 설비 요구사항을 자연어로 작성
- 시스템이 이를 구조화 가능한 형태로 변환

### 2. Intermediate Representation (IR)

- IO, 상태, 전이, 인터락, 타이머를 포함한 중간 설계 구조
- PLC 코드 생성 이전 단계에서 로직을 명확하게 분리
- 설계 → 코드 변환 과정의 재현성 확보

### 3. 설계 → 코드 자동 변환

- IR을 기반으로 Structured Text(ST) 코드 생성
- 반복적인 설계 및 코드 작성 과정 자동화

---

## 전체 구조 (Pipeline)

Spec (자연어 사양) / IO Map  
↓  
Input Parsing  
↓  
Normalization  
↓  
Intermediate Representation (IR)  
↓  
Validation  
↓  
ST Code Generation  

---

## 입력 방식

본 프로젝트는 다음 두 가지 입력을 사용합니다.

### 1. 자연어 사양 (필수)

- 설비 동작 요구사항
- 상태 흐름 및 제어 조건

예:
- "start 버튼 입력 시 모터 구동"
- "jam 발생 시 fault 상태 전환"

### 2. IO 맵 (선택)

- 엑셀/CSV 기반 신호 정의
- 주소 매핑 및 신호 구조 보강

---

## 성능 (실무 기준)

- 기존 PLC ST 설계: 수시간 ~ 반나절
- 본 구조 적용 시: 평균 1~2시간 내 초안 생성 가능

※ 설비 복잡도 및 요구사항에 따라 차이 발생

---

## 지원 가능 도메인 (총 60개)

다양한 산업 설비 기준으로 테스트 가능한 도메인 구성

---

### SIMPLE (단일 장비 / 기본 제어)

- Conveyor (기본)
- Motor on/off 제어
- Pump 자동/수동
- Water tank 레벨 제어
- Fan 제어
- Heater on/off
- Mixer (타이머 기반)
- 조명 제어
- Valve 개폐
- Lift up/down
- Compressor
- 단일 배출 컨베이어
- Drum 회전
- Filter pump
- Cooling fan
- Air blower
- Cylinder extend/retract
- Door open/close
- Alarm 트리거 시스템
- Start 지연 타이머

---

### NORMAL (인터락 / 상태 확장)

- Conveyor + jam detection
- Water tank 자동 충전
- Pump 2대 교번 운전
- Mixing 공정 (투입/혼합/배출)
- Boiler 제어 (기본 로직)
- 포장기 제어
- Lift 다단 위치 제어
- 냉각 순환 시스템
- Air compressor 압력 제어
- 세척 공정
- Filter 역세척
- 자동 게이트
- Batch tank 충전
- 단일 장비 사이클 제어
- 안전 도어 인터락
- Dryer 공정
- 냉장/냉동 제어
- 압력 릴리프 시스템
- Conveyor 분기 제어
- Alarm + Reset + Latch 구조

---

### COMPLEX (라인 / 공정 제어)

- Multi conveyor line
- 생산 라인 시퀀스 제어
- Tank + Pump + Valve 통합 제어
- Mixing + Heating + Discharge
- 포장 라인 제어
- Multi pump priority 시스템
- HVAC 시스템
- 압축 공정 라인
- 세척 + 건조 통합 시스템
- Multi-level lift
- 자동 창고 입출고 (기초)
- Sorting conveyor 시스템
- 충전 라인
- 병입 공정 (Fill + Cap)
- 열처리 공정
- 검사 + Reject 시스템
- 냉각수 순환 (multi loop)
- 다중 탱크 동기화
- Batch 공정 제어
- Safety interlock 중심 시스템

---

## 기술 구성

- CSV / JSON 기반 IO 데이터 파싱
- 자동 IO 정규화 처리
- ProjectIR 기반 데이터 구조 설계
- 상태(State) / 전이(Transition) 모델링
- Timer / Interlock / Alarm 구조 정의
- 코드 생성 파이프라인 구현

---

## 제한 사항

다음 영역은 현재 범위에 포함되지 않습니다.

- PID 제어 (정밀 제어)
- 로봇 경로 제어
- 비전 시스템
- 고정밀 동기 제어

---

## 프로젝트 목적

- PLC 설계 자동화 구조 구현
- 자연어 기반 설계 → 코드 변환 흐름 검증
- 재사용 가능한 설계 구조(IR) 실험
- 실무 적용 가능성 검토 및 포트폴리오 활용

---

## 참고

본 프로젝트는 실무 투입용 완제품이 아닌,  
PLC 설계 자동화 구조를 검증하기 위한 포트폴리오 프로젝트입니다.