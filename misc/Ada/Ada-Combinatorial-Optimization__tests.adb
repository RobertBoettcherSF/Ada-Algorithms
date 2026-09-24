--  Standalone test suite for Combinatorial_Optimization (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Combinatorial_Optimization; use Combinatorial_Optimization;

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

begin
   Put_Line ("Combinatorial_Optimization test suite");
   Put_Line ("=====================================");

   ---------------------------------------------------------------------
   Section ("1. Taxonomy problems");
   ---------------------------------------------------------------------
   declare
      Info : Problem_Info;
   begin
      Info := Classify_Problem (Knapsack);
      Check (Info.Implemented and not Info.Forthcoming,
             "Knapsack Implemented");
      Info := Classify_Problem (Assignment);
      Check (Info.Implemented and not Info.Forthcoming,
             "Assignment Implemented");
      Info := Classify_Problem (TSP);
      Check (Info.Implemented and not Info.Forthcoming,
             "TSP Implemented");
      Info := Classify_Problem (MST);
      Check (Info.Implemented and not Info.Forthcoming,
             "MST Implemented");
      Info := Classify_Problem (Set_Cover);
      Check (not Info.Implemented and Info.Forthcoming,
             "Set_Cover Forthcoming");
      Info := Classify_Problem (ILP);
      Check (not Info.Implemented and Info.Forthcoming,
             "ILP Forthcoming");

      for K in Problem_Kind loop
         Info := Classify_Problem (K);
         Check (Info.Kind = K, "Problem Kind matches " & Problem_Name (K));
         Check (Info.Implemented xor Info.Forthcoming,
                "Problem xor flags " & Problem_Name (K));
         Check (Implemented (K) = Info.Implemented,
                "Implemented fn " & Problem_Name (K));
         Check (Forthcoming (K) = Info.Forthcoming,
                "Forthcoming fn " & Problem_Name (K));
      end loop;

      Check (Problem_Name (Knapsack) = "Knapsack", "Problem_Name Knapsack");
      Check (Problem_Name (ILP) = "ILP", "Problem_Name ILP");
   end;

   ---------------------------------------------------------------------
   Section ("2. Taxonomy methods");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
   begin
      Info := Classify_Method (Exhaustive);
      Check (Info.Implemented and not Info.Forthcoming,
             "Exhaustive Implemented");
      Info := Classify_Method (Dynamic_Programming);
      Check (Info.Implemented and not Info.Forthcoming,
             "DP Implemented");
      Info := Classify_Method (Greedy);
      Check (Info.Implemented and not Info.Forthcoming,
             "Greedy Implemented");
      Info := Classify_Method (Local_Search);
      Check (Info.Implemented and not Info.Forthcoming,
             "Local_Search Implemented");
      Info := Classify_Method (Branch_and_Bound);
      Check (not Info.Implemented and Info.Forthcoming,
             "Branch_and_Bound Forthcoming");
      Info := Classify_Method (GRASP);
      Check (not Info.Implemented and Info.Forthcoming,
             "GRASP Forthcoming");
      Info := Classify_Method (Hungarian);
      Check (not Info.Implemented and Info.Forthcoming,
             "Hungarian Forthcoming");
      Info := Classify_Method (Metaheuristic);
      Check (not Info.Implemented and Info.Forthcoming,
             "Metaheuristic Forthcoming");

      for K in Method_Kind loop
         Info := Classify_Method (K);
         Check (Info.Kind = K, "Method Kind matches " & Method_Name (K));
         Check (Info.Implemented xor Info.Forthcoming,
                "Method xor flags " & Method_Name (K));
         Check (Implemented (K) = Info.Implemented,
                "Method Implemented fn " & Method_Name (K));
         Check (Forthcoming (K) = Info.Forthcoming,
                "Method Forthcoming fn " & Method_Name (K));
      end loop;

      Check (Method_Name (Hungarian) = "Hungarian", "Method_Name Hungarian");
      Check (Method_Name (GRASP) = "GRASP", "Method_Name GRASP");
   end;

   ---------------------------------------------------------------------
   Section ("3. Knapsack utilities / DP / exhaustive / greedy");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 3, 4, 5];
      V : constant Value_Array  := [3, 4, 5, 6];
      Cap : constant Capacity_Range := 5;
      R_DP  : Knapsack_Result;
      R_Ex  : Knapsack_Result;
      R_Gr  : Knapsack_Result;
      Sel   : Selection (1 .. 4);
   begin
      --  undo mistaken check above by not relying on it; fresh checks:
      Sel := [True, True, False, False];
      Check (Total_Weight (W, Sel) = 5, "Total_Weight selected=5");
      Check (Total_Value (V, Sel) = 7, "Total_Value selected=7");
      Check (Is_Feasible (W, Sel, Cap), "feasible under Cap=5");
      Sel (3) := True;
      Check (not Is_Feasible (W, Sel, Cap), "infeasible with item3");

      Check (Density (6, 3) = 2.0, "Density 6/3=2");
      Check (Density (0, 0) = 0.0, "Density 0/0=0");
      Check (Density (5, 0) > 1.0E8, "Density free positive large");

      R_DP := Knapsack_DP (W, V, Cap);
      Check (R_DP.Exact, "DP Exact flag");
      Check (R_DP.Best_Value = 7, "DP optimum value 7");
      Check (R_DP.Best_Weight = 5, "DP optimum weight 5");
      Check (R_DP.Selected (1) and R_DP.Selected (2),
             "DP selects items 1,2");
      Check (not R_DP.Selected (3) and not R_DP.Selected (4),
             "DP rejects 3,4");

      R_Ex := Knapsack_Exhaustive (W, V, Cap);
      Check (R_Ex.Exact, "Exhaustive Exact");
      Check (R_Ex.Best_Value = 7, "Exhaustive value 7");
      Check (R_Ex.Best_Weight = 5, "Exhaustive weight 5");
      Check (R_Ex.Best_Value = R_DP.Best_Value, "DP matches exhaustive");

      R_Gr := Knapsack_Greedy_Density (W, V, Cap);
      Check (not R_Gr.Exact, "Greedy not Exact");
      Check (R_Gr.Best_Value <= 7, "Greedy <= optimum");
      Check (R_Gr.Best_Weight <= Cap, "Greedy feasible weight");
      Check (Is_Feasible (W, R_Gr.Selected (1 .. 4), Cap),
             "Greedy selection feasible");
   end;

   declare
      --  Classic: weights 1,2,3 values 6,10,12 capacity 5 → opt 22 (1+2)
      W : constant Weight_Array := [1, 2, 3];
      V : constant Value_Array  := [6, 10, 12];
      R : Knapsack_Result;
   begin
      R := Knapsack_DP (W, V, 5);
      Check (R.Best_Value = 22, "DP classic value 22");
      --  Optimum is items 2+3 (w=5,v=22), not 1+2 (v=16)
      Check (not R.Selected (1) and R.Selected (2) and R.Selected (3),
             "DP classic items 2+3");
      R := Knapsack_Exhaustive (W, V, 5);
      Check (R.Best_Value = 22, "Exhaustive classic 22");
      R := Knapsack_Greedy_Density (W, V, 5);
      --  densities 6,5,4 → takes 1 then 2 → value 16 (suboptimal)
      Check (R.Best_Value = 16, "Greedy classic suboptimal 16");
   end;

   declare
      --  Greedy suboptimal: w=[2,3,3] v=[6,6,6] C=5
      --  density all 2 or 3/3=2; order may take first 2 then stuck (val 6)
      --  opt is one of the 3-weight items? weight 3 value 6; or item1 only=6
      --  Better example: w=[5,4,4] v=[10,6,6] C=8
      --  density: 2.0, 1.5, 1.5 → greedy takes item1 only value 10
      --  opt: two 4's value 12
      W : constant Weight_Array := [5, 4, 4];
      V : constant Value_Array  := [10, 6, 6];
      R_DP, R_Gr : Knapsack_Result;
   begin
      R_DP := Knapsack_DP (W, V, 8);
      R_Gr := Knapsack_Greedy_Density (W, V, 8);
      Check (R_DP.Best_Value = 12, "DP beats greedy instance opt 12");
      Check (R_Gr.Best_Value = 10, "Greedy suboptimal 10");
      Check (R_Gr.Best_Value < R_DP.Best_Value,
             "Greedy strictly below DP");
   end;

   declare
      W : constant Weight_Array := [10];
      V : constant Value_Array  := [100];
      R : Knapsack_Result;
   begin
      R := Knapsack_DP (W, V, 5);
      Check (R.Best_Value = 0, "DP empty when item too heavy");
      R := Knapsack_DP (W, V, 10);
      Check (R.Best_Value = 100, "DP single item fits");
      Check (R.Selected (1), "DP selects sole item");
   end;

   ---------------------------------------------------------------------
   Section ("4. MST Kruskal");
   ---------------------------------------------------------------------
   declare
      --  Triangle 1-2:1, 2-3:2, 1-3:4 → MST weight 3 (edges 1-2,2-3)
      C : Cost_Matrix (1 .. 3, 1 .. 3) := [others => [others => No_Edge]];
      R : MST_Result;
   begin
      C (1, 2) := 1; C (2, 1) := 1;
      C (2, 3) := 2; C (3, 2) := 2;
      C (1, 3) := 4; C (3, 1) := 4;
      R := MST_Kruskal (C, 3);
      Check (R.Success, "MST triangle connected");
      Check (R.Edge_Count = 2, "MST triangle 2 edges");
      Check (R.Total_Weight = 3, "MST triangle weight 3");
   end;

   declare
      --  Path 4 vertices weights 1,2,3
      C : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => No_Edge]];
      R : MST_Result;
   begin
      C (1, 2) := 1; C (2, 1) := 1;
      C (2, 3) := 2; C (3, 2) := 2;
      C (3, 4) := 3; C (4, 3) := 3;
      C (1, 4) := 100; C (4, 1) := 100;
      R := MST_Kruskal (C, 4);
      Check (R.Success, "MST path connected");
      Check (R.Edge_Count = 3, "MST path 3 edges");
      Check (R.Total_Weight = 6, "MST path weight 6");
   end;

   declare
      C : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[No_Edge, 5, No_Edge],
         [5, No_Edge, No_Edge],
         [No_Edge, No_Edge, No_Edge]];
      R : MST_Result;
   begin
      --  vertex 3 isolated
      R := MST_Kruskal (C, 3);
      Check (not R.Success, "MST disconnected Success=False");
      Check (R.Edge_Count = 1, "MST forest one edge");
   end;

   declare
      C : constant Cost_Matrix (1 .. 1, 1 .. 1) := [others => [others => No_Edge]];
      R : MST_Result;
   begin
      R := MST_Kruskal (C, 1);
      Check (R.Success, "MST single vertex Success");
      Check (R.Edge_Count = 0, "MST single no edges");
      Check (R.Total_Weight = 0, "MST single weight 0");
   end;

   declare
      --  K4 with known MST: edges sorted
      C : Cost_Matrix (1 .. 4, 1 .. 4) := [others => [others => No_Edge]];
      R : MST_Result;
   begin
      C (1, 2) := 1; C (2, 1) := 1;
      C (1, 3) := 4; C (3, 1) := 4;
      C (1, 4) := 3; C (4, 1) := 3;
      C (2, 3) := 2; C (3, 2) := 2;
      C (2, 4) := 5; C (4, 2) := 5;
      C (3, 4) := 6; C (4, 3) := 6;
      --  Kruskal: 1-2(1), 2-3(2), 1-4(3) = 6
      R := MST_Kruskal (C, 4);
      Check (R.Success, "MST K4 Success");
      Check (R.Total_Weight = 6, "MST K4 weight 6");
   end;

   ---------------------------------------------------------------------
   Section ("5. Assignment");
   ---------------------------------------------------------------------
   declare
      C : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[9, 2, 7],
         [6, 4, 3],
         [5, 8, 1]];
      --  identity cost 9+4+1=14; optimum 2,1,3 → 2+6+1=9
      Identity : constant Permutation (1 .. 3) := [1, 2, 3];
      Best_Perm : constant Permutation (1 .. 3) := [2, 1, 3];
      Near_Best : constant Permutation (1 .. 3) := [2, 3, 1];
      R : Assignment_Result;
   begin
      Check (Is_Permutation (Identity, 3), "identity is permutation");
      Check (Is_Permutation (Best_Perm, 3), "best perm valid");
      Check (not Is_Permutation ([1, 1, 2], 3), "dup not permutation");
      Check (Assignment_Cost (C, Identity, 3) = 14,
             "Assignment_Cost identity 14");
      Check (Assignment_Cost (C, Best_Perm, 3) = 9,
             "Assignment_Cost best 9");
      Check (Assignment_Cost (C, Near_Best, 3) = 10,
             "Assignment_Cost near-best 10");

      R := Assignment_Brute_Force (C, 3);
      Check (R.Exact, "Brute assignment Exact");
      Check (R.N = 3, "Brute N=3");
      Check (R.Total = 9, "Brute optimum 9");
      Check (Is_Permutation (R.Mapping, 3), "Brute result permutation");
      Check (Assignment_Cost (C, R.Mapping, 3) = R.Total,
             "Brute cost matches mapping");
   end;

   declare
      C : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[1, 100], [100, 1]];
      R : Assignment_Result;
   begin
      R := Assignment_Brute_Force (C, 2);
      Check (R.Total = 2, "Assignment 2x2 opt 2");
      Check (R.Mapping (1) = 1 and R.Mapping (2) = 2,
             "Assignment 2x2 identity");
   end;

   declare
      C : constant Cost_Matrix (1 .. 1, 1 .. 1) := [[42]];
      R : Assignment_Result;
   begin
      R := Assignment_Brute_Force (C, 1);
      Check (R.Total = 42, "Assignment 1x1");
      Check (R.Mapping (1) = 1, "Assignment 1x1 map");
   end;

   declare
      C : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[0, 1, 2, 3],
         [1, 0, 1, 2],
         [2, 1, 0, 1],
         [3, 2, 1, 0]];
      R : Assignment_Result;
   begin
      R := Assignment_Brute_Force (C, 4);
      Check (R.Total = 0, "Assignment diagonal zeros");
   end;

   ---------------------------------------------------------------------
   Section ("6. TSP brute-force and 2-opt");
   ---------------------------------------------------------------------
   declare
      --  Square side 1: cities (0,0)(1,0)(1,1)(0,1) — use integer L1/grid
      --  Dist as Manhattan on unit square corners → opt tour length 4
      D : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[0, 1, 2, 1],
         [1, 0, 1, 2],
         [2, 1, 0, 1],
         [1, 2, 1, 0]];
      R : TSP_Result;
      T : Tour (1 .. 4);
   begin
      R := TSP_Brute_Force (D, 4);
      Check (R.Exact, "TSP brute Exact");
      Check (R.N = 4, "TSP N=4");
      Check (R.Best_Length = 4, "TSP square opt 4");
      Check (Tour_Length (D, R.Best_Tour, 4) = 4,
             "Tour_Length of best = 4");

      --  Degenerate start: 1-3-2-4 length 2+1+2+1=6, 2-opt should improve
      T := [1, 3, 2, 4];
      Check (Tour_Length (D, T, 4) = 6, "crossed tour length 6");
      R := TSP_Two_Opt (D, T, 4);
      Check (not R.Exact, "2-opt Exact=False");
      Check (R.Best_Length = 4, "2-opt reaches 4");
   end;

   declare
      D : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[0, 2, 2],
         [2, 0, 2],
         [2, 2, 0]];
      R : TSP_Result;
   begin
      R := TSP_Brute_Force (D, 3);
      Check (R.Best_Length = 6, "TSP triangle 6");
   end;

   declare
      D : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[0, 5], [5, 0]];
      R : TSP_Result;
   begin
      R := TSP_Brute_Force (D, 2);
      Check (R.Best_Length = 10, "TSP two cities roundtrip 10");
   end;

   declare
      D : Cost_Matrix (1 .. 5, 1 .. 5) := [others => [others => 1]];
      R : TSP_Result;
   begin
      for I in 1 .. 5 loop
         D (I, I) := 0;
      end loop;
      R := TSP_Brute_Force (D, 5);
      Check (R.Best_Length = 5, "TSP complete K5 unit opt 5");
   end;

   ---------------------------------------------------------------------
   Section ("7. Caps / names smoke");
   ---------------------------------------------------------------------
   declare
      PC : Natural := 0;
      MC : Natural := 0;
      Sample : Cost := 0;
   begin
      for K in Problem_Kind loop
         PC := PC + 1;
      end loop;
      for K in Method_Kind loop
         MC := MC + 1;
      end loop;
      Check (PC = 6, "six Problem_Kind values");
      Check (MC = 8, "eight Method_Kind values");
      Check (PC + MC = 14, "problem+method count 14");
      Sample := Cost (PC + MC);
      Check (Sample = 14, "Cost of taxonomy size");
      Check (No_Edge /= Sample, "No_Edge distinct from taxonomy size");
      Check (Implemented (Knapsack), "Implemented Knapsack smoke");
      Check (Forthcoming (ILP), "Forthcoming ILP smoke");
   end;

   ---------------------------------------------------------------------
   Section ("8. Extra DP / greedy / MST smoke");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 2, 2, 2];
      V : constant Value_Array  := [2, 2, 2, 2];
      R : Knapsack_Result;
   begin
      R := Knapsack_DP (W, V, 4);
      Check (R.Best_Value = 4, "DP four equal items value 4");
      Check (R.Best_Weight = 4, "DP four equal weight 4");
      R := Knapsack_Exhaustive (W, V, 3);
      Check (R.Best_Value = 2, "Exhaustive Cap3 value 2");
      --  Cap 3 can take only one item of weight 2 → value 2
      Check (R.Best_Weight = 2, "Exhaustive Cap3 weight 2");
   end;

   declare
      C : constant Cost_Matrix (1 .. 2, 1 .. 2) := [[No_Edge, 7], [7, No_Edge]];
      R : MST_Result;
   begin
      R := MST_Kruskal (C, 2);
      Check (R.Success and R.Total_Weight = 7, "MST two nodes weight 7");
   end;

   New_Line;
   Put_Line
     ("Result: Pass_Count="
      & Natural'Image (Pass_Count)
      & " Fail_Count="
      & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Put_Line ("ALL PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("ALL PASSED (but Pass_Count < 80)");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
