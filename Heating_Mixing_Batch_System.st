(*
==============================================================================
PROJECT  : 가열 혼합 배치 제어 시스템 (Heating_Mixing_Batch_v1.1)
INDUSTRY : Food & Chemical Process (식품/화학 공정)
AUTHOR   : 서종완 (Seo Jong-wan)
VERSION  : 1.1.0
NOTE     : 3단 공정(투입/혼합/배출) 자동 시퀀스, 아날로그 온도 제어, 안전 인터락 포함==============================================================================
*)

VAR
    (* --- [1. 물리 I/O 셋팅] --- *)
    auto_mode            : BOOL;    (* 자동 모드 선택 *)
    manual_mode          : BOOL;    (* 수동 모드 선택 *)
    start_pb             : BOOL;    (* 공정 시작 버튼 *)
    stop_pb              : BOOL;    (* 정지 버튼 (N.C) *)
    reset_pb             : BOOL;    (* 에러 리셋 버튼 *)
    estop                : BOOL;    (* 비상정지 (B접점: 정상 TRUE, 작동 FALSE) *)

    level_low            : BOOL;    (* 저수위 감지 센서 *)
    level_high           : BOOL;    (* 만수위 감지 센서 *)
    over_temp            : BOOL;    (* 과온 감지 센서 (안전 장치) *)
    current_temp         : REAL;    (* 현재 온도 (Analog Input) *)
    target_temp          : REAL;    (* 설정 온도 (SV) *)

    (* 제어 출력 (Y) *)
    inlet_valve_open     : BOOL;    (* 입구 밸브 개방 *)
    feed_pump_run        : BOOL;    (* 원료 투입 펌프 *)
    agitator_run         : BOOL;    (* 교반기(Agitator) 구동 *)
    heater_run           : BOOL;    (* 가열 히터 마그네트 *)
    discharge_valve_open : BOOL;    (* 배출 밸브 개방 *)
    wash_valve_open      : BOOL;    (* 세척 밸브 개방 *)
    alarm_lamp           : BOOL;    (* 시스템 경보 램프 *)

    (* --- [2. 제어 변수 및 상태 머신] --- *)
    state_current        : INT := 0; (* 현재 시퀀스 상태 *)
    state_next           : INT := 0; (* 다음 전이 상태 *)

    (* 상태 상수 *)
    STATE_IDLE           : INT := 0;  (* 대기 상태 *)
    STATE_FILLING        : INT := 10; (* 원료 투입 중 *)
    STATE_MIXING         : INT := 20; (* 가열 및 혼합 중 *)
    STATE_DISCHARGE      : INT := 30; (* 완성품 배출 중 *)
    STATE_CLEANING       : INT := 50; (* 자동 세척 공정 *)
    STATE_FAULT          : INT := 90; (* 이상 발생 (에러) *)

    (* 내부 플래그 및 타이머 *)
    safety_ok            : BOOL;    (* 시스템 안전 무결성 *)
    fault_present        : BOOL;    (* 실시간 에러 발생 플래그 *)
    alarm_latched        : BOOL;    (* 래치 알람 상태 *)
    transition_taken     : BOOL;    (* 상태 전이 완료 플래그 *)

    fill_timer           : TON;     (* 투입 시간 초과 감지 *)
    mix_timer            : TON;     (* 혼합 공정 타이머 *)
    discharge_timer      : TON;     (* 배출 확인 타이머 *)

    (* --- [3. 최소 보완 변수] --- *)
    start_rise           : R_TRIG;  (* 시작 버튼 상승엣지 *)
    start_pulse          : BOOL;    (* 1스캔 시작 펄스 *)

    auto_mode_prev       : BOOL := FALSE;
    manual_mode_prev     : BOOL := FALSE;
    mode_transfer_blank  : BOOL;    (* AUTO↔MANUAL 전환 순간 출력 차단 *)

    mode_valid           : BOOL;    (* AUTO / MANUAL 상호배타 확인 *)

    fault_estop_rt       : BOOL;    (* 실시간 E-STOP fault *)
    fault_overtemp_rt    : BOOL;    (* 실시간 과온 fault *)
    fault_hi_temp_rt     : BOOL;    (* 실시간 100도 초과 fault *)

    alarm_estop          : BOOL;    (* 분리 알람 *)
    alarm_overtemp       : BOOL;    (* 분리 알람 *)
    alarm_hi_temp        : BOOL;    (* 분리 알람 *)
END_VAR


(* ========================================================================== *)
(* 3. 안전 및 인터락 로직 (Safety & Interlock)                                *)
(* ========================================================================== *)

(* 시작 버튼 엣지 처리 *)
start_rise(CLK := start_pb);
start_pulse := start_rise.Q;

(* AUTO / MANUAL 상호배타 *)
mode_valid := (auto_mode AND (NOT manual_mode)) OR (manual_mode AND (NOT auto_mode));

(* 모드 전환 순간 1스캔 출력 블랭크 *)
mode_transfer_blank := (auto_mode <> auto_mode_prev) OR (manual_mode <> manual_mode_prev);
auto_mode_prev := auto_mode;
manual_mode_prev := manual_mode;

(* 전체 시스템 가동 조건: 비상정지 해제 및 과온 이상 없음 *)
safety_ok := estop AND (NOT over_temp) AND mode_valid;

(* 실시간 fault 분리 *)
fault_estop_rt := (NOT estop);
fault_overtemp_rt := over_temp;
fault_hi_temp_rt := (current_temp > 100.0);

fault_present := fault_estop_rt OR fault_overtemp_rt OR fault_hi_temp_rt;

(* 래치 fault 처리 *)
IF fault_present THEN
    alarm_latched := TRUE;
END_IF;

IF reset_pb AND safety_ok AND (current_temp <= 100.0) THEN
    alarm_latched := FALSE;
END_IF;

(* 알람 분리 *)
alarm_estop := fault_estop_rt OR ((NOT estop) AND alarm_latched);
alarm_overtemp := fault_overtemp_rt OR (over_temp AND alarm_latched);
alarm_hi_temp := fault_hi_temp_rt OR ((current_temp > 100.0) AND alarm_latched);


(* ========================================================================== *)
(* 4. 상태 머신 (State Machine - CASE Logic)                                  *)
(* ========================================================================== *)

transition_taken := FALSE;
state_next := state_current;

CASE state_current OF

    STATE_IDLE:
        (* 공정 시작 조건: 자동모드 + 시작엣지 + 수위 낮음 *)
        IF auto_mode AND (NOT manual_mode) AND start_pulse AND (NOT level_high) AND (NOT alarm_latched) THEN
            state_next := STATE_FILLING;
            transition_taken := TRUE;
        ELSIF alarm_latched THEN
            state_next := STATE_FAULT;
            transition_taken := TRUE;
        END_IF;

    STATE_FILLING:
        (* 원료 투입: 만수위 도달 시 다음 단계로 *)
        IF level_high THEN
            state_next := STATE_MIXING;
            transition_taken := TRUE;
        ELSIF (NOT safety_ok) OR (NOT auto_mode) OR manual_mode OR alarm_latched THEN
            state_next := STATE_FAULT;
            transition_taken := TRUE;
        END_IF;

    STATE_MIXING:
        (* 가열 및 혼합: 설정 온도 도달 및 혼합 타이머 완료 시 *)
        mix_timer(IN := TRUE, PT := T#10m); (* 10분 혼합 예시 *)

        IF (current_temp >= target_temp) AND mix_timer.Q THEN
            state_next := STATE_DISCHARGE;
            transition_taken := TRUE;
            mix_timer(IN := FALSE);
        ELSIF alarm_latched OR (NOT safety_ok) OR manual_mode THEN
            state_next := STATE_FAULT;
            transition_taken := TRUE;
        END_IF;

    STATE_DISCHARGE:
        (* 제품 배출: 저수위 센서 감지 시 배출 완료 *)
        IF (NOT level_low) THEN
            state_next := STATE_CLEANING;
            transition_taken := TRUE;
        ELSIF alarm_latched OR (NOT safety_ok) OR manual_mode THEN
            state_next := STATE_FAULT;
            transition_taken := TRUE;
        END_IF;

    STATE_CLEANING:
        (* 세척 완료 후 대기 상태로 복귀 *)
        discharge_timer(IN := TRUE, PT := T#30s);
        IF discharge_timer.Q THEN
            state_next := STATE_IDLE;
            transition_taken := TRUE;
            discharge_timer(IN := FALSE);
        ELSIF alarm_latched OR (NOT safety_ok) OR manual_mode THEN
            state_next := STATE_FAULT;
            transition_taken := TRUE;
        END_IF;

    STATE_FAULT:
        (* 알람 리셋 시 대기로 복귀 *)
        IF (NOT alarm_latched) AND reset_pb THEN
            state_next := STATE_IDLE;
            transition_taken := TRUE;
        END_IF;

ELSE
    state_next := STATE_IDLE;
END_CASE;

(* 상태 업데이트 *)
state_current := state_next;


(* ========================================================================== *)
(* 5. 출력 할당 (Fail-Safe 우선 설계)                                         *)
(* ========================================================================== *)

(* 기본값 차단 (Default Safe State) *)
inlet_valve_open      := FALSE;
feed_pump_run         := FALSE;
agitator_run          := FALSE;
heater_run            := FALSE;
discharge_valve_open  := FALSE;
wash_valve_open       := FALSE;
alarm_lamp            := alarm_latched;

(* 안전 조건 만족 + 래치 없음 + 모드 전환 순간 아님 일 때만 출력 허용 *)
IF safety_ok AND (NOT alarm_latched) AND (NOT mode_transfer_blank) THEN

    CASE state_current OF
        STATE_FILLING:
            inlet_valve_open := TRUE;
            feed_pump_run    := TRUE;

        STATE_MIXING:
            agitator_run := TRUE;
            (* 히터는 설정 온도보다 낮을 때만 작동 (이중 인터락) *)
            IF current_temp < target_temp THEN
                heater_run := TRUE;
            END_IF;

        STATE_DISCHARGE:
            discharge_valve_open := TRUE;

        STATE_CLEANING:
            wash_valve_open      := TRUE;
            discharge_valve_open := TRUE; (* 세척액 배출 *)
    END_CASE;

END_IF;

(* 수동 모드 동작 (자동 모드가 아닐 때만 유효) *)
IF manual_mode AND (NOT auto_mode) AND safety_ok AND (NOT alarm_latched) AND (NOT mode_transfer_blank) THEN
    (* 필요 시 수동 버튼 인터페이스 추가 가능 *)
END_IF;