--  Standalone test suite for Ant_Colony_Optimization (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ant_Colony_Optimization; use Ant_Colony_Optimization;

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

   --  Unit square: cities at (0,0),(1,0),(1,1),(0,1); optimal length 4.
   function Square_4 return Dist_Matrix is
      Pts : constant Point2_Array (1 .. 4) :=
        [1 => (0.0, 0.0), 2 => (1.0, 0.0),
         3 => (1.0, 1.0), 4 => (0.0, 1.0)];
   begin
      return Euclidean_Matrix (Pts);
   end Square_4;

   --  Regular-ish 5-cycle on a pentagon-like layout; known good length.
   function Five_Cities return Dist_Matrix is
      Pts : constant Point2_Array (1 .. 5) :=
        [1 => (0.0, 0.0),
         2 => (1.0, 0.0),
         3 => (1.2, 0.8),
         4 => (0.5, 1.2),
         5 => (-0.2, 0.7)];
   begin
      return Euclidean_Matrix (Pts);
   end Five_Cities;

begin
   Put_Line ("Ant_Colony_Optimization test suite");
   Put_Line ("===================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Default_Config");
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
      Check (Approx (Real (C.Alpha), 1.0), "Default Alpha");
      Check (Approx (Real (C.Beta), 2.0), "Default Beta");
      Check (Approx (Real (C.Rho), 0.5), "Default Rho");
      Check (Approx (Real (C.Q), 100.0), "Default Q");
      Check (C.N_Ants = 10, "Default N_Ants");
      Check (C.Max_Iterations = 100, "Default Max_Iterations");
      Check (C.Seed = 1, "Default Seed");
      Check (not C.Best_Only, "Default Best_Only False");
      Check (Approx (Real (C.Initial_Tau), 1.0), "Default Initial_Tau");
      C := Default_Config
        (Alpha => 0.5, Beta => 3.0, Rho => 0.1, Q => 10.0,
         N_Ants => 4, Max_Iterations => 7, Seed => 99,
         Best_Only => True, Initial_Tau => 0.25);
      Check (C.N_Ants = 4 and then C.Seed = 99, "Default_Config overrides");
      Check (C.Best_Only and then Approx (Real (C.Rho), 0.1),
             "Default_Config Best_Only/Rho");
      Check (Approx (Real (C.Alpha), 0.5) and then Approx (Real (C.Beta), 3.0),
             "Default_Config Alpha/Beta");
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
      Idx        : City_Index;
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
      for I in 1 .. 30 loop
         Idx := Next_Index (S1, 1, 4);
         Check (Idx in 1 .. 4, "Next_Index in 1..4 #" & Integer'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("3. Euclidean / Tour_Length / Is_Valid_Tour");
   ---------------------------------------------------------------------
   declare
      D    : constant Dist_Matrix := Square_4;
      Good : constant Tour := [1, 2, 3, 4];
      Bad  : constant Tour := [1, 3, 2, 4];
      Dup  : constant Tour := [1, 2, 2, 4];
      Len_G, Len_B : Non_Negative;
      Pts  : constant Point2_Array (1 .. 2) :=
        [1 => (0.0, 0.0), 2 => (3.0, 4.0)];
      D2   : constant Dist_Matrix := Euclidean_Matrix (Pts);
   begin
      Check (Approx (Real (Euclidean (Pts (1), Pts (2))), 5.0, 1.0E-9),
             "Euclidean 3-4-5");
      Check (Approx (Real (D2 (1, 2)), 5.0, 1.0E-9), "Euclidean_Matrix 3-4-5");
      Check (Approx (Real (D2 (2, 1)), 5.0, 1.0E-9), "Euclidean_Matrix symmetric");
      Check (Approx (Real (D2 (1, 1)), 0.0), "Euclidean diagonal 0");

      Check (Approx (Real (D (1, 2)), 1.0, 1.0E-9), "square side 1-2");
      Check (Approx (Real (D (1, 3)), 1.41421356237, 1.0E-5),
             "square diagonal 1-3");
      Len_G := Tour_Length (Good, D);
      Len_B := Tour_Length (Bad, D);
      Check (Near (Real (Len_G), 4.0, 0.02), "good square tour ~ 4");
      Check (Len_B > Len_G, "crossed tour longer than boundary");
      Check (Is_Valid_Tour (Good), "Good is valid permutation");
      Check (Is_Valid_Tour (Bad), "Bad still a permutation");
      Check (not Is_Valid_Tour (Dup), "duplicate city invalid");
   end;

   ---------------------------------------------------------------------
   Section ("4. Init_Pheromone / Build_Heuristic / Edge_Weight");
   ---------------------------------------------------------------------
   declare
      D   : constant Dist_Matrix := Square_4;
      Tau : Pheromone_Matrix (1 .. 4, 1 .. 4);
      Eta : Heuristic_Matrix (1 .. 4, 1 .. 4);
      W   : Non_Negative;
      All_Off_Diag : Boolean := True;
   begin
      Init_Pheromone (Tau, 0.75);
      for I in 1 .. 4 loop
         Check (Approx (Real (Tau (I, I)), 0.0),
                "tau diagonal 0 i=" & Integer'Image (I));
         for J in 1 .. 4 loop
            if I /= J then
               if not Approx (Real (Tau (I, J)), 0.75) then
                  All_Off_Diag := False;
               end if;
            end if;
         end loop;
      end loop;
      Check (All_Off_Diag, "Init_Pheromone off-diagonal = Initial");

      Eta := Build_Heuristic (D);
      Check (Approx (Real (Eta (1, 2)), 1.0, 1.0E-9), "eta side = 1/1");
      Check (Eta (1, 1) = Big_Heuristic, "eta diagonal = Big_Heuristic");
      Check (Eta (1, 3) < Eta (1, 2), "eta diagonal edge < side (farther)");

      W := Edge_Weight (1.0, 1.0, 1.0, 2.0);
      Check (Approx (Real (W), 1.0), "Edge_Weight 1^1 * 1^2");
      W := Edge_Weight (2.0, 3.0, 0.0, 0.0);
      Check (Approx (Real (W), 1.0), "Edge_Weight 0^0 convention -> 1");
      W := Edge_Weight (0.0, 5.0, 1.0, 1.0);
      Check (Approx (Real (W), 0.0), "Edge_Weight tau=0 -> 0");
      W := Edge_Weight (4.0, 2.0, 0.5, 1.0);
      Check (Approx (Real (W), 2.0 * 2.0, 1.0E-6),
             "Edge_Weight sqrt(4)*2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Transition probabilities sum to ~1");
   ---------------------------------------------------------------------
   declare
      D   : constant Dist_Matrix := Square_4;
      Tau : Pheromone_Matrix (1 .. 4, 1 .. 4);
      Eta : constant Heuristic_Matrix := Build_Heuristic (D);
      Vis : Tour (1 .. 4) := [1, 1, 1, 1];
      Sum : Real;
      P   : Unit_Interval;
   begin
      Init_Pheromone (Tau, 1.0);
      Vis (1) := 1;
      Sum := 0.0;
      for C in City_Index range 1 .. 4 loop
         P := Transition_Probability
           (From => 1, To => C, Tau => Tau, Eta => Eta,
            Visited => Vis, Visit_Count => 1,
            Alpha => 1.0, Beta => 2.0);
         if C = 1 then
            Check (Approx (Real (P), 0.0), "p to visited city = 0");
         end if;
         Sum := Sum + Real (P);
      end loop;
      Check (Approx (Sum, 1.0, 1.0E-9), "probabilities over unused sum to 1");

      --  After visiting two cities
      Vis (1) := 1;
      Vis (2) := 2;
      Sum := 0.0;
      for C in City_Index range 1 .. 4 loop
         P := Transition_Probability
           (1, C, Tau, Eta, Vis, 2, 1.0, 2.0);
         Sum := Sum + Real (P);
      end loop;
      Check (Approx (Sum, 1.0, 1.0E-9), "sum=1 with two visited");

      Vis (1) := 1;
      Vis (2) := 2;
      Vis (3) := 3;
      Sum := 0.0;
      for C in City_Index range 1 .. 4 loop
         P := Transition_Probability
           (3, C, Tau, Eta, Vis, 3, 1.0, 1.0);
         Sum := Sum + Real (P);
      end loop;
      Check (Approx (Sum, 1.0, 1.0E-9), "sum=1 with one remaining");
      P := Transition_Probability
        (3, 4, Tau, Eta, Vis, 3, 1.0, 1.0);
      Check (Approx (Real (P), 1.0, 1.0E-9), "only remaining has p=1");
   end;

   ---------------------------------------------------------------------
   Section ("6. Construct_Tour validity / reproducibility");
   ---------------------------------------------------------------------
   declare
      D     : constant Dist_Matrix := Square_4;
      Tau   : Pheromone_Matrix (1 .. 4, 1 .. 4);
      Eta   : constant Heuristic_Matrix := Build_Heuristic (D);
      State : RNG_State;
      T1, T2 : Tour (1 .. 4);
      Same  : Boolean := True;
      All_Valid : Boolean := True;
   begin
      Init_Pheromone (Tau, 1.0);
      Seed_RNG (State, 17);
      for K in 1 .. 20 loop
         Construct_Tour (T1, Tau, Eta, 1.0, 2.0, State);
         if not Is_Valid_Tour (T1) then
            All_Valid := False;
         end if;
         Check (Tour_Length (T1, D) > 0.0,
                "Construct_Tour positive length k=" & Integer'Image (K));
      end loop;
      Check (All_Valid, "20 Construct_Tour results are valid permutations");

      Seed_RNG (State, 42);
      Construct_Tour (T1, Tau, Eta, 1.0, 2.0, State);
      Seed_RNG (State, 42);
      Construct_Tour (T2, Tau, Eta, 1.0, 2.0, State);
      for I in 1 .. 4 loop
         if T1 (I) /= T2 (I) then
            Same := False;
         end if;
      end loop;
      Check (Same, "Construct_Tour reproducible with same seed");
   end;

   ---------------------------------------------------------------------
   Section ("7. Evaporation shrinks pheromone");
   ---------------------------------------------------------------------
   declare
      Tau : Pheromone_Matrix (1 .. 3, 1 .. 3);
      T   : constant Tour := [1, 2, 3];
      Before, After : Non_Negative;
   begin
      Init_Pheromone (Tau, 1.0);
      Before := Tau (1, 2);
      Update_Pheromone
        (Tau, T, Length => 10.0, Rho => 0.5, Q => 0.0, Deposit => False);
      After := Tau (1, 2);
      Check (Approx (Real (Before), 1.0), "before evaporate tau=1");
      Check (Approx (Real (After), 0.5, 1.0E-12), "rho=0.5 halves tau");
      Check (After < Before, "evaporation strictly shrinks");

      Init_Pheromone (Tau, 2.0);
      Update_Pheromone
        (Tau, T, Length => 10.0, Rho => 0.25, Q => 0.0, Deposit => True);
      --  evaporate to 1.5, deposit Q/L=0 so stays 1.5
      Check (Approx (Real (Tau (1, 2)), 1.5, 1.0E-12),
             "evaporate rho=0.25 with Q=0");

      Init_Pheromone (Tau, 1.0);
      Update_Pheromone
        (Tau, T, Length => 10.0, Rho => 0.0, Q => 10.0, Deposit => True);
      --  no evaporate; deposit 10/10=1 on edges of tour
      Check (Approx (Real (Tau (1, 2)), 2.0, 1.0E-12),
             "deposit adds Q/L on used edge");
      Check (Approx (Real (Tau (2, 1)), 2.0, 1.0E-12),
             "deposit symmetric");
      Check (Approx (Real (Tau (1, 3)), 2.0, 1.0E-12),
             "return edge also deposited");
   end;

   ---------------------------------------------------------------------
   Section ("8. Colony_Update best-only vs all");
   ---------------------------------------------------------------------
   declare
      Tau : Pheromone_Matrix (1 .. 4, 1 .. 4);
      Tours : Tour_Array (1 .. 2);
      Lens  : Length_Array (1 .. 2);
   begin
      --  Best: 1-2-3-4-1 ; Worse: 1-2-4-3-1
      --  Exclusive to worse (undirected): 2-4
      Tours (1) := [1, 2, 3, 4, others => 1];
      Tours (2) := [1, 2, 4, 3, others => 1];
      Lens (1) := 10.0;
      Lens (2) := 20.0;

      Init_Pheromone (Tau, 1.0);
      Colony_Update
        (Tau, 4, Tours, Lens, 2, Rho => 0.0, Q => 10.0,
         Best_Only => True, Best_Idx => 1);
      Check (Approx (Real (Tau (1, 2)), 2.0, 1.0E-12),
             "Best_Only deposits on best tour edge");
      Check (Approx (Real (Tau (2, 4)), 1.0, 1.0E-12),
             "Best_Only skips worse-only edge 2-4");

      Init_Pheromone (Tau, 1.0);
      Colony_Update
        (Tau, 4, Tours, Lens, 2, Rho => 0.0, Q => 10.0,
         Best_Only => False, Best_Idx => 1);
      Check (Tau (1, 2) > 1.0, "all-ants increases shared edge");
      Check (Approx (Real (Tau (2, 4)), 1.0 + 10.0 / 20.0, 1.0E-12),
             "all-ants deposits worse-only edge from ant2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Solve_TSP finds square optimum / improves");
   ---------------------------------------------------------------------
   declare
      D   : constant Dist_Matrix := Square_4;
      Cfg : Config;
      R   : Result;
      Opt : constant Non_Negative := 4.0;
   begin
      Cfg := Default_Config
        (Alpha => 1.0, Beta => 5.0, Rho => 0.5, Q => 100.0,
         N_Ants => 12, Max_Iterations => 40, Seed => 3,
         Best_Only => False, Initial_Tau => 1.0);
      R := Solve_TSP (D, Cfg);
      Check (R.N = 4, "Solve_TSP N=4");
      Check (R.Ants_Used = 12, "Solve_TSP Ants_Used");
      Check (R.Iterations = 40, "Solve_TSP Iterations");
      Check (Is_Valid_Tour (R.Best_Tour (1 .. 4)),
             "Solve_TSP best tour valid");
      Check (Approx (Real (R.Best_Length),
                     Real (Tour_Length (R.Best_Tour (1 .. 4), D)), 1.0E-9),
             "Best_Length matches Tour_Length");
      Check (Near (Real (R.Best_Length), Real (Opt), 0.05),
             "4-city square finds optimum ~4");
   end;

   declare
      --  Crossed start length is worse; AS should reach <= crossed and near opt
      D   : constant Dist_Matrix := Square_4;
      Crossed_Len : constant Non_Negative :=
        Tour_Length (Tour'(1, 3, 2, 4), D);
      Cfg : Config;
      R   : Result;
   begin
      Cfg := Default_Config
        (N_Ants => 8, Max_Iterations => 25, Seed => 11,
         Beta => 4.0, Best_Only => True);
      R := Solve_TSP (D, Cfg);
      Check (R.Best_Length <= Crossed_Len,
             "Solve_TSP best <= crossed length");
      Check (R.Best_Length < Crossed_Len
             or else Near (Real (R.Best_Length), 4.0, 0.05),
             "Solve_TSP improves or hits optimum");
   end;

   ---------------------------------------------------------------------
   Section ("10. Five-city Euclidean / Best_Only");
   ---------------------------------------------------------------------
   declare
      D   : constant Dist_Matrix := Five_Cities;
      Cfg : Config;
      R1, R2 : Result;
      Identity : constant Tour := [1, 2, 3, 4, 5];
      Id_Len : Non_Negative;
   begin
      Id_Len := Tour_Length (Identity, D);
      Cfg := Default_Config
        (N_Ants => 15, Max_Iterations => 50, Seed => 21,
         Alpha => 1.0, Beta => 3.0, Rho => 0.4, Q => 50.0);
      R1 := Solve_TSP (D, Cfg);
      Check (R1.N = 5, "5-city N=5");
      Check (Is_Valid_Tour (R1.Best_Tour (1 .. 5)), "5-city tour valid");
      Check (R1.Best_Length <= Id_Len + 1.0E-9,
             "5-city best <= identity tour");
      Check (R1.Best_Length > 0.0, "5-city positive length");

      Cfg.Best_Only := True;
      Cfg.Seed := 22;
      R2 := Solve_TSP (D, Cfg);
      Check (Is_Valid_Tour (R2.Best_Tour (1 .. 5)),
             "5-city Best_Only tour valid");
      Check (R2.Best_Length <= Id_Len + 1.0E-9,
             "5-city Best_Only <= identity");
   end;

   ---------------------------------------------------------------------
   Section ("11. Tiny 2-city / 3-city edge cases");
   ---------------------------------------------------------------------
   declare
      D2 : constant Dist_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [0.0, 3.0], 2 => [3.0, 0.0]];
      D3 : constant Dist_Matrix (1 .. 3, 1 .. 3) :=
        [1 => [0.0, 1.0, 1.0],
         2 => [1.0, 0.0, 1.0],
         3 => [1.0, 1.0, 0.0]];
      R : Result;
      Cfg : constant Config := Default_Config
        (N_Ants => 3, Max_Iterations => 5, Seed => 1);
   begin
      R := Solve_TSP (D2, Cfg);
      Check (R.N = 2, "2-city N");
      Check (Near (Real (R.Best_Length), 6.0, 1.0E-9),
             "2-city length = 2*3");
      Check (Is_Valid_Tour (R.Best_Tour (1 .. 2)), "2-city valid");

      R := Solve_TSP (D3, Cfg);
      Check (R.N = 3, "3-city N");
      Check (Near (Real (R.Best_Length), 3.0, 1.0E-9),
             "3-city equilateral length 3");
      Check (Is_Valid_Tour (R.Best_Tour (1 .. 3)), "3-city valid");
   end;

   ---------------------------------------------------------------------
   Section ("12. Max_Iterations=0 acts as one pass / seed sensitivity");
   ---------------------------------------------------------------------
   declare
      D : constant Dist_Matrix := Square_4;
      C0 : constant Config := Default_Config
        (N_Ants => 5, Max_Iterations => 0, Seed => 8);
      C1 : constant Config := Default_Config
        (N_Ants => 5, Max_Iterations => 15, Seed => 8);
      C2 : constant Config := Default_Config
        (N_Ants => 5, Max_Iterations => 15, Seed => 9);
      R0, R1, R2 : Result;
   begin
      R0 := Solve_TSP (D, C0);
      Check (R0.Iterations = 1, "Max_Iterations=0 -> one iteration");
      Check (Is_Valid_Tour (R0.Best_Tour (1 .. 4)), "zero-iter tour valid");

      R1 := Solve_TSP (D, C1);
      R2 := Solve_TSP (D, C2);
      Check (R1.Iterations = 15 and then R2.Iterations = 15,
             "nonzero iteration budgets honored");
      Check (Near (Real (R1.Best_Length), 4.0, 0.1)
             or else Near (Real (R2.Best_Length), 4.0, 0.1),
             "at least one seed finds near-optimum");
   end;

   ---------------------------------------------------------------------
   Section ("13. Extra Edge_Weight / heuristic sanity grid");
   ---------------------------------------------------------------------
   declare
      Bases : constant array (1 .. 4) of Non_Negative :=
        [0.0, 1.0, 2.0, 0.5];
      Exps  : constant array (1 .. 3) of Non_Negative := [0.0, 1.0, 2.0];
      W : Non_Negative;
   begin
      for Bi in Bases'Range loop
         for Ei in Exps'Range loop
            W := Edge_Weight (Bases (Bi), 1.0, Exps (Ei), 0.0);
            Check (W >= 0.0,
                   "Edge_Weight nonneg b=" & Integer'Image (Bi)
                   & " e=" & Integer'Image (Ei));
         end loop;
      end loop;
      Check (Approx (Real (Edge_Weight (9.0, 1.0, 0.5, 0.0)), 3.0, 1.0E-6),
             "sqrt(9)=3");
      Check (Approx (Real (Edge_Weight (1.0, 4.0, 0.0, 0.5)), 2.0, 1.0E-6),
             "eta^0.5 with alpha0");
   end;

   New_Line;
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
