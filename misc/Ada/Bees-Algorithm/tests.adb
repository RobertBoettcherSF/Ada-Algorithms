--  Standalone test suite for Bees_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bees_Algorithm; use Bees_Algorithm;

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
   Put_Line ("Bees_Algorithm test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp / Default_Config / Config_Is_Valid");
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
      Check (C.N = 20, "Default N");
      Check (C.M = 5, "Default M");
      Check (C.E = 2, "Default E");
      Check (C.Nep = 10, "Default Nep");
      Check (C.Nsp = 5, "Default Nsp");
      Check (Approx (Real (C.Ngh), 0.5, 1.0E-12), "Default Ngh");
      Check (C.Max_Iterations = 500, "Default Max_Iterations");
      Check (C.Seed = 1, "Default Seed");
      Check (Config_Is_Valid (C), "Default Config_Is_Valid");
      C := Default_Config
        (N => 12, M => 4, E => 1, Nep => 8, Nsp => 3,
         Ngh => 0.25, Max_Iterations => 40, Seed => 9);
      Check (C.N = 12 and then C.Seed = 9, "Default_Config overrides N/Seed");
      Check (C.M = 4 and then C.E = 1, "Default_Config overrides M/E");
      Check (Approx (Real (C.Ngh), 0.25), "Default_Config Ngh");
      Check (Config_Is_Valid (C), "override Config_Is_Valid");
      C.E := 5;
      C.M := 4;
      Check (not Config_Is_Valid (C), "E>M invalid");
      C.E := 2;
      C.M := 15;
      C.N := 10;
      Check (not Config_Is_Valid (C), "M>N invalid");
      C := Default_Config (N => 5, M => 5, E => 5);
      Check (Config_Is_Valid (C), "E=M=N valid");
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
   Section ("4. Init_Colony / Best / cost consistency");
   ---------------------------------------------------------------------
   declare
      C        : Colony (8);
      State    : RNG_State;
      B        : constant Bounds := Box2 (-5.0, 5.0);
      All_In   : Boolean := True;
      Costs_Ok : Boolean := True;
      Bi       : Positive;
      Slice    : Point (1 .. 2);
   begin
      Seed_RNG (State, 11);
      Init_Colony (C, B, Sphere'Access, State);
      Check (C.Size = 8, "Init_Colony Size = Capacity");
      Check (C.Dim = 2, "Init_Colony Dim = 2");
      for K in 1 .. C.Size loop
         Check (C.Bees (K).Dim = 2,
                "bee Dim=2 k=" & Integer'Image (K));
         if C.Bees (K).X (1) < -5.0 or else C.Bees (K).X (1) > 5.0
           or else C.Bees (K).X (2) < -5.0
           or else C.Bees (K).X (2) > 5.0
         then
            All_In := False;
         end if;
         Slice (1) := C.Bees (K).X (1);
         Slice (2) := C.Bees (K).X (2);
         if not Approx (C.Bees (K).Cost, Sphere (Slice), 1.0E-9) then
            Costs_Ok := False;
         end if;
      end loop;
      Check (All_In, "Init_Colony positions inside box");
      Check (Costs_Ok, "Init_Colony Cost matches Sphere");
      Bi := Best_Index (C);
      Check (Bi in 1 .. C.Size, "Best_Index in range");
      for K in 1 .. C.Size loop
         Check (C.Bees (Bi).Cost <= C.Bees (K).Cost,
                "best Cost <= member k=" & Integer'Image (K));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Rank_Colony ordering");
   ---------------------------------------------------------------------
   declare
      C     : Colony (5);
      State : RNG_State;
      B     : constant Bounds := Box2 (-2.0, 2.0);
      Ordered : Boolean := True;
   begin
      Seed_RNG (State, 21);
      Init_Colony (C, B, Sphere'Access, State);
      Rank_Colony (C);
      Check (C.Size = 5, "Rank keeps Size");
      for K in 1 .. C.Size - 1 loop
         if C.Bees (K).Cost > C.Bees (K + 1).Cost then
            Ordered := False;
         end if;
      end loop;
      Check (Ordered, "Rank ascending by Cost");
      Check (Best_Index (C) = 1, "after Rank Best_Index = 1");
      --  Rank again is idempotent on order
      Rank_Colony (C);
      Ordered := True;
      for K in 1 .. C.Size - 1 loop
         if C.Bees (K).Cost > C.Bees (K + 1).Cost then
            Ordered := False;
         end if;
      end loop;
      Check (Ordered, "Rank idempotent order");
   end;

   ---------------------------------------------------------------------
   Section ("6. Patch_Search improves or keeps center");
   ---------------------------------------------------------------------
   declare
      State  : RNG_State;
      B      : constant Bounds := Box2 (-5.0, 5.0);
      Center : Bee;
      Best   : Bee;
      All_In : Boolean := True;
   begin
      Center.Dim := 2;
      Center.X := [others => 0.0];
      Center.X (1) := 3.0;
      Center.X (2) := -2.0;
      Center.Cost := Sphere (Center.X (1 .. 2));

      Seed_RNG (State, 31);
      Best := Patch_Search
        (Center, 1.0, 20, B, Sphere'Access, State);
      Check (Best.Cost <= Center.Cost + 1.0E-12,
             "Patch_Search never worse than center");
      Check (Best.Dim = 2, "Patch_Search Dim=2");
      Check (Best.X (1) >= -5.0 and then Best.X (1) <= 5.0,
             "Patch_Search X1 in box");
      Check (Best.X (2) >= -5.0 and then Best.X (2) <= 5.0,
             "Patch_Search X2 in box");
      Check (Approx (Best.Cost, Sphere (Best.X (1 .. 2)), 1.0E-9),
             "Patch_Search cost matches X");

      --  Ngh=0: only center (foragers collapse to center)
      Seed_RNG (State, 32);
      Best := Patch_Search
        (Center, 0.0, 5, B, Sphere'Access, State);
      Check (Approx (Best.Cost, Center.Cost, 1.0E-12),
             "Ngh=0 Patch_Search keeps center cost");
      Check (Near (Best.X (1), Center.X (1), 1.0E-12)
             and then Near (Best.X (2), Center.X (2), 1.0E-12),
             "Ngh=0 Patch_Search keeps center X");

      --  Many foragers near origin should improve far center
      Center.X (1) := 4.0;
      Center.X (2) := 4.0;
      Center.Cost := Sphere (Center.X (1 .. 2));
      Seed_RNG (State, 33);
      Best := Patch_Search
        (Center, 3.0, 30, B, Sphere'Access, State);
      Check (Best.Cost < Center.Cost, "Patch_Search improves far Sphere site");
      for T in 1 .. 15 loop
         Seed_RNG (State, 100 + T);
         Best := Patch_Search
           (Center, 2.0, 10, B, Sphere'Access, State);
         if Best.X (1) < -5.0 or else Best.X (1) > 5.0
           or else Best.X (2) < -5.0 or else Best.X (2) > 5.0
         then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "15 Patch_Searches stay in box");
   end;

   ---------------------------------------------------------------------
   Section ("7. Step ranks / updates / global re-scout");
   ---------------------------------------------------------------------
   declare
      C      : Colony (10);
      State  : RNG_State;
      B      : constant Bounds := Box2 (-1.0, 1.0);
      Cfg    : constant Config :=
        Default_Config
          (N => 10, M => 4, E => 2, Nep => 8, Nsp => 4,
           Ngh => 0.3, Max_Iterations => 1, Seed => 41);
      All_In : Boolean := True;
      Init_Best : Real;
      Ordered : Boolean;
   begin
      Seed_RNG (State, 41);
      Init_Colony (C, B, Sphere'Access, State);
      Init_Best := C.Bees (Best_Index (C)).Cost;
      for I in 1 .. 40 loop
         Step (C, B, Cfg, Sphere'Access, State);
         for K in 1 .. C.Size loop
            if C.Bees (K).X (1) < -1.0 or else C.Bees (K).X (1) > 1.0
              or else C.Bees (K).X (2) < -1.0
              or else C.Bees (K).X (2) > 1.0
            then
               All_In := False;
            end if;
         end loop;
      end loop;
      Check (All_In, "40 Steps keep all bees in [-1,1]^2");
      Check (C.Bees (Best_Index (C)).Cost <= Init_Best + 1.0E-12,
             "best after Steps never worse than init best");
      Check (C.Bees (Best_Index (C)).Cost < 0.5
             or else C.Bees (Best_Index (C)).Cost < Init_Best,
             "Steps improved or already good");

      --  After Step, colony need not be ranked; Rank should restore order
      Rank_Colony (C);
      Ordered := True;
      for K in 1 .. C.Size - 1 loop
         if C.Bees (K).Cost > C.Bees (K + 1).Cost then
            Ordered := False;
         end if;
      end loop;
      Check (Ordered, "Rank after Steps ordered");
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize_Box Sphere improves + reproducibility");
   ---------------------------------------------------------------------
   declare
      B   : constant Bounds := BoxN (3, -5.0, 5.0);
      Cfg : Config :=
        Default_Config
          (N => 16, M => 5, E => 2, Nep => 12, Nsp => 6,
           Ngh => 0.8, Max_Iterations => 80, Seed => 100);
      R1, R2, R3 : Result;
      Init_Best  : Real;
      C          : Colony (16);
      State      : RNG_State;
   begin
      Seed_RNG (State, 100);
      Init_Colony (C, B, Sphere'Access, State);
      Init_Best := C.Bees (Best_Index (C)).Cost;

      R1 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R1.Dim = 3, "Sphere Result Dim=3");
      Check (R1.Iterations = 80, "Sphere Iterations=80");
      Check (R1.Scouts_Used = 16, "Sphere Scouts_Used=16");
      Check (R1.Best_Cost < Init_Best, "Sphere improves vs initial best");
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

      Cfg.Seed := 100;
      Cfg.Max_Iterations := 0;
      R1 := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R1.Iterations = 0, "zero iterations reported");
      Check (Approx (R1.Best_Cost, Init_Best, 1.0E-9),
             "zero iters = initial colony best");
   end;

   ---------------------------------------------------------------------
   Section ("9. Minimize_Box Rosenbrock / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      B   : constant Bounds := Box2 (-2.0, 2.0);
      Cfg : Config :=
        Default_Config
          (N => 24, M => 6, E => 2, Nep => 15, Nsp => 8,
           Ngh => 0.4, Max_Iterations => 120, Seed => 7);
      R   : Result;
      Bs  : constant Bounds := BoxN (2, -1.0, 3.0);
   begin
      R := Minimize_Box (Rosenbrock'Access, B, Cfg);
      Check (R.Dim = 2, "Rosenbrock Dim=2");
      Check (R.Best_Cost < 10.0, "Rosenbrock Best_Cost < 10");
      Check (R.Best_X (1) >= -2.0 and then R.Best_X (1) <= 2.0,
             "Rosenbrock X in box");
      Check (R.Iterations = 120, "Rosenbrock iterations");

      Cfg.Max_Iterations := 100;
      Cfg.Seed := 8;
      Cfg.Ngh := 0.5;
      R := Minimize_Box (Shifted_Sphere'Access, Bs, Cfg);
      Check (R.Best_Cost < 0.5, "Shifted_Sphere Best_Cost < 0.5");
      Check (Near (R.Best_X (1), 1.0, 0.6)
             and then Near (R.Best_X (2), 1.0, 0.6),
             "Shifted_Sphere near (1,1)");
      Check (Approx (R.Best_Cost,
                     Shifted_Sphere (R.Best_X (1 .. 2)), 1.0E-9),
             "Shifted_Sphere cost matches X");
   end;

   ---------------------------------------------------------------------
   Section ("10. Extra Sphere dims / config smoke");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      for D in Dim_Count loop
         Cfg := Default_Config
           (N => 14, M => 4, E => 2, Nep => 8, Nsp => 4,
            Ngh => 0.35, Max_Iterations => 60, Seed => 200 + D);
         R := Minimize_Box (Sphere'Access, BoxN (D, -1.0, 1.0), Cfg);
         Check (R.Dim = D, "Sphere dim D=" & Dim_Count'Image (D));
         Check (R.Best_Cost < 1.0,
                "Sphere cost ok D=" & Dim_Count'Image (D));
         Check (R.Iterations = 60,
                "Sphere iters D=" & Dim_Count'Image (D));
         Check (R.Scouts_Used = 14,
                "Sphere scouts D=" & Dim_Count'Image (D));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. Edge configs / exceptions smoke");
   ---------------------------------------------------------------------
   declare
      R      : Result;
      Cfg    : Config;
      B      : constant Bounds := Box2 (-0.5, 0.5);
      Raised : Boolean;
   begin
      Cfg := Default_Config
        (N => 8, M => 3, E => 1, Nep => 6, Nsp => 3,
         Ngh => 0.0, Max_Iterations => 40, Seed => 3);
      R := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R.Best_Cost <= 1.0, "Ngh=0 still valid Sphere");
      Check (R.Best_X (1) >= -0.5 and then R.Best_X (1) <= 0.5,
             "Ngh=0 X1 clamped");

      Cfg := Default_Config
        (N => 6, M => 6, E => 6, Nep => 5, Nsp => 5,
         Ngh => 0.2, Max_Iterations => 30, Seed => 4);
      R := Minimize_Box (Sphere'Access, B, Cfg);
      Check (R.Best_Cost <= 1.0, "E=M=N (no global scouts) valid");

      Cfg := Default_Config (N => 5, M => 2, E => 1,
                             Max_Iterations => 30, Seed => 5);
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
               Default_Config (N => 4, M => 2, E => 1,
                               Max_Iterations => 1));
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

      Raised := False;
      begin
         declare
            Bad_Cfg : constant Config :=
              Default_Config (N => 4, M => 3, E => 5);
            Unused  : Result;
         begin
            Unused := Minimize_Box
              (Sphere'Access, B, Bad_Cfg);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            --  Precondition may raise Assertion_Error under -gnata;
            --  without it Config_Is_Valid check raises Invalid_Argument.
            Raised := True;
      end;
      Check (Raised, "E>M config rejected");

      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Clamp (0.0, 1.0, 0.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Clamp Lo>Hi raises Invalid_Argument");
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
