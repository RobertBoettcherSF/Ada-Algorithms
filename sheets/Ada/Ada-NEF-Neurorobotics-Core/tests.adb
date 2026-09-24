--  V&V suite for Ada-NEF-Neurorobotics-Core (Ada + assertions only; no gnatprove).
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Rover_Control;
with LIF_Neuron;
with NEF_Ensemble;

procedure Tests is
   Passes : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Passes := Passes + 1;
         Put_Line ("PASS: " & Name);
      else
         Put_Line ("FAIL: " & Name);
         raise Program_Error with "Assertion failed: " & Name;
      end if;
   end Check;

   Tol : constant Float := 1.0e-5;

   ----------------------------------------------------------------
   --  Rover_Control fixtures (hand-calculated from eqs. 1–2)
   ----------------------------------------------------------------
   Ka : constant Float := 1.0;
   Kp : constant Float := 1.0;

   --  (3,4): ||.|| = 5 → min(5,1)=1 → u_acc = 1.0
   Acc_34 : constant Float := Rover_Control.Acceleration (3.0, 4.0, Ka);
   --  (0.3,0.4): ||.|| = 0.5 → u_acc = 0.5
   Acc_034 : constant Float := Rover_Control.Acceleration (0.3, 0.4, Ka);
   --  (0,0): u_acc = 0
   Acc_00 : constant Float := Rover_Control.Acceleration (0.0, 0.0, Ka);
   --  Ka scaling: Ka=2, (0.3,0.4) → 1.0
   Acc_Ka2 : constant Float := Rover_Control.Acceleration (0.3, 0.4, 2.0);

   --  Steer: arctan2(-x*, y*) with Ada Arctan(Y=>-x*, X=>y*)
   --  (0,1), q=0 → atan2(0,1)=0 → steer=0
   St_01 : constant Float := Rover_Control.Steer (0.0, 1.0, 0.0, Kp);
   --  (1,0), q=0 → atan2(-1,0) = -π/2
   St_10 : constant Float := Rover_Control.Steer (1.0, 0.0, 0.0, Kp);
   --  (-1,0), q=0 → atan2(1,0) = +π/2
   St_M10 : constant Float := Rover_Control.Steer (-1.0, 0.0, 0.0, Kp);
   --  (0,1), q=π/4 → 0 - π/4 = -π/4
   St_Q : constant Float := Rover_Control.Steer (0.0, 1.0, Ada.Numerics.Pi / 4.0, Kp);

   ----------------------------------------------------------------
   --  LIF
   ----------------------------------------------------------------
   N_Strong : LIF_Neuron.Neuron := LIF_Neuron.Create;
   N_Zero   : LIF_Neuron.Neuron := LIF_Neuron.Create;
   Spiked   : Boolean;
   Saw_Spike : Boolean := False;

   ----------------------------------------------------------------
   --  NEF
   ----------------------------------------------------------------
   Ens : NEF_Ensemble.Ensemble;
   MSE, Max_Abs : Float;
   --  Training-set error thresholds (educational N=32 rate NEF)
   MSE_Limit     : constant Float := 0.02;
   Max_Abs_Limit : constant Float := 0.25;
   D_Acc, R_Acc  : Float;
begin
   Put_Line ("=== Rover_Control (eqs. 1–2) ===");
   Check (abs (Acc_34 - 1.0) < Tol, "accel (3,4) -> 1.0");
   Check (abs (Acc_034 - 0.5) < Tol, "accel (0.3,0.4) -> 0.5");
   Check (abs (Acc_00 - 0.0) < Tol, "accel (0,0) -> 0.0");
   Check (abs (Acc_Ka2 - 1.0) < Tol, "accel Ka=2 (0.3,0.4) -> 1.0");

   Check (abs (St_01 - 0.0) < Tol, "steer (0,1) q=0 -> 0");
   Check (abs (St_10 - (-Ada.Numerics.Pi / 2.0)) < Tol,
          "steer (1,0) q=0 -> -pi/2");
   Check (abs (St_M10 - (Ada.Numerics.Pi / 2.0)) < Tol,
          "steer (-1,0) q=0 -> +pi/2");
   Check (abs (St_Q - (-Ada.Numerics.Pi / 4.0)) < Tol,
          "steer (0,1) q=pi/4 -> -pi/4");

   Put_Line ("=== LIF_Neuron ===");
   for K in 1 .. 500 loop
      LIF_Neuron.Step (N_Strong, 5.0, Spiked);
      if Spiked then
         Saw_Spike := True;
      end if;
   end loop;
   Check (Saw_Spike, "LIF spikes on strong input I=5");
   Check (LIF_Neuron.Spike_Count (N_Strong) > 0, "LIF spike count > 0");

   for K in 1 .. 500 loop
      LIF_Neuron.Step (N_Zero, 0.0, Spiked);
   end loop;
   Check (LIF_Neuron.Spike_Count (N_Zero) = 0, "LIF silent on I=0");
   Check (LIF_Neuron.Voltage (N_Zero) < LIF_Neuron.Default_V_Thresh,
          "LIF voltage stays below threshold at I=0");

   Put_Line ("=== NEF_Ensemble (educational) ===");
   Ens := NEF_Ensemble.Create (Seed => 42);
   NEF_Ensemble.Fit_Acceleration
     (Ens, Ka => 1.0, Grid_Min => -1.5, Grid_Max => 1.5, Grid_Steps => 11);
   Check (NEF_Ensemble.Is_Fitted (Ens), "NEF fitted flag set");

   NEF_Ensemble.Eval_Error
     (Ens, Ka => 1.0, Grid_Min => -1.5, Grid_Max => 1.5,
      Grid_Steps => 11, MSE => MSE, Max_Abs => Max_Abs);
   Put_Line ("  training MSE=" & Float'Image (MSE)
             & " max_abs=" & Float'Image (Max_Abs));
   Check (MSE <= MSE_Limit, "NEF training MSE <= 0.02");
   Check (Max_Abs <= Max_Abs_Limit, "NEF training max-abs <= 0.25");

   --  Spot-check Decode vs Rover_Control reference
   declare
      Pts : constant array (1 .. 4, 1 .. 2) of Float :=
        [[0.0, 0.0], [0.5, 0.0], [0.0, 0.8], [0.3, 0.4]];
   begin
      for P in 1 .. 4 loop
         R_Acc := Rover_Control.Acceleration (Pts (P, 1), Pts (P, 2), 1.0);
         D_Acc := NEF_Ensemble.Decode (Ens, Pts (P, 1), Pts (P, 2));
         Put_Line ("  point (" & Float'Image (Pts (P, 1)) & ","
                   & Float'Image (Pts (P, 2)) & ") ref="
                   & Float'Image (R_Acc) & " dec=" & Float'Image (D_Acc));
         Check (abs (D_Acc - R_Acc) <= Max_Abs_Limit,
                "NEF decode near Rover_Control at sample point");
      end loop;
   end;

   --  Sanity: LIF_Rates returns non-negative finite-ish values
   declare
      LR : constant NEF_Ensemble.Rate_Array :=
        NEF_Ensemble.LIF_Rates (Ens, 0.5, 0.5, Steps => 100);
      Nonneg : Boolean := True;
   begin
      for I in LR'Range loop
         if LR (I) < 0.0 then
            Nonneg := False;
         end if;
      end loop;
      Check (Nonneg, "LIF_Rates non-negative");
   end;

   New_Line;
   Put_Line ("ALL TESTS PASSED:" & Natural'Image (Passes));
end Tests;
