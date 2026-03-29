(*
==============================================================================
PROJECT  : 프레스 기계 자동 제어 시스템 (Press_Machine_v1.3)
SPEC     : spec.txt 및 현장 안전 규격 반영
AUTHOR   : 서종완 (Seo Jong-wan)
VERSION  : 1.3.0 (Revised Final)
NOTE     : AUTO / MANUAL, Two-Hand Safety, Hold Timer, Timeout, Alarm Latch
==============================================================================
*)

VAR
    (* --- [물리 I/O] --- *)
    auto_mode          : BOOL;    (* 자동 모드 선택 *)
    manual_mode        : BOOL;    (* 수동 모드 선택 *)
    start_pb           : BOOL;    (* 자동 시작 버튼 *)
    stop_pb            : BOOL;    (* 정지 버튼 *)
    reset_pb           : BOOL;    (* 알람 리셋 버튼 *)

    estop              : BOOL;    (* 비상정지: 정상=TRUE, 작동=FALSE *)
    pressure_high      : BOOL;    (* 압력 이상 감지 *)
    up_sensor          : BOOL;    (* 상부 원점 센서 *)
    down_sensor        : BOOL;    (* 하부 도달 센서 *)

    two_hand_left      : BOOL;    (* 양수 좌측 버튼 *)
    two_hand_right     : BOOL;    (* 양수 우측 버튼 *)

    manual_down        : BOOL;    (* 수동 하강 버튼 *)
    manual_up          : BOOL;    (* 수동 상승 버튼 *)

    press_down         : BOOL;    (* 프레스 하강 출력 *)
    press_up           : BOOL;    (* 프레스 상승 출력 *)
    alarm_general      : BOOL;    (* 일반 알람 출력 *)

    (* --- [내부 변수] --- *)
    mode_valid         : BOOL;    (* AUTO/MANUAL 상호배타 유효 *)
    stop_cmd           : BOOL;    (* 정지 명령 *)
    safety_ok          : BOOL;    (* 기본 안전 조건 만족 *)
    two_hand_ok        : BOOL;    (* 양수 버튼 동시 조건 *)
    reset_allowed      : BOOL;    (* 리셋 허용 조건 *)
    cycle_done_pulse   : BOOL;    (* 1사이클 완료 펄스 *)

    alarm_latched      : BOOL := FALSE;

    fault_estop        : BOOL := FALSE;
    fault_pressure     : BOOL := FALSE;
    fault_down_timeout : BOOL := FALSE;
    fault_up_timeout   : BOOL := FALSE;
    fault_two_hand     : BOOL := FALSE;

    cycle_count        : INT := 0;

    (* --- [타이머] --- *)
    press_hold_timer   : TON;     (* 압착 유지 타이머 *)
    down_timeout_timer : TON;     (* 하강 타임아웃 *)
    up_timeout_timer   : TON;     (* 상승 타임아웃 *)

    (* --- [상태 머신] --- *)
    state_current      : INT := 0;
    STATE_IDLE         : INT := 0;
    STATE_READY        : INT := 10;
    STATE_DOWN         : INT := 20;
    STATE_HOLD         : INT := 30;
    STATE_UP           : INT := 40;
    STATE_FAULT        : INT := 90;
END_VAR


(* ========================================================================== *)
(* 1. 기본 조건 계산                                                           *)
(* ========================================================================== *)

mode_valid := (auto_mode AND NOT manual_mode) OR (manual_mode AND NOT auto_mode);
stop_cmd := stop_pb;

safety_ok := estop AND (NOT pressure_high) AND mode_valid;
two_hand_ok := two_hand_left AND two_hand_right;

cycle_done_pulse := FALSE;


(* ========================================================================== *)
(* 2. Fault 감시 / 래치                                                        *)
(* ========================================================================== *)

(* 실시간 이상 조건 *)
IF NOT estop THEN
    fault_estop := TRUE;
END_IF;

IF pressure_high THEN
    fault_pressure := TRUE;
END_IF;

(* 하강 단계에서만 타임아웃 감시 *)
down_timeout_timer(
    IN := (state_current = STATE_DOWN) AND (NOT down_sensor),
    PT := T#5s
);

IF down_timeout_timer.Q THEN
    fault_down_timeout := TRUE;
END_IF;

(* 상승 단계에서만 타임아웃 감시 *)
up_timeout_timer(
    IN := (state_current = STATE_UP) AND (NOT up_sensor),
    PT := T#5s
);

IF up_timeout_timer.Q THEN
    fault_up_timeout := TRUE;
END_IF;

(* 양수 버튼 안전 감시: 하강 중 불일치/중간해제 *)
IF (state_current = STATE_DOWN) AND (NOT two_hand_ok) THEN
    fault_two_hand := TRUE;
END_IF;

(* 종합 알람 래치 *)
alarm_latched :=
    fault_estop
    OR fault_pressure
    OR fault_down_timeout
    OR fault_up_timeout
    OR fault_two_hand;


(* ========================================================================== *)
(* 3. 리셋 처리                                                                *)
(* ========================================================================== *)

reset_allowed :=
    reset_pb
    AND estop
    AND (NOT pressure_high)
    AND up_sensor
    AND (NOT down_sensor);

IF reset_allowed THEN
    fault_estop := FALSE;
    fault_pressure := FALSE;
    fault_down_timeout := FALSE;
    fault_up_timeout := FALSE;
    fault_two_hand := FALSE;
END_IF;


(* ========================================================================== *)
(* 4. 상태 머신                                                                *)
(* ========================================================================== *)

CASE state_current OF

    STATE_IDLE:
        IF alarm_latched THEN
            state_current := STATE_FAULT;

        ELSIF safety_ok AND up_sensor THEN
            state_current := STATE_READY;

        ELSE
            state_current := STATE_IDLE;
        END_IF;


    STATE_READY:
        IF alarm_latched THEN
            state_current := STATE_FAULT;

        ELSIF stop_cmd THEN
            state_current := STATE_IDLE;

        ELSIF auto_mode AND start_pb AND safety_ok AND up_sensor AND (NOT alarm_latched) THEN
            state_current := STATE_DOWN;

        ELSIF NOT safety_ok THEN
            state_current := STATE_IDLE;

        ELSE
            state_current := STATE_READY;
        END_IF;


    STATE_DOWN:
        IF alarm_latched THEN
            state_current := STATE_FAULT;

        ELSIF stop_cmd THEN
            state_current := STATE_IDLE;

        ELSIF down_sensor THEN
            state_current := STATE_HOLD;

        ELSE
            state_current := STATE_DOWN;
        END_IF;


    STATE_HOLD:
        IF alarm_latched THEN
            state_current := STATE_FAULT;

        ELSIF stop_cmd THEN
            state_current := STATE_IDLE;

        ELSIF press_hold_timer.Q THEN
            state_current := STATE_UP;

        ELSE
            state_current := STATE_HOLD;
        END_IF;


    STATE_UP:
        IF alarm_latched THEN
            state_current := STATE_FAULT;

        ELSIF stop_cmd THEN
            state_current := STATE_IDLE;

        ELSIF up_sensor THEN
            cycle_done_pulse := TRUE;
            state_current := STATE_READY;

        ELSE
            state_current := STATE_UP;
        END_IF;


    STATE_FAULT:
        IF (NOT alarm_latched) AND safety_ok AND up_sensor THEN
            state_current := STATE_READY;
        ELSE
            state_current := STATE_FAULT;
        END_IF;


ELSE
    state_current := STATE_IDLE;

END_CASE;


(* ========================================================================== *)
(* 5. 보조 타이머                                                              *)
(* ========================================================================== *)

press_hold_timer(
    IN := (state_current = STATE_HOLD),
    PT := T#2s
);


(* ========================================================================== *)
(* 6. 출력 할당 (Fail-Safe 우선)                                               *)
(* ========================================================================== *)

(* 기본값 차단 *)
press_down := FALSE;
press_up := FALSE;

IF safety_ok AND (NOT alarm_latched) THEN

    IF state_current = STATE_DOWN THEN
        (* 양수 버튼이 유지될 때만 하강 허용 *)
        IF two_hand_ok THEN
            press_down := TRUE;
        ELSE
            press_down := FALSE;
        END_IF;
    END_IF;

    IF state_current = STATE_UP THEN
        press_up := TRUE;
    END_IF;

    IF manual_mode AND (NOT auto_mode) THEN
        (* 수동 모드: 동시 출력 금지 *)
        IF manual_down AND (NOT manual_up) THEN
            press_down := TRUE;
            press_up := FALSE;
        ELSIF manual_up AND (NOT manual_down) THEN
            press_down := FALSE;
            press_up := TRUE;
        ELSE
            press_down := FALSE;
            press_up := FALSE;
        END_IF;
    END_IF;

END_IF;


(* ========================================================================== *)
(* 7. 사이클 카운트                                                            *)
(* ========================================================================== *)

IF cycle_done_pulse THEN
    cycle_count := cycle_count + 1;
END_IF;


(* ========================================================================== *)
(* 8. 알람 출력                                                                *)
(* ========================================================================== *)

alarm_general := alarm_latched;