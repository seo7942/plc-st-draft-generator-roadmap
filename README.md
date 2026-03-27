# PLC ST Draft Generator Roadmap

엑셀 IO 맵과 사양서 텍스트를 입력으로 받아  
IEC 61131-3 Structured Text(ST) 초안을 자동 생성하는 범용 엔진의 로드맵 및 아키텍처 설계 문서입니다. :contentReference[oaicite:1]{index=1}

---

## 한 줄 소개

**IO 맵 + 사양서 → IR → Rule Engine → ST Generator** 흐름으로 PLC Structured Text 초안을 생성하기 위한 범용 엔진 설계 프로젝트입니다. :contentReference[oaicite:2]{index=2}

---

## 프로젝트 목적

이 프로젝트의 목표는 PLC 엔지니어가 반복적으로 작성하는  
상태 전이, 인터락, 타이머, 알람, 안전 규칙 코드를 자동 생성 가능한 구조로 바꾸는 것입니다.

단순 템플릿 치환이 아니라,  
입력 데이터를 내부 중간 표현(IR)으로 바꾼 뒤 Rule Engine을 통해 ST 코드 초안을 생성하는 구조를 목표로 설계했습니다. :contentReference[oaicite:3]{index=3}

---

## 설계 대상

입력:
- 엑셀/CSV 형태의 IO 맵
- 설비 사양서 텍스트

출력:
- IEC 61131-3 Structured Text(ST) 초안
- 검증용 중간 결과(JSON/IR)
- 테스트/검증 시나리오

적용 대상:
- GX Works3
- TIA Portal
- Codesys
- TwinCAT 등 벤더 확장 가능 구조 지향 :contentReference[oaicite:4]{index=4}

---

## 전체 아키텍처

```text
IO Map / Spec Text
        ↓
Input Ingestion
        ↓
Intermediate Representation (IR)
        ↓
Rule Engine
        ↓
ST Draft Generator
        ↓
Validator / Exporter
        ↓
Vendor-specific adaptation