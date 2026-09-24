--  Standalone test suite for Constraint_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Constraint_Algorithm; use Constraint_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Vec_Near (A, B : Vec3; Tol : Real := 1.0E-6) return Boolean is
   begin
      return Approx (A.X, B.X, Tol)
        and then Approx (A.Y, B.Y, Tol)
        and then Approx (A.Z, B.Z, Tol);
   end Vec_Near;

   Cfg : constant Solver_Config := Default_Config;

begin
   Put_Line ("Constraint_Algorithm test suite (SHAKE / RATTLE)");
   Put_Line ("=================================================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Vec / Norm / Dot");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (not Near (1.0, 2.0), "Near far");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (Approx (Dot ((1.0, 2.0, 3.0), (4.0, 5.0, 6.0)), 32.0, 1.0E-12),
          "Dot 1+2+3");
   Check (Approx (Norm2 ((3.0, 4.0, 0.0)), 25.0, 1.0E-12), "Norm2 3-4-0");
   Check (Approx (Norm ((3.0, 4.0, 0.0)), 5.0, 1.0E-12), "Norm 3-4-0");
   Check (Approx (Norm ((0.0, 0.0, 0.0)), 0.0), "Norm origin");
   Check (Approx (Distance ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0)), 1.0, 1.0E-12),
          "Distance unit X");
   declare
      S : constant Vec3 := Vec_Add ((1.0, 2.0, 3.0), (4.0, 5.0, 6.0));
      D : constant Vec3 := Vec_Sub ((5.0, 5.0, 5.0), (1.0, 2.0, 3.0));
      K : constant Vec3 := Vec_Scale ((2.0, -1.0, 0.5), 3.0);
   begin
      Check (Vec_Near (S, (5.0, 7.0, 9.0)), "Vec_Add");
      Check (Vec_Near (D, (4.0, 3.0, 2.0)), "Vec_Sub");
      Check (Vec_Near (K, (6.0, -3.0, 1.5)), "Vec_Scale");
   end;
   Check (Default_Config.Tol > 0.0, "Default_Config Tol > 0");
   Check (Default_Config.Max_Iters > 0, "Default_Config Max_Iters > 0");
   Check (Default_Config.Use_Reference, "Default_Config Use_Reference");

   ---------------------------------------------------------------------
   Section ("2. Make_Diatomic / Constraint_Value");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
   begin
      Make_Diatomic (1.0, 1.0, 1.5, P, NP, C, NC);
      Check (NP = 2, "diatomic N_Part=2");
      Check (NC = 1, "diatomic N_Cons=1");
      Check (Approx (Bond_Length (P, C (1)), 1.5, 1.0E-12), "diatomic length");
      Check (Approx (Constraint_Value (P, C (1)), 0.0, 1.0E-12),
             "diatomic g=0");
      Check (Approx (Constraint_Violation_Max (P, C, NP, NC), 0.0, 1.0E-12),
             "diatomic max|g|=0");
      Check (Approx (Total_Mass (P, NP), 2.0, 1.0E-12), "diatomic mass sum");
      Check (Vec_Near (Linear_Momentum (P, NP), (0.0, 0.0, 0.0)),
             "diatomic P=0 at rest");
   end;

   ---------------------------------------------------------------------
   Section ("3. SHAKE restores single bond from perturbation");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (2).Pos.X := 1.2;  -- stretch
      Check (abs (Constraint_Value (P, C (1))) > 1.0E-3, "pre-SHAKE violated");
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "SHAKE converged (stretch)");
      Check (R.Iterations >= 1, "SHAKE did work");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-8),
             "SHAKE restored length after stretch");
      Check (R.Final_Max_G <= Cfg.Tol, "SHAKE final |g| <= tol");
   end;
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (2).Pos.X := 0.7;  -- compress
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "SHAKE converged (compress)");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-8),
             "SHAKE restored length after compress");
   end;

   ---------------------------------------------------------------------
   Section ("4. SHAKE unchanged when already satisfied");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      Pos1, Pos2 : Vec3;
   begin
      Make_Diatomic (2.0, 3.0, 1.25, P, NP, C, NC);
      Pos1 := P (1).Pos;
      Pos2 := P (2).Pos;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "already-ok SHAKE converged");
      Check (R.Iterations = 1, "already-ok SHAKE one sweep");
      Check (Vec_Near (P (1).Pos, Pos1, 1.0E-12), "pos1 unchanged");
      Check (Vec_Near (P (2).Pos, Pos2, 1.0E-12), "pos2 unchanged");
   end;

   ---------------------------------------------------------------------
   Section ("5. Mass weighting: heavy particle moves less");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      Dx_Heavy, Dx_Light : Real;
   begin
      Make_Diatomic (100.0, 1.0, 1.0, P, NP, C, NC);
      P (2).Pos.X := 1.1;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "mass-weight SHAKE converged");
      Dx_Heavy := abs (P (1).Pos.X - 0.0);
      Dx_Light := abs (P (2).Pos.X - 1.1);
      Check (Dx_Heavy < Dx_Light, "heavy particle displaced less");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-8),
             "mass-weight length restored");
   end;

   ---------------------------------------------------------------------
   Section ("6. RATTLE zeros stretch rate");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Rattle_Result;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (1).Vel := (0.5, 0.0, 0.0);
      P (2).Vel := (-0.3, 0.1, 0.0);  -- nonzero stretch
      Check (abs (Constraint_Dot (P, C (1))) > 1.0E-6, "pre-RATTLE gdot != 0");
      Rattle_Velocities (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "RATTLE converged");
      Check (Approx (Constraint_Dot (P, C (1)), 0.0, 1.0E-9),
             "RATTLE zeros gdot");
      Check (R.Final_Max_GDot <= Cfg.Tol, "RATTLE final |gdot| <= tol");
   end;

   ---------------------------------------------------------------------
   Section ("7. RATTLE preserves linear momentum");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Rattle_Result;
      P_Before, P_After : Vec3;
   begin
      Make_Diatomic (2.0, 3.0, 1.0, P, NP, C, NC);
      P (1).Vel := (0.4, -0.2, 0.1);
      P (2).Vel := (-0.1, 0.3, -0.05);
      P_Before := Linear_Momentum (P, NP);
      Rattle_Velocities (P, C, NP, NC, Cfg, R);
      P_After := Linear_Momentum (P, NP);
      Check (R.Converged, "momentum RATTLE converged");
      Check (Vec_Near (P_Before, P_After, 1.0E-10),
             "RATTLE preserves Σ m v");
      Check (Approx (Constraint_Dot (P, C (1)), 0.0, 1.0E-9),
             "RATTLE gdot=0 after momentum check");
   end;

   ---------------------------------------------------------------------
   Section ("8. SHAKE roughly preserves COM / no spurious COM jump");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      Com_B, Com_A : Vec3;
      Mtot : Real;
   begin
      Make_Diatomic (2.0, 2.0, 1.0, P, NP, C, NC);
      P (2).Pos := (1.15, 0.05, -0.02);
      Mtot := Real (Total_Mass (P, NP));
      Com_B := Vec_Scale
        (Vec_Add (Vec_Scale (P (1).Pos, 2.0), Vec_Scale (P (2).Pos, 2.0)),
         1.0 / Mtot);
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Com_A := Vec_Scale
        (Vec_Add (Vec_Scale (P (1).Pos, 2.0), Vec_Scale (P (2).Pos, 2.0)),
         1.0 / Mtot);
      Check (R.Converged, "COM SHAKE converged");
      Check (Vec_Near (Com_B, Com_A, 1.0E-9), "SHAKE preserves COM");
   end;

   ---------------------------------------------------------------------
   Section ("9. Two-bond chain");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
   begin
      Make_Two_Bond_Chain (1.0, P, NP, C, NC);
      Check (NP = 3, "chain N_Part=3");
      Check (NC = 2, "chain N_Cons=2");
      Check (Approx (Constraint_Violation_Max (P, C, NP, NC), 0.0, 1.0E-12),
             "chain initially satisfied");
      P (2).Pos.Y := 0.2;
      P (3).Pos.X := 2.3;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "chain SHAKE converged");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-7), "chain bond1");
      Check (Approx (Bond_Length (P, C (2)), 1.0, 1.0E-7), "chain bond2");
      Check (Constraint_Violation_Max (P, C, NP, NC) <= Cfg.Tol,
             "chain max|g|<=tol");
   end;

   ---------------------------------------------------------------------
   Section ("10. Water-like 3-site rigid");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      OH : constant Positive_Real := 0.9572;
      HH : constant Positive_Real := 1.5139;
   begin
      Make_Water_Like (OH, HH, P, NP, C, NC);
      Check (NP = 3, "water N_Part=3");
      Check (NC = 3, "water N_Cons=3");
      Check (Approx (Bond_Length (P, C (1)), Real (OH), 1.0E-10), "water OH1");
      Check (Approx (Bond_Length (P, C (2)), Real (OH), 1.0E-10), "water OH2");
      Check (Approx (Bond_Length (P, C (3)), Real (HH), 1.0E-10), "water HH");
      Perturb_Positions (P, NP, 0.05, Seed => 7);
      Check (Constraint_Violation_Max (P, C, NP, NC) > 1.0E-4,
             "water perturbed");
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "water SHAKE converged");
      Check (Approx (Bond_Length (P, C (1)), Real (OH), 1.0E-6),
             "water OH1 restored");
      Check (Approx (Bond_Length (P, C (2)), Real (OH), 1.0E-6),
             "water OH2 restored");
      Check (Approx (Bond_Length (P, C (3)), Real (HH), 1.0E-6),
             "water HH restored");
   end;

   ---------------------------------------------------------------------
   Section ("11. Water RATTLE on all three constraints");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Rattle_Result;
      P0, P1 : Vec3;
   begin
      Make_Water_Like (1.0, 1.5, P, NP, C, NC);
      P (1).Vel := (0.1, 0.0, 0.0);
      P (2).Vel := (0.0, 0.2, -0.1);
      P (3).Vel := (-0.05, 0.0, 0.15);
      P0 := Linear_Momentum (P, NP);
      Rattle_Velocities (P, C, NP, NC, Cfg, R);
      P1 := Linear_Momentum (P, NP);
      Check (R.Converged, "water RATTLE converged");
      Check (Velocity_Violation_Max (P, C, NP, NC) <= Cfg.Tol,
             "water all gdot ~ 0");
      Check (Vec_Near (P0, P1, 1.0E-9), "water RATTLE preserves P");
   end;

   ---------------------------------------------------------------------
   Section ("12. Random perturbations within tol (SHAKE)");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      All_Ok : Boolean := True;
   begin
      for Seed in 1 .. 12 loop
         Make_Diatomic (1.0, 1.5, 0.9, P, NP, C, NC);
         Perturb_Positions (P, NP, 0.08, Seed => Seed);
         Shake_Positions (P, C, NP, NC, Cfg, R);
         if not R.Converged
           or else not Approx (Bond_Length (P, C (1)), 0.9, 1.0E-6)
         then
            All_Ok := False;
         end if;
         Check (R.Converged,
                "random SHAKE seed" & Integer'Image (Seed) & " conv");
         Check (Approx (Bond_Length (P, C (1)), 0.9, 1.0E-6),
                "random SHAKE seed" & Integer'Image (Seed) & " length");
      end loop;
      Check (All_Ok, "all 12 random SHAKE trials ok");
   end;

   ---------------------------------------------------------------------
   Section ("13. Iteration count / convergence behavior");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R_Loose, R_Tight : Shake_Result;
      Loose : Solver_Config := Cfg;
      Tight : Solver_Config := Cfg;
   begin
      Loose.Tol := 1.0E-4;
      Tight.Tol := 1.0E-12;
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (2).Pos.X := 1.25;
      Shake_Positions (P, C, NP, NC, Loose, R_Loose);
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (2).Pos.X := 1.25;
      Shake_Positions (P, C, NP, NC, Tight, R_Tight);
      Check (R_Loose.Converged, "loose tol converged");
      Check (R_Tight.Converged, "tight tol converged");
      Check (R_Tight.Iterations >= R_Loose.Iterations,
             "tighter tol needs >= iterations");
      Check (R_Loose.Final_Max_G <= Loose.Tol, "loose final ok");
      Check (R_Tight.Final_Max_G <= Tight.Tol, "tight final ok");
   end;

   ---------------------------------------------------------------------
   Section ("14. Use_Reference False still converges");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      Cfg2 : Solver_Config := Cfg;
   begin
      Cfg2.Use_Reference := False;
      Make_Two_Bond_Chain (1.0, P, NP, C, NC);
      Perturb_Positions (P, NP, 0.04, Seed => 3);
      Shake_Positions (P, C, NP, NC, Cfg2, R);
      Check (R.Converged, "non-ref SHAKE converged");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-6), "non-ref bond1");
      Check (Approx (Bond_Length (P, C (2)), 1.0, 1.0E-6), "non-ref bond2");
   end;

   ---------------------------------------------------------------------
   Section ("15. Velocity-Verlet constrained free flight");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      SR : Step_Result;
      P0, P1 : Vec3;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      --  Rigid translation + slight stretch tendency
      P (1).Vel := (0.2, 0.1, 0.0);
      P (2).Vel := (0.2, 0.1, 0.05);
      P0 := Linear_Momentum (P, NP);
      Velocity_Verlet_Constrained_Step
        (P, C, NP, NC, 0.01, Cfg, SR);
      P1 := Linear_Momentum (P, NP);
      Check (SR.Shake.Converged, "VV step SHAKE converged");
      Check (SR.Rattle.Converged, "VV step RATTLE converged");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-7),
             "VV step bond length");
      Check (Approx (Constraint_Dot (P, C (1)), 0.0, 1.0E-8),
             "VV step gdot=0");
      Check (Vec_Near (P0, P1, 1.0E-8), "VV step momentum");
   end;

   --  Multi-step free flight with water
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      SR : Step_Result;
      Ok : Boolean := True;
   begin
      Make_Water_Like (1.0, 1.6, P, NP, C, NC);
      P (1).Vel := (0.05, 0.0, 0.0);
      P (2).Vel := (0.05, 0.02, 0.0);
      P (3).Vel := (0.05, -0.01, 0.01);
      Rattle_Velocities (P, C, NP, NC, Cfg, SR.Rattle);
      for Step in 1 .. 20 loop
         Velocity_Verlet_Constrained_Step
           (P, C, NP, NC, 0.005, Cfg, SR);
         if not SR.Shake.Converged
           or else not SR.Rattle.Converged
           or else Constraint_Violation_Max (P, C, NP, NC) > 1.0E-6
           or else Velocity_Violation_Max (P, C, NP, NC) > 1.0E-6
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "20-step water free flight constraints held");
      Check (Approx (Bond_Length (P, C (1)), 1.0, 1.0E-5), "flight OH1");
      Check (Approx (Bond_Length (P, C (2)), 1.0, 1.0E-5), "flight OH2");
      Check (Approx (Bond_Length (P, C (3)), 1.6, 1.0E-5), "flight HH");
   end;

   ---------------------------------------------------------------------
   Section ("16. Edge cases");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      Rr : Rattle_Result;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      NC := 0;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "empty constraints SHAKE ok");
      Check (R.Iterations = 0, "empty SHAKE zero iters");
      Rattle_Velocities (P, C, NP, NC, Cfg, Rr);
      Check (Rr.Converged, "empty constraints RATTLE ok");
      Check (Rr.Iterations = 0, "empty RATTLE zero iters");
   end;

   --  Orthogonal velocity already satisfies gdot=0
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Rattle_Result;
      V1, V2 : Vec3;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (1).Vel := (0.0, 1.0, 0.0);  -- perpendicular to bond (x-axis)
      P (2).Vel := (0.0, 1.0, 0.0);
      Check (Approx (Constraint_Dot (P, C (1)), 0.0, 1.0E-12),
             "perp velocity already gdot=0");
      V1 := P (1).Vel;
      V2 := P (2).Vel;
      Rattle_Velocities (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "perp RATTLE converged");
      Check (Vec_Near (P (1).Vel, V1, 1.0E-12), "perp vel1 unchanged");
      Check (Vec_Near (P (2).Vel, V2, 1.0E-12), "perp vel2 unchanged");
   end;

   --  Large equal masses
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
   begin
      Make_Diatomic (1.0E6, 1.0E6, 2.0, P, NP, C, NC);
      P (2).Pos.X := 2.1;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "heavy equal masses SHAKE");
      Check (Approx (Bond_Length (P, C (1)), 2.0, 1.0E-6),
             "heavy equal length");
   end;

   ---------------------------------------------------------------------
   Section ("17. More SHAKE / RATTLE spot checks");
   ---------------------------------------------------------------------
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      Rr : Rattle_Result;
   begin
      Make_Two_Bond_Chain (0.75, P, NP, C, NC);
      Check (Approx (Bond_Length (P, C (1)), 0.75, 1.0E-12), "chain0.75 b1");
      Check (Approx (Bond_Length (P, C (2)), 0.75, 1.0E-12), "chain0.75 b2");
      P (1).Pos.Z := 0.1;
      P (3).Pos.Y := -0.08;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "3D-perturb chain SHAKE");
      Check (Approx (Bond_Length (P, C (1)), 0.75, 1.0E-6), "3D chain b1");
      Check (Approx (Bond_Length (P, C (2)), 0.75, 1.0E-6), "3D chain b2");

      P (1).Vel := (0.3, -0.2, 0.1);
      P (2).Vel := (0.0, 0.4, 0.0);
      P (3).Vel := (-0.1, 0.0, 0.2);
      Rattle_Velocities (P, C, NP, NC, Cfg, Rr);
      Check (Rr.Converged, "chain RATTLE");
      Check (Velocity_Violation_Max (P, C, NP, NC) <= Cfg.Tol,
             "chain velocity constraints");
   end;

   --  Constraint_Value sign: stretched => positive g
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (2).Pos.X := 1.5;
      Check (Constraint_Value (P, C (1)) > 0.0, "stretched g > 0");
      P (2).Pos.X := 0.5;
      Check (Constraint_Value (P, C (1)) < 0.0, "compressed g < 0");
   end;

   --  Several unequal-mass diatomic RATTLE trials
   for Seed in 1 .. 8 loop
      declare
         P : Particle_Array (1 .. Max_Particles);
         C : Constraint_Array (1 .. Max_Constraints);
         NP : Particle_Count;
         NC : Constraint_Count;
         R  : Rattle_Result;
         P0 : Vec3;
      begin
         Make_Diatomic (1.0, 4.0, 1.1, P, NP, C, NC);
         Perturb_Positions (P, NP, 0.0, Seed => Seed);  -- advance RNG only
         --  Set velocities from seed-ish values
         P (1).Vel :=
           (0.1 * Real (Seed), -0.05 * Real (Seed), 0.02 * Real (Seed));
         P (2).Vel :=
           (-0.03 * Real (Seed), 0.07 * Real (Seed), -0.01 * Real (Seed));
         P0 := Linear_Momentum (P, NP);
         Rattle_Velocities (P, C, NP, NC, Cfg, R);
         Check (R.Converged,
                "unequal RATTLE seed" & Integer'Image (Seed));
         Check (Approx (Constraint_Dot (P, C (1)), 0.0, 1.0E-8),
                "unequal gdot seed" & Integer'Image (Seed));
         Check (Vec_Near (P0, Linear_Momentum (P, NP), 1.0E-9),
                "unequal P seed" & Integer'Image (Seed));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("18. Norm / Distance extras + config copy");
   ---------------------------------------------------------------------
   Check (Approx (Norm ((0.0, 0.0, 5.0)), 5.0, 1.0E-12), "Norm z-axis");
   Check (Approx (Distance ((1.0, 1.0, 1.0), (1.0, 1.0, 1.0)), 0.0),
          "Distance coincident");
   Check (Approx (Norm2 ((1.0, 1.0, 1.0)), 3.0, 1.0E-12), "Norm2 ones");
   declare
      C2 : constant Solver_Config :=
        (Tol => 1.0E-8, Max_Iters => 100, Use_Reference => False);
   begin
      Check (C2.Tol = 1.0E-8, "custom Tol");
      Check (C2.Max_Iters = 100, "custom Max_Iters");
      Check (not C2.Use_Reference, "custom Use_Reference False");
   end;

   --  SHAKE does not alter velocities
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      R  : Shake_Result;
      V1, V2 : Vec3;
   begin
      Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
      P (1).Vel := (1.0, 2.0, 3.0);
      P (2).Vel := (4.0, 5.0, 6.0);
      V1 := P (1).Vel;
      V2 := P (2).Vel;
      P (2).Pos.X := 1.2;
      Shake_Positions (P, C, NP, NC, Cfg, R);
      Check (R.Converged, "vel-preserve SHAKE");
      Check (Vec_Near (P (1).Vel, V1), "SHAKE leaves v1");
      Check (Vec_Near (P (2).Vel, V2), "SHAKE leaves v2");
   end;

   --  Final water geometry sanity after combined SHAKE+RATTLE
   declare
      P : Particle_Array (1 .. Max_Particles);
      C : Constraint_Array (1 .. Max_Constraints);
      NP : Particle_Count;
      NC : Constraint_Count;
      Rs : Shake_Result;
      Rr : Rattle_Result;
   begin
      Make_Water_Like (0.96, 1.51, P, NP, C, NC);
      Perturb_Positions (P, NP, 0.03, Seed => 99);
      P (1).Vel := (0.2, -0.1, 0.05);
      P (2).Vel := (-0.1, 0.15, 0.0);
      P (3).Vel := (0.05, 0.0, -0.1);
      Shake_Positions (P, C, NP, NC, Cfg, Rs);
      Rattle_Velocities (P, C, NP, NC, Cfg, Rr);
      Check (Rs.Converged and then Rr.Converged, "combined water ok");
      Check (Constraint_Violation_Max (P, C, NP, NC) <= Cfg.Tol,
             "combined pos constraints");
      Check (Velocity_Violation_Max (P, C, NP, NC) <= Cfg.Tol,
             "combined vel constraints");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   Put_Line ("========================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
