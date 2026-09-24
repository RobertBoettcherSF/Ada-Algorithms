--  Standalone test suite for Differential_Evolution (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Differential_Evolution; use Differential_Evolution;

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

   function BoxN (N : Dimension; Lo, Hi : Real) return Bounds is
      B : Bounds (1 .. N);
   begin
      for I in B'Range loop
         B (I) := (Lo => Lo, Hi => Hi);
      end loop;
      return B;
   end BoxN;

begin
   Put_Line ("Differential_Evolution test suite");
   Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp / Default_Parameters");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
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
      P := Default_Parameters;
      Check (Approx (Real (P.F), 0.8, 1.0E-12), "Default F");
      Check (Approx (Real (P.CR), 0.9, 1.0E-12), "Default CR");
      Check (P.NP = 20, "Default NP");
      Check (P.Max_Gen = 200, "Default Max_Gen");
      Check (P.Seed = 1, "Default Seed");
      Check (not P.Maximize, "Default Maximize False");
      P := Default_Parameters
        (F => 0.5, CR => 0.3, NP => 8, Max_Gen => 10,
         Seed => 42, Maximize => True);
      Check (P.NP = 8 and then P.Seed = 42 and then P.Maximize,
             "Default_Parameters overrides");
      Check (Approx (Real (P.F), 0.5) and then Approx (Real (P.CR), 0.3),
             "Default_Parameters F/CR");
   end;

   ---------------------------------------------------------------------
   Section ("2. Clamp_Vector / inverted bounds");
   ---------------------------------------------------------------------
   declare
      B : Bounds (1 .. 2);
      X : Vector (1 .. 2);
      Y : Vector (1 .. 2);
      Raised : Boolean;
   begin
      B (1) := (Lo => -1.0, Hi => 1.0);
      B (2) := (Lo => 0.0, Hi => 5.0);
      X := [3.0, -2.0];
      Y := Clamp_Vector (X, B);
      Check (Approx (Y (1), 1.0), "Clamp_Vector dim1 Hi");
      Check (Approx (Y (2), 0.0), "Clamp_Vector dim2 Lo");
      X := [0.0, 2.5];
      Y := Clamp_Vector (X, B);
      Check (Approx (Y (1), 0.0) and then Approx (Y (2), 2.5),
             "Clamp_Vector interior");
      Raised := False;
      begin
         declare
            Unused : constant Real := Clamp (0.0, 2.0, 1.0);
         begin
            Check (Unused < 0.0, "unreachable clamp success");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Clamp inverted raises");
      Raised := False;
      begin
         B (1) := (Lo => 5.0, Hi => 1.0);
         Y := Clamp_Vector ([0.0, 0.0], B);
         Check (Approx (Y (1), 0.0), "unreachable clamp_vector success");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Clamp_Vector inverted raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. RNG determinism / range / Next_Index");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_Match  : Boolean := True;
      Saw_Diff   : Boolean := False;
      Idx        : Positive;
      Idx_Ok     : Boolean := True;
      Uni_Ok     : Boolean := True;
      V          : Real;
   begin
      Seed_RNG (S1, 7);
      Seed_RNG (S2, 7);
      Seed_RNG (S3, 8);
      for K in 1 .. 50 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         U3 := Next_Unit (S3);
         if U1 /= U2 then
            All_Match := False;
         end if;
         if U1 /= U3 then
            Saw_Diff := True;
         end if;
         if Real (U1) < 0.0 then
            All_Match := False;
         end if;
      end loop;
      Check (All_Match, "RNG same seed reproduces and stays in [0,1)");
      Check (Saw_Diff, "RNG different seeds diverge");

      Seed_RNG (S1, 0);
      Seed_RNG (S2, 0);
      Check (Next_Unit (S1) = Next_Unit (S2), "Seed 0 maps identically");

      Seed_RNG (S1, 99);
      for K in 1 .. 200 loop
         Idx := Next_Index (S1, 1, 5);
         if Idx > 5 then
            Idx_Ok := False;
         end if;
      end loop;
      Check (Idx_Ok, "Next_Index in [1,5]");

      declare
         Counts : array (1 .. 3) of Natural := [others => 0];
         Seen_All : Boolean;
      begin
         Seed_RNG (S1, 123);
         for K in 1 .. 300 loop
            Idx := Next_Index (S1, 1, 3);
            Counts (Idx) := Counts (Idx) + 1;
         end loop;
         Seen_All := Counts (1) > 0 and then Counts (2) > 0
           and then Counts (3) > 0;
         Check (Seen_All, "Next_Index hits all of 1..3");
         Check (Counts (1) + Counts (2) + Counts (3) = 300,
                "Next_Index count sum 300");
      end;

      Seed_RNG (S1, 3);
      for K in 1 .. 100 loop
         V := Next_Uniform (S1, -2.0, 2.0);
         if V < -2.0 or else V > 2.0 then
            Uni_Ok := False;
         end if;
      end loop;
      Check (Uni_Ok, "Next_Uniform in [-2,2]");
   end;

   ---------------------------------------------------------------------
   Section ("4. Objectives: Sphere / Rosenbrock / Rastrigin / Shifted");
   ---------------------------------------------------------------------
   declare
      Z2 : constant Vector (1 .. 2) := [0.0, 0.0];
      O2 : constant Vector (1 .. 2) := [1.0, 1.0];
      P2 : constant Vector (1 .. 2) := [1.0, 2.0];
      Z4 : constant Vector (1 .. 4) := [others => 0.0];
      Raised : Boolean;
   begin
      Check (Approx (Sphere (Z2), 0.0), "Sphere at origin");
      Check (Approx (Sphere (P2), 5.0), "Sphere at (1,2)");
      Check (Approx (Sphere (Z4), 0.0), "Sphere 4D origin");
      Check (Approx (Rosenbrock (O2), 0.0, 1.0E-12), "Rosenbrock at (1,1)");
      Check (Rosenbrock ([0.0, 0.0]) > 0.0, "Rosenbrock (0,0) positive");
      Check (Approx (Rastrigin (Z2), 0.0, 1.0E-10), "Rastrigin at origin");
      Check (Rastrigin ([1.0, 1.0]) > 0.0, "Rastrigin (1,1) positive");
      Check (Approx (Shifted_Sphere (O2), 0.0), "Shifted_Sphere at ones");
      Check (Approx (Shifted_Sphere (Z2), 2.0), "Shifted_Sphere at origin");
      Check (Approx (Neg_Sphere (Z2), 0.0), "Neg_Sphere at origin");
      Check (Neg_Sphere (P2) < 0.0, "Neg_Sphere (1,2) negative");
      Raised := False;
      begin
         declare
            Unused : constant Real := Rosenbrock ([0.0]);
         begin
            Check (Unused < -1.0, "unreachable Rosenbrock success");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock Dim<2 raises");
   end;

   ---------------------------------------------------------------------
   Section ("5. Mutation algebra Mutate_Rand1");
   ---------------------------------------------------------------------
   declare
      B    : constant Bounds (1 .. 2) :=
        [(Lo => -100.0, Hi => 100.0), (Lo => -100.0, Hi => 100.0)];
      Base : constant Vector (1 .. 2) := [1.0, 2.0];
      D1   : constant Vector (1 .. 2) := [4.0, 6.0];
      D2   : constant Vector (1 .. 2) := [3.0, 5.0];
      V    : Vector (1 .. 2);
   begin
      V := Mutate_Rand1 (Base, D1, D2, 0.5, B);
      Check (Approx (V (1), 1.5), "Mutate_Rand1 x algebra");
      Check (Approx (V (2), 2.5), "Mutate_Rand1 y algebra");

      V := Mutate_Rand1 (Base, D1, D2, 0.0, B);
      Check (Approx (V (1), 1.0) and then Approx (V (2), 2.0),
             "Mutate_Rand1 F=0 equals base");

      declare
         Tight : constant Bounds (1 .. 2) :=
           [(Lo => 0.0, Hi => 1.0), (Lo => 0.0, Hi => 1.0)];
         Far1 : constant Vector (1 .. 2) := [10.0, 10.0];
         Far2 : constant Vector (1 .. 2) := [0.0, 0.0];
         Vb   : constant Vector (1 .. 2) := [0.5, 0.5];
      begin
         V := Mutate_Rand1 (Vb, Far1, Far2, 2.0, Tight);
         Check (Approx (V (1), 1.0) and then Approx (V (2), 1.0),
                "Mutate_Rand1 clamps to Hi");
         V := Mutate_Rand1 (Vb, Far2, Far1, 2.0, Tight);
         Check (Approx (V (1), 0.0) and then Approx (V (2), 0.0),
                "Mutate_Rand1 clamps to Lo");
      end;

      V := Mutate_Rand1 ([0.0, 0.0], [3.0, -1.0], [1.0, 1.0], 1.0, B);
      Check (Approx (V (1), 2.0) and then Approx (V (2), -2.0),
             "Mutate_Rand1 F=1 difference");
      V := Mutate_Rand1 ([10.0, 10.0], [1.0, 1.0], [1.0, 1.0], 1.5, B);
      Check (Approx (V (1), 10.0) and then Approx (V (2), 10.0),
             "Mutate_Rand1 zero difference");
   end;

   ---------------------------------------------------------------------
   Section ("6. Binomial_Crossover guarantees j_rand");
   ---------------------------------------------------------------------
   declare
      State : RNG_State;
      Target : constant Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      Mutant : constant Vector (1 .. 4) := [10.0, 20.0, 30.0, 40.0];
      Trial  : Vector (1 .. 4);
      All_J  : Boolean := True;
      J_Rand_Ok : Boolean := True;
      Saw_Target : Boolean := False;
      Saw_Mutant_Extra : Boolean := False;
   begin
      for J in Dim_Index range 1 .. 4 loop
         Seed_RNG (State, 50 + J);
         Trial := Binomial_Crossover (Target, Mutant, 0.0, J, State);
         if not Approx (Trial (J), Mutant (J)) then
            All_J := False;
         end if;
         for K in Dim_Index range 1 .. 4 loop
            if K /= J and then not Approx (Trial (K), Target (K)) then
               All_J := False;
            end if;
         end loop;
      end loop;
      Check (All_J, "CR=0 only j_rand from mutant");
      Check (All_J, "CR=0 non-j_rand stay target");
      Check (All_J, "CR=0 all four j_rand positions");

      Seed_RNG (State, 1);
      Trial := Binomial_Crossover (Target, Mutant, 1.0, 2, State);
      Check (Approx (Trial (1), 10.0), "CR=1 dim1 mutant");
      Check (Approx (Trial (2), 20.0), "CR=1 dim2 mutant");
      Check (Approx (Trial (3), 30.0), "CR=1 dim3 mutant");
      Check (Approx (Trial (4), 40.0), "CR=1 dim4 mutant");

      for Trial_N in 1 .. 40 loop
         Seed_RNG (State, 1000 + Trial_N);
         Trial := Binomial_Crossover (Target, Mutant, 0.5, 1, State);
         if not Approx (Trial (1), 10.0) then
            J_Rand_Ok := False;
         end if;
         for K in Dim_Index range 2 .. 4 loop
            if Approx (Trial (K), Target (K)) then
               Saw_Target := True;
            end if;
            if Approx (Trial (K), Mutant (K)) then
               Saw_Mutant_Extra := True;
            end if;
         end loop;
      end loop;
      Check (J_Rand_Ok, "CR=0.5 j_rand=1 always mutant (40 trials)");
      Check (J_Rand_Ok, "j_rand guarantee holds under mid CR");
      Check (Saw_Target, "CR=0.5 sometimes keeps target coords");
      Check (Saw_Mutant_Extra, "CR=0.5 sometimes takes extra mutant coords");
      Check (Saw_Target and then Saw_Mutant_Extra,
             "CR=0.5 mixes target and mutant on non-j_rand");

      for J in Dim_Index range 1 .. 4 loop
         J_Rand_Ok := True;
         for Trial_N in 1 .. 20 loop
            Seed_RNG (State, 2000 + 20 * J + Trial_N);
            Trial := Binomial_Crossover (Target, Mutant, 0.3, J, State);
            if not Approx (Trial (J), Mutant (J)) then
               J_Rand_Ok := False;
            end if;
         end loop;
         Check (J_Rand_Ok,
                "j_rand dim" & Dim_Index'Image (J) & " always mutant");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Better / Select_Greedy");
   ---------------------------------------------------------------------
   declare
      A  : Agent;
      Tx : constant Vector (1 .. 2) := [0.0, 0.0];
   begin
      Check (Better (1.0, 2.0, False), "Better min trial smaller");
      Check (not Better (2.0, 1.0, False), "Better min trial larger");
      Check (not Better (1.0, 1.0, False), "Better min equal no replace");
      Check (Better (2.0, 1.0, True), "Better max trial larger");
      Check (not Better (1.0, 2.0, True), "Better max trial smaller");
      Check (not Better (5.0, 5.0, True), "Better max equal no replace");

      A.Dim := 2;
      A.X (1) := 5.0;
      A.X (2) := 5.0;
      A.Cost := 50.0;
      Select_Greedy (A, Tx, 0.0, False);
      Check (Approx (A.Cost, 0.0) and then Approx (A.X (1), 0.0),
             "Select_Greedy accepts better min");
      Select_Greedy (A, [9.0, 9.0], 100.0, False);
      Check (Approx (A.Cost, 0.0), "Select_Greedy rejects worse min");

      A.Cost := 1.0;
      A.X (1) := 1.0;
      A.X (2) := 1.0;
      Select_Greedy (A, [3.0, 3.0], 10.0, True);
      Check (Approx (A.Cost, 10.0) and then Approx (A.X (1), 3.0),
             "Select_Greedy accepts better max");
      Select_Greedy (A, [0.0, 0.0], 0.5, True);
      Check (Approx (A.Cost, 10.0), "Select_Greedy rejects worse max");
   end;

   ---------------------------------------------------------------------
   Section ("8. Init_Population bounds / costs / determinism");
   ---------------------------------------------------------------------
   declare
      Pop1 : Population (Capacity => 8);
      Pop2 : Population (Capacity => 8);
      B    : constant Bounds := Box2 (-5.0, 5.0);
      S1, S2 : RNG_State;
      In_Box : Boolean := True;
      Same   : Boolean := True;
      Costs_Ok : Boolean := True;
      V : Vector (1 .. 2);
   begin
      Seed_RNG (S1, 11);
      Seed_RNG (S2, 11);
      Init_Population (Pop1, B, Sphere'Access, S1);
      Init_Population (Pop2, B, Sphere'Access, S2);
      Check (Pop1.Size = 8, "Init size 8");
      Check (Pop1.Dim = 2, "Init dim 2");
      for I in 1 .. Pop1.Size loop
         for D in 1 .. Pop1.Dim loop
            if Pop1.Members (I).X (D) < -5.0
              or else Pop1.Members (I).X (D) > 5.0
            then
               In_Box := False;
            end if;
            if Pop1.Members (I).X (D) /= Pop2.Members (I).X (D) then
               Same := False;
            end if;
         end loop;
         V (1) := Pop1.Members (I).X (1);
         V (2) := Pop1.Members (I).X (2);
         if not Approx (Pop1.Members (I).Cost, Sphere (V), 1.0E-12) then
            Costs_Ok := False;
         end if;
      end loop;
      Check (In_Box, "Init agents inside box");
      Check (Same, "Init deterministic with same seed");
      Check (Costs_Ok, "Init costs match Sphere");
      Check (Best_Agent_Index (Pop1) in 1 .. Pop1.Size,
             "Best_Agent_Index in range");
   end;

   ---------------------------------------------------------------------
   Section ("9. Step_Generation improves Sphere best");
   ---------------------------------------------------------------------
   declare
      Pop : Population (Capacity => 12);
      B   : constant Bounds := BoxN (3, -5.0, 5.0);
      S   : RNG_State;
      P   : constant Parameters := Default_Parameters
        (F => 0.8, CR => 0.9, NP => 12, Max_Gen => 1, Seed => 5);
      Before, After : Real;
      Bi : Positive;
   begin
      Seed_RNG (S, 5);
      Init_Population (Pop, B, Sphere'Access, S);
      Bi := Best_Agent_Index (Pop);
      Before := Pop.Members (Bi).Cost;
      for Gen in 1 .. 30 loop
         Step_Generation (Pop, B, P, Sphere'Access, S);
      end loop;
      Bi := Best_Agent_Index (Pop);
      After := Pop.Members (Bi).Cost;
      Check (After <= Before, "Step_Generation best cost non-increasing");
      Check (After < Before, "Step_Generation improves Sphere best");
      Check (After < 10.0, "Step_Generation Sphere best modest");
   end;

   ---------------------------------------------------------------------
   Section ("10. Minimize Sphere converges near 0");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : constant Parameters := Default_Parameters
        (F => 0.8, CR => 0.9, NP => 20, Max_Gen => 80, Seed => 2);
      B : constant Bounds := BoxN (3, -5.0, 5.0);
   begin
      R := Minimize (Sphere'Access, B, P);
      Check (R.Dim = 3, "Minimize Sphere dim");
      Check (R.NP_Used = 20, "Minimize Sphere NP_Used");
      Check (R.Generations = 80, "Minimize Sphere generations");
      Check (R.Best_Cost < 1.0E-2, "Minimize Sphere cost < 1e-2");
      Check (abs (R.Best_X (1)) < 0.2, "Minimize Sphere x1 near 0");
      Check (abs (R.Best_X (2)) < 0.2, "Minimize Sphere x2 near 0");
      Check (abs (R.Best_X (3)) < 0.2, "Minimize Sphere x3 near 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Minimize Rosenbrock / Rastrigin / Shifted_Sphere");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : Parameters;
   begin
      P := Default_Parameters
        (F => 0.8, CR => 0.9, NP => 30, Max_Gen => 250, Seed => 7);
      R := Minimize (Rosenbrock'Access, Box2 (-2.0, 2.0), P);
      Check (R.Best_Cost < 0.1, "Rosenbrock cost < 0.1");
      Check (abs (R.Best_X (1) - 1.0) < 0.35, "Rosenbrock x near 1");
      Check (abs (R.Best_X (2) - 1.0) < 0.35, "Rosenbrock y near 1");

      P := Default_Parameters
        (F => 0.9, CR => 0.9, NP => 40, Max_Gen => 300, Seed => 13);
      R := Minimize (Rastrigin'Access, BoxN (2, -5.12, 5.12), P);
      Check (R.Best_Cost < 5.0, "Rastrigin cost modest");
      Check (abs (R.Best_X (1)) < 2.0, "Rastrigin x1 near basin");
      Check (abs (R.Best_X (2)) < 2.0, "Rastrigin x2 near basin");

      P := Default_Parameters
        (F => 0.8, CR => 0.9, NP => 16, Max_Gen => 60, Seed => 4);
      R := Minimize (Shifted_Sphere'Access, BoxN (2, -2.0, 3.0), P);
      Check (R.Best_Cost < 1.0E-2, "Shifted_Sphere cost < 1e-2");
      Check (Approx (R.Best_X (1), 1.0, 0.15), "Shifted_Sphere x near 1");
      Check (Approx (R.Best_X (2), 1.0, 0.15), "Shifted_Sphere y near 1");
   end;

   ---------------------------------------------------------------------
   Section ("12. Maximize / Optimize flags");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : Parameters := Default_Parameters
        (F => 0.8, CR => 0.9, NP => 16, Max_Gen => 40, Seed => 9);
      B : constant Bounds := BoxN (2, -2.0, 2.0);
   begin
      R := Maximize (Neg_Sphere'Access, B, P);
      Check (R.Best_Cost > -0.05, "Maximize Neg_Sphere near 0");
      Check (abs (R.Best_X (1)) < 0.3, "Maximize Neg_Sphere x1");
      Check (abs (R.Best_X (2)) < 0.3, "Maximize Neg_Sphere x2");

      P.Maximize := True;
      R := Optimize (Neg_Sphere'Access, B, P);
      Check (R.Best_Cost > -0.05, "Optimize Maximize flag Neg_Sphere");

      P.Maximize := False;
      R := Optimize (Sphere'Access, B, P);
      Check (R.Best_Cost < 0.05, "Optimize Minimize flag Sphere");

      P.Maximize := True;
      R := Minimize (Sphere'Access, B, P);
      Check (R.Best_Cost < 0.05, "Minimize ignores Maximize flag");
   end;

   ---------------------------------------------------------------------
   Section ("13. Determinism of Minimize");
   ---------------------------------------------------------------------
   declare
      P : constant Parameters := Default_Parameters
        (F => 0.7, CR => 0.8, NP => 10, Max_Gen => 25, Seed => 77);
      B : constant Bounds := BoxN (2, -3.0, 3.0);
      R1, R2 : Result;
   begin
      R1 := Minimize (Sphere'Access, B, P);
      R2 := Minimize (Sphere'Access, B, P);
      Check (Approx (R1.Best_Cost, R2.Best_Cost, 0.0),
             "Minimize deterministic cost");
      Check (Approx (R1.Best_X (1), R2.Best_X (1), 0.0),
             "Minimize deterministic x1");
      Check (Approx (R1.Best_X (2), R2.Best_X (2), 0.0),
             "Minimize deterministic x2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Max_Gen=0 init-only");
   ---------------------------------------------------------------------
   declare
      P : constant Parameters := Default_Parameters
        (NP => 8, Max_Gen => 0, Seed => 1);
      B : constant Bounds := BoxN (2, -1.0, 1.0);
      R : Result;
   begin
      R := Minimize (Sphere'Access, B, P);
      Check (R.Generations = 0, "Max_Gen=0 generations");
      Check (R.Best_Cost >= 0.0, "Max_Gen=0 Sphere cost non-neg");
      Check (R.NP_Used = 8, "Max_Gen=0 NP_Used");
      Check (R.Dim = 2, "Max_Gen=0 Dim");
   end;

   ---------------------------------------------------------------------
   Section ("15. Parameter / bounds validation");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Bad    : Bounds (1 .. 2);
      P      : constant Parameters :=
        Default_Parameters (NP => 8, Max_Gen => 5);
   begin
      Bad (1) := (Lo => 1.0, Hi => -1.0);
      Bad (2) := (Lo => 0.0, Hi => 1.0);
      Raised := False;
      begin
         declare
            R : constant Result := Minimize (Sphere'Access, Bad, P);
            Ok : constant Boolean := R.NP_Used > 0;
         begin
            Check (not Ok, "unreachable bad bounds");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Minimize inverted bounds raises");

      Raised := False;
      begin
         declare
            R : constant Result := Minimize (null, Box2 (-1.0, 1.0), P);
            Ok : constant Boolean := R.NP_Used > 0;
         begin
            Check (not Ok, "unreachable null objective");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "null objective rejected");
   end;

   ---------------------------------------------------------------------
   Section ("16. Capacity / Best index / box invariance");
   ---------------------------------------------------------------------
   declare
      Pop : Population (Capacity => 4);
      B1  : constant Bounds := BoxN (1, 0.0, 1.0);
      S   : RNG_State;
      Bi  : Positive;
   begin
      Seed_RNG (S, 1);
      Init_Population (Pop, B1, Sphere'Access, S);
      Check (Pop.Size = 4, "Min NP size 4");
      Bi := Best_Agent_Index (Pop);
      Check (Bi <= 4, "Best index within 1..4");
      Check (Pop.Members (Bi).Cost >= 0.0, "Best Sphere cost non-neg");
   end;

   declare
      Pop : Population (Capacity => 16);
      B   : constant Bounds := BoxN (4, -1.5, 2.5);
      S   : RNG_State;
      P   : constant Parameters := Default_Parameters
        (F => 1.2, CR => 0.5, NP => 16, Seed => 21);
      Ok  : Boolean := True;
   begin
      Seed_RNG (S, 21);
      Init_Population (Pop, B, Sphere'Access, S);
      for Gen in 1 .. 50 loop
         Step_Generation (Pop, B, P, Sphere'Access, S);
      end loop;
      for I in 1 .. Pop.Size loop
         for D in 1 .. Pop.Dim loop
            if Pop.Members (I).X (D) < -1.5
              or else Pop.Members (I).X (D) > 2.5
            then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "Population stays inside box after Steps");
      Check (Pop.Dim = 4, "Step preserves dim 4");
   end;

   ---------------------------------------------------------------------
   Section ("17. F/CR edge effects");
   ---------------------------------------------------------------------
   declare
      R : Result;
      B : constant Bounds := BoxN (2, -4.0, 4.0);
   begin
      R := Minimize
        (Sphere'Access, B,
         Default_Parameters
           (F => 0.0, CR => 0.0, NP => 12, Max_Gen => 20, Seed => 3));
      Check (R.Best_Cost >= 0.0, "F=0 CR=0 runs");
      Check (R.Generations = 20, "F=0 CR=0 gens");
      R := Minimize
        (Sphere'Access, B,
         Default_Parameters
           (F => 2.0, CR => 1.0, NP => 12, Max_Gen => 40, Seed => 3));
      Check (R.Best_Cost < 1.0, "F=2 CR=1 Sphere improves");
      Check (R.NP_Used = 12, "F=2 CR=1 NP");
   end;

   ---------------------------------------------------------------------
   Section ("18. Extra mutation / crossover algebra");
   ---------------------------------------------------------------------
   declare
      B : constant Bounds (1 .. 3) :=
        [(Lo => -10.0, Hi => 10.0),
         (Lo => -10.0, Hi => 10.0),
         (Lo => -10.0, Hi => 10.0)];
      V : Vector (1 .. 3);
      State : RNG_State;
      Trial : Vector (1 .. 3);
   begin
      V := Mutate_Rand1
        ([1.0, 1.0, 1.0], [2.0, 4.0, 6.0], [0.0, 0.0, 0.0], 0.5, B);
      Check (Approx (V (1), 2.0), "3D mutate x");
      Check (Approx (V (2), 3.0), "3D mutate y");
      Check (Approx (V (3), 4.0), "3D mutate z");

      Seed_RNG (State, 1);
      Trial := Binomial_Crossover
        ([0.0, 0.0, 0.0], [5.0, 5.0, 5.0], 0.0, 3, State);
      Check (Approx (Trial (3), 5.0), "3D CR=0 j_rand=3");
      Check (Approx (Trial (1), 0.0) and then Approx (Trial (2), 0.0),
             "3D CR=0 others target");
   end;

   New_Line;
   Put_Line
     ("Result: Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Put_Line ("ALL PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES (but Pass_Count < 80)");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
