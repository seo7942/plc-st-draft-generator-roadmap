(*
==============================================================================
PROJECT  : 히터 온도 제어 표준 시스템 (Heater_Control_System_v1.0)
INDUSTRY : Thermal Process (열처리 공정 제어)
AUTHOR   : 서종완 (Seo Jong-wan)
VERSION  : 1.0.0
NOTE     : IEC 61131-3 표준 준수, 안전 인터락 및 알람 래치 로직 포함
==============================================================================
*)

VAR
    (* 입출력 신호 정의 (IO Signals) *)
    current_temp    : REAL;    (* 현재 온도 입력 (PV) *)
    setpoint        : REAL;    (* 설정 온도 (SV) *)
    manual_run      : BOOL;    (* 수동 운전 명령 *)
    estop           : BOOL;    (* 비상정지 신호 (A접점) *)
    reset_pb        : BOOL;    (* 알람 리셋 버튼 *)
    heater_run      : BOOL;    (* 히터 마그네트 제어 출력 *)
    alarm           : BOOL;    (* 과온 발생 알람 출력 *)
    over_temp       : BOOL;    (* 과온 감지 내부 플래그 *)
    heater_running  : BOOL;    (* 시스템 운전 상태 모니터링 *)

    (* 상태 제어 변수 (State Machine) *)
    state_current   : INT := 0; (* 현재 운전 상태 코드 *)
    state_next      : INT := 0; (* 다음 전이 상태 코드 *)
    state_init_done : BOOL := FALSE;
    
    STATE_OFF       : INT := 0;  (* 히터 정지 상태 *)
    STATE_HEATING   : INT := 10; (* 히터 가열 상태 *)
    STATE_FAULT     : INT := 90; (* 장치 이상(과온/비상정지) 상태 *)

    (* 인터락 및 안전 플래그 *)
    ilock_estop_interlock    : BOOL := FALSE; (* 비상정지 인터락 *)
    ilock_overtemp_interlock : BOOL := FALSE; (* 과온 방지 인터락 *)

    (* 알람 로직 변수 *)
    alarm_overtemp_active    : BOOL := FALSE; (* 과온 실시간 감지 *)
    alarm_overtemp_latched   : BOOL := FALSE; (* 과온 알람 유지(Latch) *)

    (* 실행 허용 플래그 *)
    run_permissive_core : BOOL := TRUE;
    transition_taken_core : BOOL := FALSE;
END_VAR

(* =========================================== *)
(* 프로그램 바디 (Program Body)                *)
(* =========================================== *)

(* 시스템 초기화 *)
IF NOT state_init_done THEN
    state_current := STATE_OFF;
    state_init_done := TRUE;
END_IF;

(* 1. 인터락 논리 연산 *)
ilock_estop_interlock := (estop);
ilock_overtemp_interlock := (current_temp > setpoint + 10.0) OR over_temp;

(* 2. 실행 허용 조건 결정 *)
run_permissive_core := (NOT ilock_estop_interlock) AND (NOT ilock_overtemp_interlock);

(* 3. 알람 래치(Latch) 로직 *)
alarm_overtemp_active := (current_temp > setpoint + 5.0);
IF alarm_overtemp_active THEN
    alarm_overtemp_latched := TRUE;
END_IF;

(* 알람 리셋 처리 *)
IF reset_pb AND (NOT alarm_overtemp_active) THEN
    alarm_overtemp_latched := FALSE;
END_IF;

(* 4. 상태 머신 (State Machine) *)
transition_taken_core := FALSE;
state_next := state_current;

CASE state_current OF
    STATE_OFF:
        IF (current_temp < setpoint) AND run_permissive_core AND (NOT transition_taken_core) THEN
            state_next := STATE_HEATING;
            transition_taken_core := TRUE;
        END_IF;

    STATE_HEATING:
        IF (NOT run_permissive_core) AND (NOT transition_taken_core) THEN
            state_next := STATE_FAULT;
            transition_taken_core := TRUE;
        ELSIF (current_temp >= setpoint) AND (NOT transition_taken_core) THEN
            state_next := STATE_OFF;
            transition_taken_core := TRUE;
        END_IF;

    STATE_FAULT:
        IF run_permissive_core AND (NOT alarm_overtemp_latched) AND (NOT transition_taken_core) THEN
            state_next := STATE_OFF;
            transition_taken_core := TRUE;
        END_IF;
ELSE
    state_next := STATE_OFF;
END_CASE;

state_current := state_next;

(* 5. 최종 출력 할당 (Output Mapping) *)
heater_run := (state_current = STATE_HEATING) AND run_permissive_core;

IF manual_run AND run_permissive_core THEN
    heater_run := TRUE;
END_IF;

alarm := alarm_overtemp_latched;
heater_running := (state_current = STATE_HEATING);