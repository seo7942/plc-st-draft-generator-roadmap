# PLC ST Draft Generator

엑셀/CSV 기반 IO 맵과 사양서 텍스트를 입력으로 받아  
IEC 61131-3 Structured Text(ST) 초안을 생성하는 Python 기반 PLC 코드 생성 실험 프로젝트입니다.

---

## Overview

이 프로젝트는 PLC 제어 로직 초안 작성을 보조하기 위한 개인 개발 프로젝트입니다.

입력 데이터(IO 맵, 사양서 텍스트)를 정규화한 뒤,  
내부 데이터 구조를 기반으로 Structured Text(ST) 초안을 생성하는 흐름을 다룹니다.

주요 목적은 다음과 같습니다.

- 비정형 입력 데이터를 일정한 구조로 정리
- PLC 로직 초안 생성을 위한 데이터 변환 파이프라인 구성
- 검증 가능한 중간 표현과 출력 구조 실험
- 향후 다양한 산업/벤더 환경에 적용 가능한 형태 검토

---

## Scope

현재 공개 저장소 범위는 아래와 같습니다.

- 입력 데이터 로드
- IO 정보 정규화
- 내부 데이터 구조(IR) 구성
- 기본 검증 로직
- 범용 Structured Text(ST) 초안 생성

이 저장소는 **개념 검증 및 구조 설계 중심의 공개용 버전**입니다.

---

## Pipeline

```text
IO Map / Spec Text
        ↓
Input Parsing
        ↓
Normalization
        ↓
Intermediate Representation
        ↓
Validation
        ↓
ST Draft Generation