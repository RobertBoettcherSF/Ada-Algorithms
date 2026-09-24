--  V&V suite for Ada-NEF-Adaptive-OSC (Ada + assertions only; no gnatprove).
with Ada.Text_IO; use Ada.Text_IO;
with OSC_PD;
with Adaptive_Residual;
with Plant_Sim;

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

   subtype JV is OSC_PD.Joint_Vector;

   ----------------------------------------------------------------
   --  Shared targets / gains
   ----------------------------------------------------------------
   Q_Des  : constant JV := [0.5, -0.3];
   Qd_Des : constant JV := [0.0, 0.0];
   G      : constant OSC_PD.Gains := (Kp => 8.0, Kd => 2.0);
   Steps  : constant Natural := 3000;
   Dist   : constant JV := [1.2, -0.8];  -- unmodelled constant torque bias

   function Run_Closed_Loop
     (Use_Adapt   : Boolean;
      Disturbance : JV;
      N_Steps     : Natural) return Float
   is
      P : Plant_Sim.Plant := Plant_Sim.Create
        (Dt => 0.01, Inertia => [1.0, 1.0],
         Disturbance => Disturbance,
         Q0 => [0.0, 0.0], Qd0 => [0.0, 0.0]);
      C : Adaptive_Residual.Controller :=
        Adaptive_Residual.Create
          (Learning_Rate => 0.08, Weight_Bound => 4.0, Rate_Bound => 0.05);
      Tau_PD, Tau_Ad, Tau : JV;
      Phi : Adaptive_Residual.Feature_Vector;
      E   : JV;
      Dn  : Float;
   begin
      C.Enabled := Use_Adapt;
      for K in 1 .. N_Steps loop
         Tau_PD := OSC_PD.Torque
           (Plant_Sim.Position (P), Plant_Sim.Velocity (P),
            Q_Des, Qd_Des, G);
         Phi := Adaptive_Residual.Features
           (Plant_Sim.Position (P), Plant_Sim.Velocity (P));
         Tau_Ad := Adaptive_Residual.Torque (C, Phi);
         for I in JV'Range loop
            Tau (I) := Tau_PD (I) + Tau_Ad (I);
         end loop;
         --  Learn from tracking error, then integrate plant.
         E := OSC_PD.Error (Plant_Sim.Position (P), Q_Des);
         if Use_Adapt then
            Adaptive_Residual.Update (C, Phi, E, Dn);
         end if;
         Plant_Sim.Step (P, Tau);
      end loop;
      return OSC_PD.Norm (OSC_PD.Error (Plant_Sim.Position (P), Q_Des));
   end Run_Closed_Loop;

   Err_PD, Err_Adapt : Float;
   Dn_Zero : Float;
   C0 : Adaptive_Residual.Controller;
   Phi0 : Adaptive_Residual.Feature_Vector;
   E0 : JV;
   W_Before : Float;
begin
   ----------------------------------------------------------------
   --  1. PD alone reduces error on a step target (no disturbance)
   ----------------------------------------------------------------
   Put_Line ("=== OSC_PD step response (no disturbance) ===");
   declare
      P : Plant_Sim.Plant := Plant_Sim.Create
        (Dt => 0.01, Inertia => [1.0, 1.0],
         Disturbance => [0.0, 0.0],
         Q0 => [0.0, 0.0], Qd0 => [0.0, 0.0]);
      Tau : JV;
      E_Init, E_Final : Float;
   begin
      E_Init := OSC_PD.Norm (OSC_PD.Error (Plant_Sim.Position (P), Q_Des));
      for K in 1 .. Steps loop
         Tau := OSC_PD.Torque
           (Plant_Sim.Position (P), Plant_Sim.Velocity (P),
            Q_Des, Qd_Des, G);
         Plant_Sim.Step (P, Tau);
      end loop;
      E_Final := OSC_PD.Norm (OSC_PD.Error (Plant_Sim.Position (P), Q_Des));
      Put_Line ("  |e|_init=" & Float'Image (E_Init)
                & " |e|_final=" & Float'Image (E_Final));
      Check (E_Init > 0.4, "PD step: initial error is significant");
      Check (E_Final < 0.05, "PD step: final error < 0.05");
      Check (E_Final < 0.2 * E_Init, "PD step: error reduced by >5x");
   end;

   ----------------------------------------------------------------
   --  2. With constant disturbance, adaptive beats PD-only SSE
   ----------------------------------------------------------------
   Put_Line ("=== Adaptive residual vs PD-only under bias ===");
   Err_PD := Run_Closed_Loop
     (Use_Adapt => False, Disturbance => Dist, N_Steps => Steps);
   Err_Adapt := Run_Closed_Loop
     (Use_Adapt => True, Disturbance => Dist, N_Steps => Steps);
   Put_Line ("  |e|_PD=" & Float'Image (Err_PD)
             & " |e|_adapt=" & Float'Image (Err_Adapt));
   Check (Err_PD > 0.08, "disturbance yields noticeable PD SSE");
   Check (Err_Adapt < Err_PD, "adaptive SSE < PD-only SSE");
   Check (Err_Adapt < 0.50 * Err_PD,
          "adaptive cuts SSE by >50% vs PD-only");

   ----------------------------------------------------------------
   --  3. Sanity: zero error → near-zero adapt update
   ----------------------------------------------------------------
   Put_Line ("=== Adaptive_Residual zero-error sanity ===");
   C0 := Adaptive_Residual.Create
     (Learning_Rate => 0.08, Weight_Bound => 4.0, Rate_Bound => 0.05);
   C0.W (1, 1) := 0.5;
   C0.W (2, 2) := -0.3;
   W_Before := Adaptive_Residual.Weight_Max_Abs (C0);
   Phi0 := Adaptive_Residual.Features ([0.1, -0.2], [0.0, 0.0]);
   E0 := [0.0, 0.0];
   Adaptive_Residual.Update (C0, Phi0, E0, Dn_Zero);
   Put_Line ("  delta_norm(e=0)=" & Float'Image (Dn_Zero)
             & " |W|_max=" & Float'Image (W_Before));
   Check (Dn_Zero < 1.0e-6, "zero error -> near-zero weight update");
   Check (abs (Adaptive_Residual.Weight_Max_Abs (C0) - W_Before) < 1.0e-6,
          "weights unchanged when e=0");

   declare
      C_Z : constant Adaptive_Residual.Controller := Adaptive_Residual.Create;
      Tz  : constant JV :=
        Adaptive_Residual.Torque
          (C_Z, Adaptive_Residual.Features ([0.0, 0.0], [0.0, 0.0]));
   begin
      Check (abs (Tz (1)) < 1.0e-9 and then abs (Tz (2)) < 1.0e-9,
             "zero weights -> zero tau_adapt");
   end;

   declare
      P0 : Plant_Sim.Plant := Plant_Sim.Create;
   begin
      Plant_Sim.Step (P0, [0.0, 0.0]);
      Check (abs (Plant_Sim.Position (P0) (1)) < 1.0e-9
             and then abs (Plant_Sim.Position (P0) (2)) < 1.0e-9,
             "plant at rest stays at rest under zero torque");
   end;

   declare
      T0 : constant JV :=
        OSC_PD.Torque (Q_Des, Qd_Des, Q_Des, Qd_Des, G);
   begin
      Check (abs (T0 (1)) < 1.0e-9 and then abs (T0 (2)) < 1.0e-9,
             "PD torque zero at target with qd=0");
   end;

   New_Line;
   Put_Line ("ALL TESTS PASSED:" & Natural'Image (Passes));
end Tests;
