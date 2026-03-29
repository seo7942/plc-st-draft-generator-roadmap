(*
==============================================================================
PROJECT  : 솔레노이드 밸브 표준 제어 시스템 (Solenoid_Valve_v1.0)
INDUSTRY : Fluid/Gas Control (유체 및 가스 제어)
AUTHOR   : 서종완 (Seo Jong-wan)
VERSION  : 1.0.0
NOTE     : 자동/수동 전환, 압력 인터락 및 비상 정지 로직 포함 (IEC 61131-3 준수)
==============================================================================
*)

VAR
    (* 입출력 신호 정의 (IO Signals) *)
    open_cmd        : BOOL;    (* 자동 모드: 열림 명령 *)
    close_cmd       : BOOL;    (* 자동 모드: 닫힘 명령 *)
    manual_open     : BOOL;    (* 수동 모드: 강제 열림 버튼 *)
    manual_close    : BOOL;    (* 수동 모드: 강제 닫힘 버튼 *)
    estop           : BOOL;    (* 비상정지 신호 (A접점) *)
    pressure_high   : BOOL;    (* 고압 감지 센서 (Interlock) *)
    reset_pb        : BOOL;    (* 알람/상태 리셋 버튼 *)
    
    valve_output    : BOOL;    (* 실제 솔레노이드 밸브 출력 (Y) *)
    alarm_pressure  : BOOL;    (* 압력 이상 알람 출력 *)
    
    valve_is_open   : BOOL;    (* 밸브 열림 상태 모니터링 (M) *)
    valve_is_closed : BOOL;    (* 밸브 닫힘 상태 모니터링 (M) *)

    (* 상태 제어 변수 (State Machine) *)
    state_current   : INT := 0; (* 현재 밸브 상태 *)
    state_next      : INT := 0; (* 다음 전이 상태 *)
    state_init_done : BOOL := FALSE;
    
    STATE_CLOSED    : INT := 0;  (* 밸브 닫힘 상태 *)
    STATE_OPEN      : INT := 10; (* 밸브 열림 상태 *)
    STATE_FAULT     : INT := 90; (* 이상 발생(비상정지/고압) 상태 *)

    (* 인터락 및 안전 플래그 *)
    ilock_estop_interlock    : BOOL := FALSE; (* 비상정지 인터락 *)
    ilock_pressure_interlock : BOOL := FALSE; (* 고압 안전 인터락 *)

    (* 알람 로직 변수 *)
    alarm_latched            : BOOL := FALSE; (* 알람 유지 플래그 *)

    (* 실행 허용 플래그 *)
    run_permissive_core : BOOL := TRUE;
    transition_taken_core : BOOL := FALSE;
END_VAR

(* =========================================== *)
(* 프로그램 바디 (Program Body)                *)
(* =========================================== *)

(* 시스템 초기화 *)
IF NOT state_init_done THEN
    state_current := STATE_CLOSED;
    state_init_done := TRUE;
END_IF;

(* 1. 인터락 및 안전 조건 연산 *)
ilock_estop_interlock := (estop);        (* 비상정지 시 TRUE *)
ilock_pressure_interlock := (pressure_high); (* 고압 시 TRUE *)

(* 2. 실행 허용 조건 (안전해야만 동작 가능) *)
run_permissive_core := (NOT ilock_estop_interlock) AND (NOT ilock_pressure_interlock);

(* 3. 알람 래치 로직 *)
IF pressure_high THEN
    alarm_latched := TRUE;
END_IF;

IF reset_pb AND (NOT pressure_high) THEN
    alarm_latched := FALSE;
END_IF;

(* 4. 상태 머신 (State Machine) *)
transition_taken_core := FALSE;
state_next := state_current;

CASE state_current OF
    STATE_CLOSED:
        (* 열림 조건: 명령 발생 + 안전 확보 *)
        IF (open_cmd OR manual_open) AND run_permissive_core AND (NOT transition_taken_core) THEN
            state_next := STATE_OPEN;
            transition_taken_core := TRUE;
        END_IF;

    STATE_OPEN:
        (* 닫힘 조건: 닫힘 명령 혹은 수동 닫힘 *)
        IF (close_cmd OR manual_close) AND (NOT transition_taken_core) THEN
            state_next := STATE_CLOSED;
            transition_taken_core := TRUE;
        (* 안전 위반 시 즉시 에러 상태로 전이 *)
        ELSIF (NOT run_permissive_core) AND (NOT transition_taken_core) THEN
            state_next := STATE_FAULT;
            transition_taken_core := TRUE;
        END_IF;

    STATE_FAULT:
        (* 이상 상태 복귀: 안전 확보 및 리셋 *)
        IF run_permissive_core AND (NOT alarm_latched) AND (NOT transition_taken_core) THEN
            state_next := STATE_CLOSED;
            transition_taken_core := TRUE;
        END_IF;
ELSE
    state_next := STATE_CLOSED;
END_CASE;

state_current := state_next;

(* =========================================== *)
(* 5. 최종 출력 할당 (Output Mapping)          *)
(* =========================================== *)

(* 밸브 출력: 열림 상태이고 안전할 때만 전원 인가 *)
valve_output := (state_current = STATE_OPEN) AND run_permissive_core;

(* 알람 출력 *)
alarm_pressure := alarm_latched;

(* 상태 피드백 *)
valve_is_open := (state_current = STATE_OPEN);
valve_is_closed := (state_current = STATE_CLOSED);