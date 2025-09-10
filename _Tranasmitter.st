(*=============================================================*)
(* FB: TransmitterHandler                                      *)
(* Description: Handles transmitter scaling, PV limits, high/low alarms, and channel fault *)
(*=============================================================*)

FUNCTION_BLOCK TransmitterHandler
VAR_INPUT
    Raw_AI         : INT;       (* Raw analog input from AI module, e.g., 0-27648 *)
    PV_Min         : REAL;       (* Minimum engineering unit value *)
    PV_Max         : REAL;      (* Maximum engineering unit value *)
    SP_High        : REAL;       (* High alarm setpoint *)
    SP_Low         : REAL;       (* Low alarm setpoint *)
    Fault_Threshold: INT;        (* Threshold to detect open circuit / bad channel *)
END_VAR

VAR_OUTPUT
    PV             : REAL;      (* Process value in engineering units *)
    Alarm_High     : BOOL;      (* High alarm *)
    Alarm_Low      : BOOL;      (* Low alarm *)
    Alarm_Fault    : BOOL;      (* Channel fault alarm *)
END_VAR

VAR
    Scaled_PV      : REAL;      (* Internal variable for PV calculation *)
END_VAR

(*================= Scaling & Fault Check =================*)
IF (Raw_AI < Fault_Threshold) OR (Raw_AI > (27648 - Fault_Threshold)) THEN
    Alarm_Fault := TRUE;
    PV := 0.0;
ELSE
    Alarm_Fault := FALSE;
    Scaled_PV := (REAL(Raw_AI) * (PV_Max - PV_Min) / 27648.0) + PV_Min;

    (* Clamp PV to min/max *)
    IF Scaled_PV > PV_Max THEN
        PV := PV_Max;
    ELSIF Scaled_PV < PV_Min THEN
        PV := PV_Min;
    ELSE
        PV := Scaled_PV;
    END_IF;
END_IF;

(*================= High/Low Alarms =================*)
Alarm_High := (PV >= SP_High) AND (NOT Alarm_Fault);
Alarm_Low  := (PV <= SP_Low)  AND (NOT Alarm_Fault);
