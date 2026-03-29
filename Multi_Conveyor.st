(*
==============================================================================
PROJECT  : 멀티 컨베이어 자동 제어 시스템 (Multi_Conveyor_System_v1.3)
SPEC     : spec.txt 및 현장 안전 규격 반영
AUTHOR   : 서종완 (Seo Jong-wan)
VERSION  : 1.3.0 (Revised Final)
NOTE     : 수동 개별 제어, 3단 동기 연동, Jam/Timeout 래치 및 안전 인터락 포함
==============================================================================
*)

VAR
    (* --- [물리 I/O 셋팅] --- *)
    auto_mode         : BOOL;    (* 자동 모드 선택 *)
    manual_mode       : BOOL;    (* 수동 모드 선택 *)
    start_pb          : BOOL;    (* 자동 시작 버튼 *)
    stop_pb           : BOOL;    (* 정지 버튼 (N.C: 정상 시 TRUE, 누름/단선 시 FALSE) *)
    reset_pb          : BOOL;    (* 에러 리셋 버튼 *)
    estop             : BOOL;    (* 비상정지 (B접점: 정상 시 TRUE, 작동 시 FALSE) *)

    jam_sensor        : BOOL;    (* 적체 감지 센서 *)
    product_sensor_1  : BOOL;    (* 1-2번 사이 센서 *)
    product_sensor_2  : BOOL;    (* 2-3번 사이 센서 *)

    (* 수동 모드 전용 버튼 *)
    m_conveyor_1_pb   : BOOL;
    m_conveyor_2_pb   : BOOL;
    m_conveyor_3_pb   : BOOL;

    (* 출력 신호 *)
    conveyor_1_run    : BOOL;
    conveyor_2_run    : BOOL;
    conveyor_3_run    : BOOL;
    alarm_lamp        : BOOL;

    (* --- [내부 제어 로직] --- *)
    safety_ok         : BOOL;
    fault_present     : BOOL;

    jam_latched       : BOOL := FALSE;
    timeout_1_latched : BOOL := FALSE;
    timeout_2_latched : BOOL := FALSE;
    estop_latched     : BOOL := FALSE;

    stop_cmd          : BOOL;
    mode_valid        : BOOL;

    (* 타이머 *)
    t_jam_detect      : TON;
    t_sensor_1_timeout: TON;
    t_sensor_2_timeout: TON;

    (* 상태 머신 *)
    state_current     : INT := 0;
    STATE_IDLE        : INT := 0;
    STATE_AUTO_RUN    : INT := 10;
    STATE_FAULT       : INT := 90;
END_VAR


(* ========================================================================== *)
(* 1. 기본 명령 / 모드 유효성                                                 *)
(* ========================================================================== *)

(* N.C 정지 버튼: 정상=TRUE, 누름/이상=FALSE *)
stop_cmd := NOT stop_pb;

(* AUTO / MANUAL 상호배타 *)
mode_valid := (auto_mode AND NOT manual_mode) OR (manual_mode AND NOT auto_mode);


(* ========================================================================== *)
(* 2. 안전 및 Fault Latch                                                     *)
(* ========================================================================== *)

(* AUTO 운전 중 3초 이상 Jam 센서 유지 시 Jam 확정 *)
t_jam_detect(IN := (state_current = STATE_AUTO_RUN) AND jam_sensor, PT := T#3s);
IF t_jam_detect.Q THEN
    jam_latched := TRUE;
END_IF;

(* AUTO 운전 중 각 구간 센서 미검출 타임아웃 *)
t_sensor_1_timeout(IN := (state_current = STATE_AUTO_RUN) AND conveyor_1_run AND (NOT product_sensor_1), PT := T#10s);
t_sensor_2_timeout(IN := (state_current = STATE_AUTO_RUN) AND conveyor_2_run AND (NOT product_sensor_2), PT := T#10s);

IF t_sensor_1_timeout.Q THEN
    timeout_1_latched := TRUE;
END_IF;

IF t_sensor_2_timeout.Q THEN
    timeout_2_latched := TRUE;
END_IF;

(* E-STOP 발생 기억 *)
IF NOT estop THEN
    estop_latched := TRUE;
END_IF;

(* Fault 종합 *)
fault_present := (NOT estop) OR jam_latched OR timeout_1_latched OR timeout_2_latched OR estop_latched OR (NOT mode_valid);

(* 실제 출력 허용 안전 조건 *)
safety_ok := estop AND (NOT fault_present) AND mode_valid AND (NOT stop_cmd);


(* ========================================================================== *)
(* 3. Reset 처리                                                              *)
(* ========================================================================== *)

(* 리셋은 원인 제거 후에만 허용 *)
IF reset_pb
   AND estop
   AND (NOT jam_sensor)
   AND mode_valid
THEN
    jam_latched := FALSE;
    timeout_1_latched := FALSE;
    timeout_2_latched := FALSE;
    estop_latched := FALSE;
END_IF;


(* ========================================================================== *)
(* 4. 메인 시퀀스 제어 (State Machine)                                         *)
(* ========================================================================== *)

CASE state_current OF

    STATE_IDLE:
        IF fault_present THEN
            state_current := STATE_FAULT;
        ELSIF auto_mode AND (NOT manual_mode) AND start_pb AND (NOT stop_cmd) AND (NOT fault_present) THEN
            state_current := STATE_AUTO_RUN;
        ELSE
            state_current := STATE_IDLE;
        END_IF;

    STATE_AUTO_RUN:
        IF fault_present THEN
            state_current := STATE_FAULT;
        ELSIF stop_cmd OR manual_mode OR (NOT auto_mode) THEN
            state_current := STATE_IDLE;
        ELSE
            state_current := STATE_AUTO_RUN;
        END_IF;

    STATE_FAULT:
        IF NOT fault_present THEN
            state_current := STATE_IDLE;
        ELSE
            state_current := STATE_FAULT;
        END_IF;

ELSE
    state_current := STATE_IDLE;

END_CASE;


(* ========================================================================== *)
(* 5. 출력 할당 (Fail-Safe 우선)                                               *)
(* ========================================================================== *)

(* 기본값 선차단 *)
conveyor_1_run := FALSE;
conveyor_2_run := FALSE;
conveyor_3_run := FALSE;

IF safety_ok THEN

    IF state_current = STATE_AUTO_RUN THEN
        (* AUTO MODE: 1번 선행, 센서 조건으로 후단 연동 *)
        conveyor_1_run := TRUE;
        conveyor_2_run := conveyor_1_run AND product_sensor_1;
        conveyor_3_run := conveyor_2_run AND product_sensor_2;

    ELSIF manual_mode AND (NOT auto_mode) THEN
        (* MANUAL MODE: 개별 제어 *)
        conveyor_1_run := m_conveyor_1_pb;
        conveyor_2_run := m_conveyor_2_pb;
        conveyor_3_run := m_conveyor_3_pb;

    END_IF;

END_IF;


(* ========================================================================== *)
(* 6. 알람 출력                                                               *)
(* ========================================================================== *)

alarm_lamp := fault_present;