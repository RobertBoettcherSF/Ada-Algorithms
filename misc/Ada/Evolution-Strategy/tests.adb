--  Standalone test suite for Evolution_Strategy (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Evolution_Strategy; use Evolution_Strategy;

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

begin
   Put_Line ("Evolution_Strategy test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Default_Config / Config_Is_Valid");
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

      C := Default_Config;
      Check (C.Mu = 1, "Default Mu");
      Check (C.Lambda = 1, "Default Lambda");
      Check (C.Plus_Or_Comma = Plus, "Default Plus");
      Check (C.Max_Gens = 500, "Default Max_Gens");
      Check (C.Seed = 1, "Default Seed");
      Check (Approx (Real (C.Init_Sigma), 1.0, 1.0E-12), "Default Init_Sigma");
      Check (C.Recombine = False, "Default Recombine");
      Check (C.Success_Window = 10, "Default Success_Window");
      Check (Config_Is_Valid (C), "Default config valid");

      C := Default_Config
        (Mu => 5, Lambda => 20, Plus_Or_Comma => Comma,
         Max_Gens => 100, Seed => 9, Init_Sigma => 0.5,
         Recombine => True, Success_Window => 5);
      Check (C.Mu = 5 and then C.Lambda = 20 and then C.Seed = 9,
             "Default_Config overrides sizes/seed");
      Check (C.Plus_Or_Comma = Comma and then C.Recombine,
             "Default_Config Comma/Recombine");
      Check (Approx (Real (C.Init_Sigma), 0.5), "Default_Config Init_Sigma");
      Check (Config_Is_Valid (C), "Comma lambda>=mu valid");

      C := Default_Config (Mu => 5, Lambda => 3, Plus_Or_Comma => Comma);
      Check (not Config_Is_Valid (C), "Comma lambda<mu invalid");
      C := Default_Config (Mu => 5, Lambda => 3, Plus_Or_Comma => Plus);
      Check (Config_Is_Valid (C), "Plus lambda<mu still valid");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / Sample_Normal");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      X          : Real;
      Sum        : Real := 0.0;
      Sum_Sq     : Real := 0.0;
      N          : constant := 400;
      Mean, Var  : Real;
      Z1, Z2     : Real;
      Neg, Pos   : Natural := 0;
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

      Seed_RNG (S1, 55);
      Check (Next_Natural (S1, 3, 3) = 3, "Next_Natural Lo=Hi");
      Seed_RNG (S1, 55);
      declare
         Ok_Range : Boolean := True;
         V        : Natural;
      begin
         for I in 1 .. 50 loop
            V := Next_Natural (S1, 1, 4);
            if V < 1 or else V > 4 then
               Ok_Range := False;
            end if;
         end loop;
         Check (Ok_Range, "Next_Natural stays in [1,4]");
      end;

      Seed_RNG (S1, 77);
      Seed_RNG (S2, 77);
      Z1 := Sample_Normal (S1);
      Z2 := Sample_Normal (S2);
      Check (Approx (Z1, Z2, 0.0), "Sample_Normal deterministic");

      Seed_RNG (S1, 101);
      for I in 1 .. N loop
         X := Sample_Normal (S1);
         Sum := Sum + X;
         Sum_Sq := Sum_Sq + X * X;
         if X < 0.0 then
            Neg := Neg + 1;
         elsif X > 0.0 then
            Pos := Pos + 1;
         end if;
      end loop;
      Mean := Sum / Real (N);
      Var := Sum_Sq / Real (N) - Mean * Mean;
      Check (abs (Mean) < 0.25, "Sample_Normal mean near 0");
      Check (Var > 0.5 and then Var < 1.8, "Sample_Normal var near 1");
      Check (Neg > 50 and then Pos > 50, "Sample_Normal both signs");
   end;

   ---------------------------------------------------------------------
   Section ("3. Objectives Sphere / Rosenbrock / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      Z  : constant Point (1 .. 3) := [0.0, 0.0, 0.0];
      O  : constant Point (1 .. 2) := [1.0, 1.0];
      S1 : constant Point (1 .. 2) := [1.0, 1.0];
      P  : constant Point (1 .. 2) := [0.0, 0.0];
      Raised : Boolean;
   begin
      Check (Approx (Sphere (Z), 0.0), "Sphere at origin = 0");
      Check (Approx (Sphere (Point'(1 => 3.0)), 9.0), "Sphere (3) = 9");
      Check (Approx (Sphere (Point'(1 => -2.0, 2 => 1.0)), 5.0),
             "Sphere (-2,1) = 5");
      Check (Approx (Rosenbrock (O), 0.0), "Rosenbrock at (1,1) = 0");
      Check (Rosenbrock (P) > 0.0, "Rosenbrock at (0,0) > 0");
      Check (Rosenbrock (Point'(1 => -1.0, 2 => 1.0)) > 0.0,
             "Rosenbrock elsewhere > 0");
      Check (Approx (Shifted_Sphere (S1), 0.0), "Shifted_Sphere at ones");
      Check (Shifted_Sphere (Z) > 0.0, "Shifted_Sphere origin > 0");
      Check (Approx (Shifted_Sphere (Point'(1 => 2.0, 2 => 0.0)), 2.0),
             "Shifted_Sphere (2,0) = 2");

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

   ---------------------------------------------------------------------
   Section ("4. Init_Population / Rank / Best_Index");
   ---------------------------------------------------------------------
   declare
      Pop      : Population (8);
      State    : RNG_State;
      Cfg      : Config;
      All_In   : Boolean := True;
      Costs_Ok : Boolean := True;
      Bi       : Positive;
      Slice    : Point (1 .. 2);
   begin
      Cfg := Default_Config (Mu => 8, Lambda => 16, Init_Sigma => 0.4,
                             Seed => 11);
      Seed_RNG (State, 11);
      Init_Population (Pop, 2, Cfg, Sphere'Access, State, -3.0, 3.0);
      Check (Pop.Size = 8, "Init Size = Mu");
      Check (Pop.Dim = 2, "Init Dim = 2");
      for K in 1 .. Pop.Size loop
         Check (Pop.Members (K).Dim = 2,
                "member Dim=2 k=" & Integer'Image (K));
         Check (Approx (Real (Pop.Members (K).Sigma), 0.4, 1.0E-12),
                "member Init_Sigma k=" & Integer'Image (K));
         if Pop.Members (K).X (1) < -3.0 or else Pop.Members (K).X (1) > 3.0
           or else Pop.Members (K).X (2) < -3.0
           or else Pop.Members (K).X (2) > 3.0
         then
            All_In := False;
         end if;
         Slice (1) := Pop.Members (K).X (1);
         Slice (2) := Pop.Members (K).X (2);
         if not Approx (Pop.Members (K).Fitness, Sphere (Slice), 1.0E-9)
         then
            Costs_Ok := False;
         end if;
      end loop;
      Check (All_In, "init X in [Init_Lo,Init_Hi]");
      Check (Costs_Ok, "init Fitness = Sphere(X)");

      Bi := Best_Index (Pop);
      Check (Bi in 1 .. Pop.Size, "Best_Index in range");
      for K in 1 .. Pop.Size loop
         Check (Pop.Members (Bi).Fitness <= Pop.Members (K).Fitness,
                "Best_Index is minimal k=" & Integer'Image (K));
      end loop;

      Rank_Ascending (Pop);
      Check (Approx (Pop.Members (1).Fitness,
                     Pop.Members (Best_Index (Pop)).Fitness, 0.0),
             "Rank puts best first");
      declare
         Ordered : Boolean := True;
      begin
         for K in 2 .. Pop.Size loop
            if Pop.Members (K - 1).Fitness > Pop.Members (K).Fitness then
               Ordered := False;
            end if;
         end loop;
         Check (Ordered, "Rank ascending by Fitness");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Mutate / Mutate_Self_Adaptive / Recombine");
   ---------------------------------------------------------------------
   declare
      State  : RNG_State;
      Parent : Individual;
      Child  : Individual;
      A, B   : Individual;
      Moved  : Boolean := False;
      Sig_Ch : Boolean := False;
   begin
      Parent.Dim := 3;
      Parent.Sigma := 1.0;
      Parent.X := [0.0, 0.0, 0.0, others => 0.0];
      Parent.Fitness := 0.0;

      Seed_RNG (State, 3);
      for Trial in 1 .. 20 loop
         Child := Mutate (Parent, State);
         Check (Child.Dim = 3, "Mutate preserves Dim t="
                & Integer'Image (Trial));
         Check (Approx (Real (Child.Sigma), 1.0, 0.0),
                "Mutate keeps Sigma t=" & Integer'Image (Trial));
         if abs (Child.X (1)) > 1.0E-12
           or else abs (Child.X (2)) > 1.0E-12
           or else abs (Child.X (3)) > 1.0E-12
         then
            Moved := True;
         end if;
      end loop;
      Check (Moved, "Mutate changes coordinates");

      Seed_RNG (State, 8);
      for Trial in 1 .. 30 loop
         Child := Mutate_Self_Adaptive (Parent, State);
         Check (Child.Dim = 3, "SA Mutate Dim t=" & Integer'Image (Trial));
         Check (Real (Child.Sigma) > 0.0, "SA Sigma > 0");
         if not Approx (Real (Child.Sigma), 1.0, 1.0E-15) then
            Sig_Ch := True;
         end if;
      end loop;
      Check (Sig_Ch, "Self-adaptive Sigma changes");

      A := Parent;
      B := Parent;
      A.X (1) := 2.0;
      B.X (1) := 4.0;
      A.Sigma := 1.0;
      B.Sigma := 3.0;
      Seed_RNG (State, 12);
      Child := Intermediate_Recombine (A, B, State);
      Check (Child.Dim = 3, "Recombine Dim");
      Check (Real (Child.Sigma) > 0.0, "Recombine Sigma > 0");
      --  After recombine+mutate, X is near midpoint then noise; just
      --  sanity-check finite fitness placeholder.
      Check (Child.Fitness = Real'Last, "Recombine Fitness unset");
   end;

   ---------------------------------------------------------------------
   Section ("6. (1+1)-ES Sphere / 1/5 rule");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      Cfg := Default_Config
        (Mu => 1, Lambda => 1, Plus_Or_Comma => Plus,
         Max_Gens => 800, Seed => 2, Init_Sigma => 0.8,
         Success_Window => 10);
      R := Minimize (Sphere'Access, 2, Cfg, -2.0, 2.0);
      Check (R.Dim = 2, "(1+1) Sphere Dim");
      Check (R.Generations = 800, "(1+1) Sphere gens");
      Check (R.Mu_Used = 1 and then R.Lambda_Used = 1, "(1+1) sizes");
      Check (R.Evaluations = 1 + 800, "(1+1) evaluations");
      Check (R.Best_Cost < 1.0E-4, "(1+1) Sphere cost small");
      Check (abs (R.Best_X (1)) < 0.05 and then abs (R.Best_X (2)) < 0.05,
             "(1+1) Sphere near origin");
      Check (R.Best_Sigma > 0.0, "(1+1) Sigma positive");

      Cfg.Max_Gens := 0;
      R := Minimize (Sphere'Access, 2, Cfg, -1.0, 1.0);
      Check (R.Generations = 0, "(1+1) Max_Gens=0");
      Check (R.Evaluations = 1, "(1+1) init-only evals");
      Check (R.Best_Cost >= 0.0, "(1+1) init cost >= 0");
   end;

   ---------------------------------------------------------------------
   Section ("7. (μ,λ) / (μ+λ) Sphere");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      Cfg := Default_Config
        (Mu => 5, Lambda => 20, Plus_Or_Comma => Comma,
         Max_Gens => 120, Seed => 4, Init_Sigma => 0.6,
         Recombine => False);
      R := Minimize (Sphere'Access, 3, Cfg, -2.0, 2.0);
      Check (R.Dim = 3, "(mu,lambda) Dim");
      Check (R.Mu_Used = 5 and then R.Lambda_Used = 20, "(mu,lambda) sizes");
      Check (R.Generations = 120, "(mu,lambda) gens");
      Check (R.Evaluations = 5 + 120 * 20, "(mu,lambda) evals");
      Check (R.Best_Cost < 1.0E-3, "(mu,lambda) Sphere cost");
      Check (abs (R.Best_X (1)) < 0.1, "(mu,lambda) X1 near 0");

      Cfg := Default_Config
        (Mu => 4, Lambda => 16, Plus_Or_Comma => Plus,
         Max_Gens => 100, Seed => 5, Init_Sigma => 0.5,
         Recombine => True);
      R := Minimize (Sphere'Access, 2, Cfg, -2.0, 2.0);
      Check (R.Dim = 2, "(mu+lambda) Dim");
      Check (R.Best_Cost < 1.0E-3, "(mu+lambda) Sphere cost");
      Check (R.Best_Sigma > 0.0, "(mu+lambda) Sigma > 0");
      Check (R.Evaluations = 4 + 100 * 16, "(mu+lambda) evals");
   end;

   ---------------------------------------------------------------------
   Section ("8. Rosenbrock / Shifted_Sphere demos");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      Cfg := Default_Config
        (Mu => 6, Lambda => 36, Plus_Or_Comma => Plus,
         Max_Gens => 250, Seed => 17, Init_Sigma => 0.4,
         Recombine => True);
      R := Minimize (Rosenbrock'Access, 2, Cfg, -1.5, 1.5);
      Check (R.Dim = 2, "Rosenbrock Dim");
      Check (R.Best_Cost < 0.5, "Rosenbrock cost improved");
      Check (abs (R.Best_X (1) - 1.0) < 0.8, "Rosenbrock X near 1-ish");

      Cfg := Default_Config
        (Mu => 5, Lambda => 25, Plus_Or_Comma => Comma,
         Max_Gens => 150, Seed => 19, Init_Sigma => 0.5,
         Recombine => False);
      R := Minimize (Shifted_Sphere'Access, 4, Cfg, -1.0, 3.0);
      Check (R.Dim = 4, "Shifted_Sphere Dim");
      Check (R.Best_Cost < 0.05, "Shifted_Sphere cost");
      Check (abs (R.Best_X (1) - 1.0) < 0.3, "Shifted_Sphere X1~1");
   end;

   ---------------------------------------------------------------------
   Section ("9. Dimensional sweep Sphere Dim=1..8");
   ---------------------------------------------------------------------
   declare
      R   : Result;
      Cfg : Config;
   begin
      for D in Dim_Count loop
         Cfg := Default_Config
           (Mu => 6, Lambda => 30, Plus_Or_Comma => Plus,
            Max_Gens => 80, Seed => 30 + D,
            Init_Sigma => 0.5, Recombine => True);
         R := Minimize (Sphere'Access, D, Cfg, -1.5, 1.5);
         Check (R.Dim = D, "Sphere dim D=" & Dim_Count'Image (D));
         Check (R.Best_Cost < 1.0,
                "Sphere cost ok D=" & Dim_Count'Image (D));
         Check (R.Generations = 80,
                "Sphere gens D=" & Dim_Count'Image (D));
         Check (R.Mu_Used = 6,
                "Sphere mu D=" & Dim_Count'Image (D));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Step_One_Plus_One / Step_Mu_Lambda unit");
   ---------------------------------------------------------------------
   declare
      Parent      : Individual;
      State       : RNG_State;
      Successes   : Natural := 0;
      Trials      : Natural := 0;
      Evals       : Natural := 0;
      Pop         : Population (4);
      Cfg         : Config;
      Before      : Real;
   begin
      Parent.Dim := 2;
      Parent.Sigma := 0.5;
      Parent.X := [1.0, 1.0, others => 0.0];
      Parent.Fitness := Sphere (Point'(1 => 1.0, 2 => 1.0));
      Seed_RNG (State, 21);
      Before := Parent.Fitness;
      for I in 1 .. 50 loop
         Step_One_Plus_One
           (Parent, Sphere'Access, State, Successes, Trials, 10, Evals);
      end loop;
      Check (Evals = 50, "Step_One_Plus_One 50 evals");
      Check (Parent.Fitness <= Before, "(1+1) never worsens parent");
      Check (Real (Parent.Sigma) > 0.0, "(1+1) sigma stays positive");

      Cfg := Default_Config
        (Mu => 4, Lambda => 12, Plus_Or_Comma => Plus,
         Init_Sigma => 0.7, Recombine => False);
      Seed_RNG (State, 22);
      Init_Population (Pop, 2, Cfg, Sphere'Access, State, -2.0, 2.0);
      Evals := 0;
      Before := Pop.Members (Best_Index (Pop)).Fitness;
      Step_Mu_Lambda (Pop, Cfg, Sphere'Access, State, Evals);
      Check (Pop.Size = 4, "Step_Mu_Lambda keeps Mu");
      Check (Evals = 12, "Step_Mu_Lambda lambda evals");
      Check (Pop.Members (Best_Index (Pop)).Fitness <= Before + 1.0E-12,
             "Plus step best not worse");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exceptions / edge configs");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      R      : Result;
      Cfg    : Config;
   begin
      Raised := False;
      begin
         declare
            Unused : Result;
         begin
            Unused := Minimize
              (Sphere'Access, 2,
               Default_Config (Mu => 5, Lambda => 2, Plus_Or_Comma => Comma));
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "invalid Comma config raises");

      Raised := False;
      begin
         declare
            Unused : Result;
         begin
            Unused := Minimize
              (Sphere'Access, 2,
               Default_Config, Init_Lo => 2.0, Init_Hi => -2.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := True;
      end;
      Check (Raised, "Init_Lo>Init_Hi raises");

      Cfg := Default_Config
        (Mu => 3, Lambda => 9, Plus_Or_Comma => Comma,
         Max_Gens => 40, Seed => 3, Init_Sigma => 0.3);
      R := Minimize (Sphere'Access, 1, Cfg, -2.0, 2.0);
      Check (R.Dim = 1, "1-D Sphere Dim");
      Check (R.Best_Cost < 0.1, "1-D Sphere cost");

      Cfg := Default_Config
        (Mu => 1, Lambda => 7, Plus_Or_Comma => Comma,
         Max_Gens => 60, Seed => 8, Init_Sigma => 0.5);
      R := Minimize (Sphere'Access, 2, Cfg, -1.0, 1.0);
      Check (R.Mu_Used = 1 and then R.Lambda_Used = 7, "(1,lambda) sizes");
      Check (R.Best_Cost < 0.05, "(1,lambda) Sphere cost");

      Cfg := Default_Config
        (Mu => 1, Lambda => 1, Plus_Or_Comma => Plus,
         Max_Gens => 200, Seed => 1, Init_Sigma => 1.0,
         Success_Window => 1);
      R := Minimize (Sphere'Access, 2, Cfg, -1.0, 1.0);
      Check (R.Best_Cost < 0.01, "Success_Window=1 still works");
   end;

   ---------------------------------------------------------------------
   Section ("12. Reproducibility same seed");
   ---------------------------------------------------------------------
   declare
      R1, R2, R3 : Result;
      Cfg        : Config;
   begin
      Cfg := Default_Config
        (Mu => 4, Lambda => 16, Plus_Or_Comma => Plus,
         Max_Gens => 40, Seed => 123, Init_Sigma => 0.5,
         Recombine => True);
      R1 := Minimize (Sphere'Access, 2, Cfg, -2.0, 2.0);
      R2 := Minimize (Sphere'Access, 2, Cfg, -2.0, 2.0);
      Cfg.Seed := 456;
      R3 := Minimize (Sphere'Access, 2, Cfg, -2.0, 2.0);
      Check (Approx (R1.Best_Cost, R2.Best_Cost, 0.0),
             "same seed same Best_Cost");
      Check (Approx (R1.Best_X (1), R2.Best_X (1), 0.0)
             and then Approx (R1.Best_X (2), R2.Best_X (2), 0.0),
             "same seed same Best_X");
      Check (Approx (R1.Best_Sigma, R2.Best_Sigma, 0.0),
             "same seed same Best_Sigma");
      Check (R1.Evaluations = R2.Evaluations, "same seed same evals");
      --  Different seed almost surely differs (allow rare collision).
      Check (R1.Best_Cost /= R3.Best_Cost
             or else R1.Best_X (1) /= R3.Best_X (1),
             "different seed differs");
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
