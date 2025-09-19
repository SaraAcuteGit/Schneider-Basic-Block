(*===================================================================
Function Block : FB_VFD_Pump
Author         : Saravanan
Company        : Acute-Automation
Created Date   : 2025-09-18
Description    : This function block is used for VFD Pump control.
                 It includes start/stop logic, emergency stop, 
		 ramping, feedback, alarms, and runtime calculation.
=====================================================================*)

(*DDT Mapping*)
DDT_PUMP.EStop_Sts:=EStop;
DDT_PUMP.Trip_Sts:=In_Trip;
DDT_PUMP.Interlock_Sts:=Interlock;
DDT_PUMP.Start_Cmd:=Start_Cmd;
Man_Temp_Speed:=DDT_PUMP.Man_Speed_Sp;
Auto_Temp_speed:=Auto_Speed_In;
DDT_PUMP.Speed_Out:=Speed_Out;


(* Available*)
IF DDT_PUMP.Remote_Sts AND NOT DDT_PUMP.Com_Fault_Alm THEN
  DDT_PUMP.Avail_sts:=TRUE;
ELSE
    DDT_PUMP.Avail_sts:=FALSE;
END_IF;


(*Remote Status*)
IF In_Remote OR DDT_PUMP.Simulation THEN
    
     DDT_PUMP.Remote_Sts:= TRUE;
Else
     DDT_PUMP.Remote_Sts:= FALSE;
END_IF;


(*Run Status with Simulation*)
IF In_Run OR (DDT_PUMP.Simulation AND Start_Cmd) THEN
    DDT_PUMP.Run_Sts:=TRUE;
Else
    DDT_PUMP.Run_Sts:=FALSE;
END_IF;


IF DDT_PUMP.Simulation AND Start_Cmd THEN
    DDT_PUMP.Feedback:=Speed_Out;
Else
    DDT_PUMP.Feedback:=Feedback_Temp;
END_IF;


(*Auto mode selsection*)
IF DDT_PUMP.Auto_Man THEN   
     DDT_PUMP.Auto_Sts:=TRUE;
ELSE  
     DDT_PUMP.Auto_Sts:=FALSE;
END_IF;


(*Manual Mode Start/Stop*)

IF NOt DDT_PUMP.EStop_Sts AND NOT DDT_PUMP.Maint_Mode AND NOT DDT_PUMP.Interlock_Sts THEN

   IF DDT_PUMP.Remote_Sts AND NOT DDT_PUMP.Auto_Sts THEN
          
	  IF DDT_PUMP.Man_Start AND NOT DDT_PUMP.Com_Fault_Alm THEN
	     Start_Cmd:=TRUE;
	     Stop_Cmd:=FALSE;
          ElsIf DDT_PUMP.Man_Stop OR DDT_PUMP.Com_Fault_Alm THEN 
	     Stop_Cmd:=TRUE;
             Start_Cmd:=FALSE;
          END_IF;	     

   END_IF;

ELSE
    Stop_Cmd:=TRUE;
    Start_Cmd:=FALSE;

END_IF;


(*Auto Mode Start/Stop*)

IF NOT DDT_PUMP.EStop_Sts AND NOT DDT_PUMP.Maint_Mode AND NOT DDT_PUMP.Interlock_Sts  THEN

   IF DDT_PUMP.Remote_Sts AND DDT_PUMP.Auto_Sts THEN
          
	  IF Auto_Start_Req AND NOT Auto_Stop_Req AND NOT DDT_PUMP.Com_Fault_Alm THEN
	     Start_Cmd:=TRUE;
	     Stop_Cmd:=FALSE;
          END_IF;
	  IF Auto_Stop_Req OR DDT_PUMP.Com_Fault_Alm THEN
	     Stop_Cmd:=TRUE;
             Start_Cmd:=FALSE;
          END_IF;	     

   END_IF;

ELSE
    Stop_Cmd:=TRUE;
    Start_Cmd:=FALSE;

END_IF;



(*Man Speed Setpoint*)

IF NOT DDT_PUMP.EStop_Sts AND NOT DDT_PUMP.Maint_Mode THEN

   IF NOT DDT_PUMP.Interlock_Sts AND DDT_PUMP.Remote_Sts AND NOT DDT_PUMP.Auto_Sts THEN
          
	  IF Start_Cmd AND NOT Stop_Cmd AND NOT DDT_PUMP.Com_Fault_Alm THEN
	     Speed_Out_Temp:=Man_Temp_speed;	    
          ELSIF Stop_Cmd OR DDT_PUMP.Com_Fault_Alm THEN
	     Speed_Out_Temp:=0.0;	
          END_IF;	     

   END_IF;

ELSE
    Speed_Out_Temp:=0.0;
END_IF;



(*Auto Speed Setpoint*)
IF NOt DDT_PUMP.EStop_Sts AND NOT DDT_PUMP.Maint_Mode THEN

   IF NOT DDT_PUMP.Interlock_Sts AND DDT_PUMP.Remote_Sts AND DDT_PUMP.Auto_Sts THEN
          
	  IF Start_Cmd AND NOT Stop_Cmd AND NOT DDT_PUMP.Com_Fault_Alm THEN
	     Speed_Out_Temp:=Auto_Temp_speed;	    
          ELSIF Stop_Cmd OR DDT_PUMP.Com_Fault_Alm THEN
	     Speed_Out_Temp:=0.0;	
          END_IF;	     

   END_IF;

ELSE
    Speed_Out_Temp:=0.0;
END_IF;


(*************Fail To Run Alarm****************)

FTR_TMR (IN := DDT_PUMP.ABE_Alm_Enbl AND DDT_PUMP.Remote_Sts AND Start_Cmd AND NOT DDT_PUMP.Run_Sts AND NOT DDT_PUMP.Fault_Reset,
       PT :=DINT_TO_TIME(IN:= (DDT_PUMP.FailToRun_Sp *1000)),
       Q => DDT_PUMP.Fail_to_Run_Alm);


(***************Fail To Stop Alarm*************)

FTS_TMR (IN := DDT_PUMP.ABE_Alm_Enbl AND DDT_PUMP.Remote_Sts AND Stop_Cmd AND DDT_PUMP.Run_Sts AND NOT DDT_PUMP.Fault_Reset,
       PT :=DINT_TO_TIME(IN:= (DDT_PUMP.FailToStop_Sp *1000)),
       Q => DDT_PUMP.Fail_to_Stop_Alm);



(************Common Fault***********)

IF DDT_PUMP.Fail_to_Run_Alm OR DDT_PUMP.Fail_to_STOP_Alm OR DDT_PUMP.Trip_Sts OR DDT_PUMP.EStop_Sts THEN

   DDT_PUMP.Com_Fault_Alm:=TRUE;

Elsif DDT_PUMP.Fault_Reset THEN
 
   DDT_PUMP.Com_Fault_Alm:=FALSE;

END_IF;


IF DDT_PUMP.Fail_to_Run_Alm OR DDT_PUMP.Fail_to_STOP_Alm THEN

    DDT_PUMP.ABE_Alm:=TRUE;

Elsif DDT_PUMP.Fault_Reset THEN
 
    DDT_PUMP.ABE_Alm:=FALSE;

END_IF;


(*********************Running Time Calculation********************)

DDT_PUMP.Run_Min:=RunMinutes;    
DDT_PUMP.Run_Hr:=RunHours; 
DDT_PUMP.Run_Day:=RunDays;   

(* Run hour calculation Reset*)
IF DDT_PUMP.Runtime_Reset THEN
   RunMinutes := 0;
   RunHours := 0;
END_IF;

(* Start 1-minute timer when pump is running *)
RunTimer(IN := DDT_PUMP.Run_Sts, PT := T#60s);

IF RunTimer.Q THEN
RunMinutes := RunMinutes + 1;
RunTimer(IN := FALSE);
END_IF;

(* Convert minutes to hours *)
IF RunMinutes >= 60 THEN
   RunHours := RunHours + (RunMinutes / 60);
   RunMinutes := RunMinutes MOD 60;
END_IF;

IF RunHours >= 24 THEN
    RunDays := RunDays + (RunHours / 24);
    RunHours := RunHours MOD 24;
END_IF;


(*********************Speed Ramp up/Down ********************)

Speed_Ramp_Para.inc_rate:=Speed_Inc;
Speed_Ramp_Para.dec_rate:=Speed_Dec;

Speed_Ramp (RSP := Speed_Out_Temp,
        PARA := Speed_Ramp_Para,
        SP => Speed_Out);


(*********************AI And AO SCALING ********************)
AI_Para.in_max :=AI_Raw_Min;
AI_Para.in_min :=AI_Raw_Max;
AI_Para.out_max :=FB_Min;
AI_Para.out_min :=FB_Max;

AI_FB (IN := INT_TO_REAL(In_FB),
       PARA := AI_Para,
       OUT =>Feedback_Temp);


AO_Para.in_max :=Out_Min;
AO_Para.in_min :=Out_Max;
AO_Para.out_max :=AO_Raw_Min;
AO_Para.out_min :=AO_Raw_Max;

AO_OUT (IN := Speed_Out,
       PARA := AO_Para,
       OUT =>Speed_Out_AO);

(**************************************************************)