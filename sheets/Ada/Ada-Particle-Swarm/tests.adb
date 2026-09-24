--  Standalone test suite for Particle_Swarm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Particle_Swarm; use Particle_Swarm;

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

   function Box2 (Lo, Hi : Real) return Bounds is
      B : Bounds (1 .. 2);
   begin
      B (1) := (Lo => Lo, Hi => Hi);
      B (2) := (Lo => Lo, Hi => Hi);
      return B;
   end Box2;

   function BoxN (N : Dim_Count; Lo, Hi : Real) return Bounds is
      B : Bounds (1 .. N);
   begin
      for I in B'Range loop
         B (I) := (Lo => Lo, Hi => Hi);
      end loop;
      return B;
   end BoxN;

begin
   Put_Line ("Particle_Swarm test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp / Default_Config");
   ---------------------------------------------------------------------
   declare
      C : Config;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Clamp (0.5, 0.0, 1.0) = 0.5, "Clamp interior");
      Check (Clamp (-1.0, 0.0, 1.0) = 0.0, "Clamp below");
      Check (Clamp (2.0, 0.0, 1.0) = 1.0, "Clamp above");
      Check (Clamp (0.0, 0.0, 1.0) = 0.0, "Clamp at Lo");
      Check (Clamp (1.0, 0.0, 1.0) = 1.0, "Clamp at Hi");
      C := Default_Config;
      Check (C.Swarm_Size = 20, "Default Swarm_Size");
      Check (C.Max_Iterations = 500, "Default Max_Iterations");
      Check (Approx (Real (C.Inertia), 0.729, 1.0E-12), "Default Inertia");
      Check (Approx (Real (C.C1), 1.49445, 1.0E-12), "Default C1");
      Check (Approx (Real (C.C2), 1.49445, 1.0E-12), "Default C2");
      Check (C.Seed = 1, "Default Seed");
      C := Default_Config
        (Swarm_Size => 5, Max_Iterations => 20,
         Inertia => 0.5, C1 => 1.0, C2 => 2.0, Seed => 9);
      Check (C.Swarm_Size = 5 and then C.Seed = 9,
             "Default_Config overrides");
      Check (Approx (Real (C.Inertia), 0.5) and then Approx (Real (C.C2), 2.0),
             "Default_Config inertia/C2");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      X          : Real;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      U3 := Next_Unit (S3);
      Check (U1 = U2, "same seed -> same first draw");
      Check (U1 /= U3, "different seeds differ");
      Check (U1 >= 0.0 and then U1 < 1.0, "U in [0,1)");

      Seed_RNG (S1, 7);
      Seed_RNG (S2, 7);
      for I in 1 .. 40 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         if U1 /= U2 then
            Saw_Diff := True;
         end if;
         if U1 < 0.0 or else U1 >= 1.0 then
            All_In := False;
         end if;
      end loop;
      Check (not Saw_Diff, "same seed stream matches for 40 draws");
      Check (All_In, "40 units stay in [0,1)");

      Seed_RNG (S1, 0);
      U1 := Next_Unit (S1);
      Check (U1 >= 0.0 and then U1 < 1.0, "Seed 0 still valid");

      Seed_RNG (S1, 123);
      X := Next_Uniform (S1, -2.0, 5.0);
      Check (X >= -2.0 and then X <= 5.0, "Next_Uniform in [Lo,Hi]");
      Seed_RNG (S1, 123);
      Check (Approx (Next_Uniform (S1, 3.0, 3.0), 3.0),
             "Next_Uniform Lo=Hi");
   end;

   ---------------------------------------------------------------------
   Section ("3. Objectives Sphere / Rosenbrock / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      Z  : constant Point (1 .. 3) := [0.0, 0.0, 0.0];
      O  : constant Point (1 .. 2) := [1.0, 1.0];
      S1 : constant Point (1 .. 2) := [1.0, 1.0];
      P  : constant Point (1 .. 2) := [0.0, 0.0];
   begin
      Check (Approx (Sphere (Z), 0.0), "Sphere at origin = 0");
      Check (Approx (Sphere (Point'(1 => 3.0)), 9.0), "Sphere (3) = 9");
      Check (Approx (Rosenbrock (O), 0.0), "Rosenbrock at (1,1) = 0");
      Check (Rosenbrock (P) > 0.0, "Rosenbrock at (0,0) > 0");
      Check (Approx (Shifted_Sphere (S1), 0.0), "Shifted_Sphere at ones");
      Check (Shifted_Sphere (Z) > 0.0, "Shifted_Sphere origin > 0");
      Check (Approx (Sphere (Point'(1 => -2.0, 2 => 1.0)), 5.0),
             "Sphere (-2,1) = 5");
      Check (Rosenbrock (Point'(1 => -1.0, 2 => 1.0)) > 0.0,
             "Rosenbrock elsewhere > 0");
      Check (Approx (Shifted_Sphere (Point'(1 => 2.0, 2 => 0.0)), 2.0),
             "Shifted_Sphere (2,0) = 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Init_Swarm / Best / cost consistency");
   ---------------------------------------------------------------------
   declare
      S        : Swarm (8);
      State    : RNG_State;
      B        : constant Bounds := Box2 (-5.0, 5.0);
      All_In   : Boolean := True;
      Costs_Ok : Boolean := True;
      Vel_Ok   : Boolean := True;
      Bi       : Positive;
      Slice    : Point (1 .. 2);
   begin
      Seed_RNG (State, 11);
      Init_Swarm (S, B, Sphere'Access, State);
      Check (S.Size = 8, "Init_Swarm Size = Capacity");
      Check (S.Dim = 2, "Init_Swarm Dim = 2");
      for K in 1 .. S.Size loop
         Check (S.Particles (K).Dim = 2,
                "particle Dim=2 k=" & Integer'Image (K));
         if S.Particles (K).X (1) < -5.0 or else S.Particles (K).X (1) > 5.0
           or else S.Particles (K).X (2) < -5.0
           or else S.Particles (K).X (2) > 5.0
         then
            All_In := False;
         end if;
         --  personal best starts at position
         Check
           (Near (S.Particles (K).P (1), S.Particles (K).X (1), 0.0)
            and then Near (S.Particles (K).P (2), S.Particles (K).X (2), 0.0),
            "p = x after init k=" & Integer'Image (K));
         Slice (1) := S.Particles (K).X (1);
         Slice (2) := S.Particles (K).X (2);
         if not Approx (S.Particles (K).P_Cost, Sphere (Slice), 1.0E-9) then
            Costs_Ok := False;
         end if;
         --  velocity span: box width 10, so |v| <= 10
         if abs (S.Particles (K).V (1)) > 10.0 + 1.0E-9
           or else abs (S.Particles (K).V (2)) > 10.0 + 1.0E-9
         then
            Vel_Ok := False;
         end if;
      end loop;
      Check (All_In, "Init_Swarm positions inside box");
      Check (Costs_Ok, "Init_Swarm P_Cost matches Sphere");
      Check (Vel_Ok, "Init_Swarm velocities in +/- span");
      Bi := Best_Particle_Index (S);
      Check (Bi in 1 .. S.Size, "Best_Particle_Index in range");
      for K in 1 .. S.Size loop
         Check (S.Particles (Bi).P_Cost <= S.Particles (K).P_Cost,
                "best P_Cost <= member k=" & Integer'Image (K));
      end loop;
      Check (Approx (S.G_Cost, S.Particles (Bi).P_Cost, 1.0E-12),
             "G_Cost equals best personal best");
      Check (Near (S.G (1), S.Particles (Bi).P (1), 0.0)
             and then Near (S.G (2), S.Particles (Bi).P (2), 0.0),
             "G equals best personal position");
   end;

   ---------------------------------------------------------------------
   Section ("5. Step stays in bounds / updates bests");
   ---------------------------------------------------------------------
   declare
      S      : Swarm (6);
      State  : RNG_State;
      B      : constant Bounds := Box2 (-1.0, 1.0);
      Cfg    : Config := Default_Config (Swarm_Size => 6, Seed => 33);
      All_In : Boolean := True;
      Init_G : Real;
   begin
      Seed_RNG (State, 33);
      Init_Swarm (S, B, Sphere'Access, State);
      Init_G := S.G_Cost;
      Cfg.Inertia := 0.7;
      Cfg.C1 := 1.5;
      Cfg.C2 := 1.5;
      for I in 1 .. 50 loop
         Step (S, B, Cfg, Sphere'Access, State);
         for K in 1 .. S.Size loop
            if S.Particles (K).X (1) < -1.0 or else S.Particles (K).X (1) > 1.0
              or else S.Particles (K).X (2) < -1.0
              or else S.Particles (K).X (2) > 1.0
            then
               All_In := False;
            end if;
         end loop;
         Check (S.G_Cost <= Init_G + 1.0E-12,
                "G_Cost never worse after step i=" & Integer'Image (I));
      end loop;
      Check (All_In, "50 Steps keep all positions in [-1,1]^2");
      Check (S.G_Cost < Init_G or else S.G_Cost < 0.5,
             "Step improved or already good G_Cost");
   end;

   ---------------------------------------------------------------------
   Section ("6. Step with zero cognitive/social (inertia only)");
   ---------------------------------------------------------------------
   declare
      S     : Swarm (4);
      State : RNG_State;
      B     : constant Bounds := Box2 (0.0, 1.0);
      Cfg   : Config := Default_Config (Swarm_Size => 4);
      All_In : Boolean := True;
      Saved_X1 : Real;
      Saved_V1 : Real;
   begin
      Seed_RNG (State, 44);
      Init_Swarm (S, B, Sphere'Access, State);
      Cfg.Inertia := 0.5;
      Cfg.C1 := 0.0;
      Cfg.C2 := 0.0;
      Saved_X1 := S.Particles (1).X (1);
      Saved_V1 := S.Particles (1).V (1);
      Step (S, B, Cfg, Sphere'Access, State);
      --  With c1=c2=0: v' = w v, x' = clamp(x + w v)
      Check
        (Approx (S.Particles (1).V (1), 0.5 * Saved_V1, 1.0E-12),
         "C1=C2=0 velocity is w*v");
      Check
        (Approx
           (S.Particles (1).X (1),
            Clamp (Saved_X1 + 0.5 * Saved_V1, 0.0, 1.0),
            1.0E-12),
         "C1=C2=0 position update");
      for I in 1 .. 20 loop
         Step (S, B, Cfg, Sphere'Access, State);
         for K in 1 .. S.Size loop
            if S.Particles (K).X (1) < 0.0 or else S.Particles (K).X (1) > 1.0
              or else S.Particles (K).X (2) < 0.0
              or else S.Particles (K).X (2) > 1.0
            then
               All_In := False;
            end if;
         end loop;
      end loop;
      Check (All_In, "inertia-only Steps stay in bounds");
   end;

   ---------------------------------------------------------------------
   Section ("7. Minimize_Box Sphere improves + reproducibility");
   ---------------------------------------------------------------------
   declare
      B   : constant Bounds := BoxN (3, -5.0, 5.0);
      Cfg : Config :=
        Default_Config
          (Swarm_Size => 16, Max_Iterations => 200,
           Inertia => 0.729, C1 => 1.49445, C2 => 1.49445, Seed => 100);
      R1, R2, R3 : Result;
      Init_Best  : Real;
      S          : Swarm (16);
      State      : RNG_State;
   begin
      Seed_RNG (State, 100);
      Init_Swarm (S, B, Sphere'Access, State);
      Init_Best := S.G_Cost;

      R1 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R1.Dim = 3, "Sphere Result Dim=3");
      Check (R1.Iterations = 200, "Sphere Iterations=200");
      Check (R1.Swarm_Used = 16, "Sphere Swarm_Used=16");
      Check (R1.Best_Cost < Init_Best, "Sphere improves vs initial G");
      Check (R1.Best_Cost < 0.5, "Sphere Best_Cost < 0.5");
      Check (R1.Best_X (1) >= -5.0 and then R1.Best_X (1) <= 5.0,
             "Sphere X1 in box");
      Check (R1.Best_X (2) >= -5.0 and then R1.Best_X (2) <= 5.0,
             "Sphere X2 in box");
      Check (R1.Best_X (3) >= -5.0 and then R1.Best_X (3) <= 5.0,
             "Sphere X3 in box");
      Check (Approx (R1.Best_Cost, Sphere (R1.Best_X (1 .. 3)), 1.0E-9),
             "Sphere Best_Cost matches Best_X");

      R2 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (Approx (R1.Best_Cost, R2.Best_Cost, 0.0),
             "same seed -> same Best_Cost");
      Check (Near (R1.Best_X (1), R2.Best_X (1), 0.0)
             and then Near (R1.Best_X (2), R2.Best_X (2), 0.0)
             and then Near (R1.Best_X (3), R2.Best_X (3), 0.0),
             "same seed -> same Best_X");

      Cfg.Seed := 101;
      R3 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R3.Best_Cost /= R1.Best_Cost
             or else not Near (R3.Best_X (1), R1.Best_X (1), 0.0),
             "different seed usually differs");

      --  Max_Iterations = 0 returns best of initial swarm only
      Cfg.Seed := 100;
      Cfg.Max_Iterations := 0;
      R1 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R1.Iterations = 0, "zero iterations reported");
      Check (Approx (R1.Best_Cost, Init_Best, 1.0E-9),
             "zero iters = initial swarm best");
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize_Box Rosenbrock / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      B   : constant Bounds := Box2 (-2.0, 2.0);
      Cfg : Config :=
        Default_Config
          (Swarm_Size => 24, Max_Iterations => 400,
           Inertia => 0.729, C1 => 1.49445, C2 => 1.49445, Seed => 7);
      R   : Result;
      Bs  : constant Bounds := BoxN (2, -1.0, 3.0);
   begin
      R := Minimize_Box (Rosenbrock'Access, B, Cfg);
      Check (R.Dim = 2, "Rosenbrock Dim=2");
      Check (R.Best_Cost < 5.0, "Rosenbrock Best_Cost < 5");
      Check (R.Best_X (1) >= -2.0 and then R.Best_X (1) <= 2.0,
             "Rosenbrock X in box");
      Check (R.Iterations = 400, "Rosenbrock iterations");

      Cfg.Max_Iterations := 250;
      Cfg.Seed := 8;
      R := Minimize_Box (Shifted_Sphere'Access, Bs, Cfg);
      Check (R.Best_Cost < 0.2, "Shifted_Sphere Best_Cost < 0.2");
      Check (Near (R.Best_X (1), 1.0, 0.4)
             and then Near (R.Best_X (2), 1.0, 0.4),
             "Shifted_Sphere near (1,1)");
      Check (Approx (R.Best_Cost,
                     Shifted_Sphere (R.Best_X (1 .. 2)), 1.0E-9),
             "Shifted_Sphere cost matches X");
   end;

   ---------------------------------------------------------------------
   Section ("9. Extra Sphere dims / config smoke");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      for D in Dim_Count loop
         Cfg := Default_Config
           (Swarm_Size => 12, Max_Iterations => 80,
            Inertia => 0.7, C1 => 1.5, C2 => 1.5, Seed => 200 + D);
         R := Minimize_Box (Sphere'Access, BoxN (D, -1.0, 1.0), Cfg);
         Check (R.Dim = D, "Sphere dim D=" & Dim_Count'Image (D));
         Check (R.Best_Cost < 1.0,
                "Sphere cost ok D=" & Dim_Count'Image (D));
         Check (R.Iterations = 80,
                "Sphere iters D=" & Dim_Count'Image (D));
         Check (R.Swarm_Used = 12,
                "Sphere swarm D=" & Dim_Count'Image (D));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Edge configs / clamping / exceptions smoke");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
      B   : constant Bounds := Box2 (-0.5, 0.5);
      Raised : Boolean;
   begin
      Cfg := Default_Config
        (Swarm_Size => 8, Max_Iterations => 60,
         Inertia => 0.0, C1 => 2.0, C2 => 2.0, Seed => 3);
      R := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R.Best_Cost < 0.5, "Inertia=0 still finds low Sphere");
      Check (R.Best_X (1) >= -0.5 and then R.Best_X (1) <= 0.5,
             "Inertia=0 X1 clamped");

      Cfg.Inertia := 1.0;
      Cfg.C1 := 0.0;
      Cfg.C2 := 2.5;
      Cfg.Seed := 4;
      R := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R.Best_Cost <= 1.0, "social-only still valid");

      Cfg := Default_Config (Swarm_Size => 5, Max_Iterations => 30, Seed => 5);
      R := Minimize_Box (Sphere'Access, BoxN (1, -2.0, 2.0), Cfg);
      Check (R.Dim = 1, "1-D Sphere Dim");
      Check (R.Best_Cost < 0.5, "1-D Sphere cost");

      Raised := False;
      begin
         declare
            Bad : constant Bounds (1 .. 2) :=
              [(Lo => 1.0, Hi => 0.0), (Lo => -1.0, Hi => 1.0)];
            Unused : Result;
         begin
            Unused := Minimize_Box
              (Sphere'Access, Bad,
               Default_Config (Swarm_Size => 3, Max_Iterations => 1));
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "inverted bounds raise Invalid_Argument");

      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Rosenbrock (Point'(1 => 0.0));
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock Dim<2 raises Invalid_Argument");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Result: Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES (but Pass_Count < 100)");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

end Tests;
