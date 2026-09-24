--  Standalone test suite for Grasp (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Grasp; use Grasp;

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

   function Same_Selection (A, B : Selection) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Selection;

   function RCL_Contains (List : RCL; Item : Natural) return Boolean is
   begin
      for K in 1 .. List.Count loop
         if List.Items (K) = Item then
            return True;
         end if;
      end loop;
      return False;
   end RCL_Contains;

begin
   Put_Line ("Grasp test suite");
   Put_Line ("================");

   ---------------------------------------------------------------------
   Section ("1. Default_Parameters / Near / RNG");
   ---------------------------------------------------------------------
   declare
      P          : Parameters;
      S1, S2, S3 : RNG_State;
      A, B, C    : Natural;
      U          : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      Prev       : Natural := 0;
   begin
      P := Default_Parameters;
      Check (Near (P.Alpha, 0.3), "default Alpha 0.3");
      Check (P.Max_Iterations = 50, "default Max_Iterations 50");
      Check (P.Seed = 1, "default Seed 1");
      P := Default_Parameters (Alpha => 0.0, Max_Iterations => 10, Seed => 42);
      Check (Near (P.Alpha, 0.0), "custom Alpha 0");
      Check (P.Max_Iterations = 10, "custom iters");
      Check (P.Seed = 42, "custom seed");

      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near unequal");
      Check (Near (1.0, 1.0 + 1.0E-13), "Near within tol");

      Seed_RNG (S1, 1);
      Seed_RNG (S2, 1);
      Seed_RNG (S3, 2);
      A := Next_Natural (S1, 1, 100);
      B := Next_Natural (S2, 1, 100);
      C := Next_Natural (S3, 1, 100);
      Check (A = B, "same seed → same first draw");
      --  Different seed should diverge within a few draws
      declare
         Differ : Boolean := A /= C;
      begin
         for K in 1 .. 20 loop
            if Next_Natural (S1, 0, 1_000_000)
              /= Next_Natural (S3, 0, 1_000_000)
            then
               Differ := True;
            end if;
         end loop;
         Check (Differ, "diff seed eventually diverges");
      end;
      Seed_RNG (S1, 1);
      Seed_RNG (S2, 1);
      declare
         A1 : constant Natural := Next_Natural (S1, 0, 10);
         B1 : constant Natural := Next_Natural (S2, 0, 10);
         A2 : constant Natural := Next_Natural (S1, 0, 10);
         B2 : constant Natural := Next_Natural (S2, 0, 10);
      begin
         Check (A1 = B1 and then A2 = B2,
                "same seed → matching first two draws");
      end;

      Seed_RNG (S1, 7);
      for K in 1 .. 40 loop
         A := Next_Natural (S1, 3, 8);
         if A < 3 or else A > 8 then
            All_In := False;
         end if;
         if K > 1 and then A /= Prev then
            Saw_Diff := True;
         end if;
         Prev := A;
      end loop;
      Check (All_In, "Next_Natural stays in [Lo,Hi]");
      Check (Saw_Diff, "Next_Natural varies");

      Seed_RNG (S1, 9);
      U := Next_Unit (S1);
      Check (U >= 0.0 and then U < 1.0 + 1.0E-9, "Next_Unit in [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("2. Greedy_Score / totals / feasibility");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 3, 4, 5];
      V : constant Value_Array  := [3, 4, 5, 6];
      S : constant Selection (1 .. 4) := [True, True, False, False];
      Z : constant Selection (1 .. 4) := [others => False];
   begin
      Check (Near (Greedy_Score (10, 2), 5.0), "score 10/2=5");
      Check (Near (Greedy_Score (6, 0), 6.0), "score zero weight → value");
      Check (Near (Greedy_Score (0, 5), 0.0), "score zero value");
      Check (Total_Weight (W, S) = 5, "total weight 2+3");
      Check (Total_Value (V, S) = 7, "total value 3+4");
      Check (Total_Weight (W, Z) = 0, "empty weight");
      Check (Total_Value (V, Z) = 0, "empty value");
      Check (Is_Feasible (W, S, 5), "feasible at capacity");
      Check (Is_Feasible (W, S, 100), "feasible large cap");
      Check (not Is_Feasible (W, S, 4), "infeasible underweight");
   end;

   ---------------------------------------------------------------------
   Section ("3. Build_RCL Alpha=0 vs Alpha=1");
   ---------------------------------------------------------------------
   declare
      Items  : constant RCL_Buffer (1 .. 4) := [10, 20, 30, 40];
      Scores : constant Score_Array (1 .. 4) := [1.0, 5.0, 3.0, 5.0];
      List0  : RCL;
      List1  : RCL;
      ListH  : RCL;
   begin
      Build_RCL (Items, Scores, 4, 0.0, List0);
      Check (List0.Count = 2, "Alpha=0 → only max scores (2 ties)");
      Check (RCL_Contains (List0, 20), "Alpha=0 contains item 20");
      Check (RCL_Contains (List0, 40), "Alpha=0 contains item 40");
      Check (not RCL_Contains (List0, 10), "Alpha=0 excludes worst");
      Check (not RCL_Contains (List0, 30), "Alpha=0 excludes mid");

      Build_RCL (Items, Scores, 4, 1.0, List1);
      Check (List1.Count = 4, "Alpha=1 → all candidates");
      Check (RCL_Contains (List1, 10)
               and RCL_Contains (List1, 20)
               and RCL_Contains (List1, 30)
               and RCL_Contains (List1, 40),
             "Alpha=1 contains every item");

      Build_RCL (Items, Scores, 4, 0.5, ListH);
      Check (ListH.Count >= 2, "Alpha=0.5 at least best tier");
      Check (RCL_Contains (ListH, 20) and RCL_Contains (ListH, 40),
             "Alpha=0.5 keeps max scores");
      --  threshold = 5 - 0.5*(5-1) = 3 → include 30 as well
      Check (RCL_Contains (ListH, 30), "Alpha=0.5 includes mid (>=3)");
      Check (not RCL_Contains (ListH, 10), "Alpha=0.5 excludes 1.0");

      Build_RCL (Items, Scores, 0, 0.5, List0);
      Check (List0.Count = 0, "empty candidate → empty RCL");
   end;

   ---------------------------------------------------------------------
   Section ("4. Build_RCL_Min (TSP-style)");
   ---------------------------------------------------------------------
   declare
      Items  : constant RCL_Buffer (1 .. 3) := [1, 2, 3];
      Scores : constant Score_Array (1 .. 3) := [4.0, 1.0, 2.0];
      List0  : RCL;
      List1  : RCL;
   begin
      Build_RCL_Min (Items, Scores, 3, 0.0, List0);
      Check (List0.Count = 1, "Min Alpha=0 → only nearest");
      Check (List0.Items (1) = 2, "Min Alpha=0 picks dist 1");

      Build_RCL_Min (Items, Scores, 3, 1.0, List1);
      Check (List1.Count = 3, "Min Alpha=1 → all");
   end;

   ---------------------------------------------------------------------
   Section ("5. Build_RCL_Knapsack / Pick_From_RCL");
   ---------------------------------------------------------------------
   declare
      --  scores: 3/2=1.5, 4/3≈1.333, 5/4=1.25, 6/5=1.2
      W    : constant Weight_Array := [2, 3, 4, 5];
      V    : constant Value_Array  := [3, 4, 5, 6];
      Sel  : Selection (1 .. 4) := [others => False];
      List : RCL;
      St   : RNG_State;
      Pick : Natural;
      Saw  : array (1 .. 4) of Boolean := [others => False];
   begin
      Build_RCL_Knapsack (W, V, Sel, 5, 0.0, List);
      Check (List.Count = 1, "KS RCL Alpha=0 only best ratio");
      Check (List.Items (1) = 1, "KS RCL Alpha=0 item 1 (1.5)");

      Build_RCL_Knapsack (W, V, Sel, 5, 1.0, List);
      Check (List.Count = 4, "KS RCL Alpha=1 all fit in rem=5");

      Build_RCL_Knapsack (W, V, Sel, 2, 1.0, List);
      Check (List.Count = 1, "KS RCL rem=2 only item wt 2");
      Check (List.Items (1) = 1, "KS RCL rem=2 → item 1");

      Sel (1) := True;
      Build_RCL_Knapsack (W, V, Sel, 3, 1.0, List);
      Check (List.Count = 1, "KS RCL after select; rem=3 → item 2");
      Check (List.Items (1) = 2, "KS RCL item 2");

      Build_RCL_Knapsack (W, V, Sel, 0, 1.0, List);
      Check (List.Count = 0, "KS RCL rem=0 empty");

      Sel := [others => False];
      Build_RCL_Knapsack (W, V, Sel, 100, 1.0, List);
      declare
         Ok : Boolean := True;
      begin
         Seed_RNG (St, 99);
         for K in 1 .. 80 loop
            Pick := Pick_From_RCL (List, St);
            if Pick not in 1 .. 4 then
               Ok := False;
            else
               Saw (Pick) := True;
            end if;
         end loop;
         Check (Ok, "80 picks stay in 1..4");
         Check (Saw (1) and Saw (2) and Saw (3) and Saw (4),
                "Alpha=1 picks eventually hit all items");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Construct_Solution feasibility");
   ---------------------------------------------------------------------
   declare
      W     : constant Weight_Array := [2, 3, 4, 5];
      V     : constant Value_Array  := [3, 4, 5, 6];
      St    : RNG_State;
      Sel   : Selection (1 .. 4);
      Cap   : constant Natural := 5;
   begin
      Seed_RNG (St, 1);
      Construct_Solution_Knapsack (W, V, Cap, 0.0, St, Sel);
      Check (Is_Feasible (W, Sel, Cap), "construct Alpha=0 feasible");
      Check (Total_Weight (W, Sel) <= Cap, "construct weight ≤ cap");
      Check (Total_Value (V, Sel) > 0, "construct Alpha=0 nonempty value");

      Seed_RNG (St, 2);
      Construct_Solution_Knapsack (W, V, Cap, 1.0, St, Sel);
      Check (Is_Feasible (W, Sel, Cap), "construct Alpha=1 feasible");

      Seed_RNG (St, 3);
      Construct_Solution_Knapsack (W, V, 0, 0.5, St, Sel);
      Check (Total_Weight (W, Sel) = 0, "construct cap=0 → empty");
      Check (Total_Value (V, Sel) = 0, "construct cap=0 → value 0");

      --  Pure greedy Alpha=0 on classic instance: pick item1 (ratio 1.5),
      --  rem=3 → pick item2 (ratio 4/3), rem=0. Value=7.
      Seed_RNG (St, 1);
      Construct_Solution_Knapsack (W, V, 5, 0.0, St, Sel);
      Check (Total_Value (V, Sel) = 7, "construct Alpha=0 → greedy 7");
      Check (Sel (1) and Sel (2) and not Sel (3) and not Sel (4),
             "construct Alpha=0 selects items 1+2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Local_Search nondecrease");
   ---------------------------------------------------------------------
   declare
      W        : constant Weight_Array := [2, 3, 4, 5];
      V        : constant Value_Array  := [3, 4, 5, 6];
      Sel      : Selection (1 .. 4) := [True, False, False, False];
      Before   : Natural;
      After    : Natural;
      Improves : Natural;
      --  Swap opportunity: select heavy low-value, free capacity for better
      W2 : constant Weight_Array := [5, 4, 3];
      V2 : constant Value_Array  := [1, 10, 9];
      S2 : Selection (1 .. 3) := [True, False, False];
      B2, A2 : Natural;
      Imp2   : Natural;
   begin
      Before := Total_Value (V, Sel);
      Local_Search_Knapsack (W, V, 5, Sel, Improves);
      After := Total_Value (V, Sel);
      Check (After >= Before, "LS value nondecrease");
      Check (Is_Feasible (W, Sel, 5), "LS stays feasible");
      Check (After = 7, "LS from {1} reaches 7");
      Check (Improves >= 1, "LS recorded improves");

      --  Already local opt {1,2}
      Sel := [True, True, False, False];
      Before := Total_Value (V, Sel);
      Local_Search_Knapsack (W, V, 5, Sel, Improves);
      After := Total_Value (V, Sel);
      Check (After = Before, "LS at local opt unchanged");
      Check (Improves = 0, "LS at opt zero improves");

      B2 := Total_Value (V2, S2);
      --  Cap 7: cannot add 2 or 3 onto {1}; swap drops 1→{2}, then add 3.
      Local_Search_Knapsack (W2, V2, 7, S2, Imp2);
      A2 := Total_Value (V2, S2);
      Check (A2 >= B2, "LS swap case nondecrease");
      Check (A2 = 19, "LS swap reaches 10+9");
      Check (not S2 (1) and S2 (2) and S2 (3), "LS swap drops item1");
      Check (Imp2 >= 1, "LS swap improves > 0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Seeded reproducibility");
   ---------------------------------------------------------------------
   declare
      W  : constant Weight_Array := [2, 3, 4, 5, 1];
      V  : constant Value_Array  := [3, 4, 5, 6, 2];
      P  : constant Parameters :=
             Default_Parameters (0.5, 20, 12345);
      R1 : Knapsack_Result;
      R2 : Knapsack_Result;
      R3 : Knapsack_Result;
   begin
      R1 := Grasp_Knapsack (W, V, 7, P);
      R2 := Grasp_Knapsack (W, V, 7, P);
      Check (R1.Best_Value = R2.Best_Value, "same seed → same best value");
      Check (R1.Best_Weight = R2.Best_Weight, "same seed → same weight");
      Check (Same_Selection
               (R1.Selected (1 .. 5), R2.Selected (1 .. 5)),
             "same seed → same selection");
      Check (R1.Iterations_Run = R2.Iterations_Run, "same iters run");
      Check (R1.Local_Improves = R2.Local_Improves, "same LS improves");

      R3 := Grasp_Knapsack
        (W, V, 7, Default_Parameters (0.5, 20, 99999));
      Check (R3.Iterations_Run = 20, "alt seed still runs 20");
      Check (R3.N_Items = 5, "alt seed N_Items 5");
   end;

   ---------------------------------------------------------------------
   Section ("9. Small knapsack optima (GRASP)");
   ---------------------------------------------------------------------
   declare
      --  Classic: w=2,3,4,5 v=3,4,5,6 C=5 → 7
      W1 : constant Weight_Array := [2, 3, 4, 5];
      V1 : constant Value_Array  := [3, 4, 5, 6];
      --  Textbook: w=1,2,3 v=6,10,12 C=5 → 22
      W2 : constant Weight_Array := [1, 2, 3];
      V2 : constant Value_Array  := [6, 10, 12];
      --  Single fit
      W3 : constant Weight_Array := [5];
      V3 : constant Value_Array  := [10];
      --  None fit
      W4 : constant Weight_Array := [10, 20];
      V4 : constant Value_Array  := [100, 200];
      R  : Knapsack_Result;
      P  : Parameters;
   begin
      P := Default_Parameters (0.2, 30, 1);
      R := Grasp_Knapsack (W1, V1, 5, P);
      Check (R.Best_Value = 7, "GRASP classic → 7");
      Check (R.Best_Weight = 5, "GRASP classic weight 5");
      Check (R.Selected (1) and R.Selected (2), "GRASP classic items 1+2");
      Check (R.N_Items = 4, "GRASP N_Items 4");
      Check (R.Iterations_Run = 30, "GRASP ran 30 iters");
      Check (Is_Feasible (W1, R.Selected (1 .. 4), 5),
             "GRASP classic feasible");

      R := Grasp_Knapsack (W2, V2, 5, Default_Parameters (0.3, 40, 7));
      Check (R.Best_Value = 22, "GRASP textbook → 22");
      Check (R.Selected (2) and R.Selected (3),
             "GRASP textbook items 2+3");

      R := Grasp_Knapsack (W2, V2, 1, Default_Parameters (0.0, 10, 1));
      Check (R.Best_Value = 6, "GRASP C=1 → 6");

      R := Grasp_Knapsack (W2, V2, 2, Default_Parameters (0.0, 10, 1));
      Check (R.Best_Value = 10, "GRASP C=2 → 10");

      R := Grasp_Knapsack (W2, V2, 3, Default_Parameters (0.5, 15, 1));
      Check (R.Best_Value = 16, "GRASP C=3 → 16");

      R := Grasp_Knapsack (W2, V2, 4, Default_Parameters (0.5, 15, 1));
      Check (R.Best_Value = 18, "GRASP C=4 → 18");

      R := Grasp_Knapsack (W3, V3, 5, Default_Parameters (1.0, 5, 1));
      Check (R.Best_Value = 10, "GRASP single fit");
      Check (R.Selected (1), "GRASP single selected");

      R := Grasp_Knapsack (W3, V3, 4, Default_Parameters (1.0, 5, 1));
      Check (R.Best_Value = 0, "GRASP single no fit");
      Check (not R.Selected (1), "GRASP single not selected");

      R := Grasp_Knapsack (W4, V4, 5, Default_Parameters (0.5, 5, 1));
      Check (R.Best_Value = 0, "GRASP none fit");

      R := Grasp_Knapsack (W1, V1, 0, Default_Parameters (0.5, 5, 1));
      Check (R.Best_Value = 0, "GRASP zero capacity");
   end;

   ---------------------------------------------------------------------
   Section ("10. Alpha extremes on GRASP");
   ---------------------------------------------------------------------
   declare
      W  : constant Weight_Array := [2, 3, 4, 5];
      V  : constant Value_Array  := [3, 4, 5, 6];
      R0 : Knapsack_Result;
      R1 : Knapsack_Result;
   begin
      R0 := Grasp_Knapsack (W, V, 5, Default_Parameters (0.0, 25, 11));
      R1 := Grasp_Knapsack (W, V, 5, Default_Parameters (1.0, 25, 11));
      Check (R0.Best_Value = 7, "Alpha=0 finds optimum 7");
      Check (R1.Best_Value = 7, "Alpha=1 finds optimum 7");
      Check (R0.Best_Construction <= R0.Best_Value,
             "construction ≤ final (Alpha=0)");
      Check (R1.Best_Construction <= R1.Best_Value,
             "construction ≤ final (Alpha=1)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Optional TSP 2-opt GRASP");
   ---------------------------------------------------------------------
   declare
      --  4 cities on a unit square: optimal tour length 4
      D4 : Dist_Matrix (1 .. 4, 1 .. 4);
      --  3 collinear-ish: simple
      D3 : Dist_Matrix (1 .. 3, 1 .. 3);
      St : RNG_State;
      T  : Tour (1 .. 4);
      Imp : Natural;
      R  : TSP_Result;
      Len_Before, Len_After : Non_Negative;
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            D4 (I, J) := 0.0;
         end loop;
      end loop;
      --  Square corners: (0,0)(1,0)(1,1)(0,1)
      D4 (1, 2) := 1.0; D4 (2, 1) := 1.0;
      D4 (2, 3) := 1.0; D4 (3, 2) := 1.0;
      D4 (3, 4) := 1.0; D4 (4, 3) := 1.0;
      D4 (4, 1) := 1.0; D4 (1, 4) := 1.0;
      D4 (1, 3) := Euclidean (0.0, 0.0, 1.0, 1.0);
      D4 (3, 1) := D4 (1, 3);
      D4 (2, 4) := Euclidean (1.0, 0.0, 0.0, 1.0);
      D4 (4, 2) := D4 (2, 4);

      Check (Near (Euclidean (0.0, 0.0, 3.0, 4.0), 5.0), "Euclidean 3-4-5");

      Seed_RNG (St, 1);
      Construct_Tour_NN_RCL (D4, 0.0, St, T);
      Check (T (1) = 1, "NN tour starts at 1");
      declare
         Seen : array (1 .. 4) of Boolean := [others => False];
         Ok   : Boolean := True;
      begin
         for K in 1 .. 4 loop
            if T (K) not in 1 .. 4 or else Seen (T (K)) then
               Ok := False;
            end if;
            Seen (T (K)) := True;
         end loop;
         Check (Ok, "NN tour is a permutation");
      end;

      --  Deliberately crossed tour 1-2-4-3 (uses diagonals?) —
      --  1-3-2-4 may be longer; use identity and reverse mid.
      T := [1, 3, 2, 4];
      Len_Before := Tour_Length (T, D4);
      Local_Search_2Opt (D4, T, Imp);
      Len_After := Tour_Length (T, D4);
      Check (Len_After <= Len_Before + 1.0E-9, "2-opt nonincrease");
      Check (Near (Len_After, 4.0, 1.0E-6), "2-opt reaches square opt 4");

      R := Grasp_TSP (D4, Default_Parameters (0.3, 20, 5));
      Check (Near (R.Best_Length, 4.0, 1.0E-6), "GRASP TSP square → 4");
      Check (R.N = 4, "TSP N=4");
      Check (R.Iterations_Run = 20, "TSP iters 20");

      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            if I = J then
               D3 (I, J) := 0.0;
            else
               D3 (I, J) := Real (abs (I - J));
            end if;
         end loop;
      end loop;
      R := Grasp_TSP (D3, Default_Parameters (0.0, 10, 1));
      Check (Near (R.Best_Length, 4.0, 1.0E-9),
             "TSP path 1-2-3-1 length 1+1+2=4");
   end;

   ---------------------------------------------------------------------
   Section ("12. Apply_2Opt / Tour_Length smoke");
   ---------------------------------------------------------------------
   declare
      D : Dist_Matrix (1 .. 4, 1 .. 4) := [others => [others => 1.0]];
      T : constant Tour (1 .. 4) := [1, 2, 3, 4];
      U : Tour (1 .. 4);
   begin
      for I in 1 .. 4 loop
         D (I, I) := 0.0;
      end loop;
      Check (Near (Tour_Length (T, D), 4.0), "unit complete K4 tour len 4");
      U := Apply_2Opt (T, 1, 3);
      --  Reverse 2..3 → [1,3,2,4]
      Check (U (1) = 1 and U (2) = 3 and U (3) = 2 and U (4) = 4,
             "2-opt reverse mid segment");
   end;

   ---------------------------------------------------------------------
   Section ("13. Caps / larger educational instance");
   ---------------------------------------------------------------------
   declare
      W : Weight_Array (1 .. 10);
      V : Value_Array (1 .. 10);
      R : Knapsack_Result;
   begin
      for I in 1 .. 10 loop
         W (I) := I;
         V (I) := I * 2;
      end loop;
      R := Grasp_Knapsack (W, V, 20, Default_Parameters (0.4, 40, 3));
      Check (R.Best_Value > 0, "10-item GRASP positive value");
      Check (Is_Feasible (W, R.Selected (1 .. 10), 20),
             "10-item feasible");
      Check (R.Best_Weight <= 20, "10-item weight ≤ 20");
      Check (Total_Value (V, R.Selected (1 .. 10)) = R.Best_Value,
             "Best_Value matches selection");
      Check (R.N_Items = 10, "10-item N_Items field");
      Check (R.Iterations_Run = 40, "10-item ran 40 iters");
   end;

   ---------------------------------------------------------------------
   Section ("14. Construction best ≤ final across seeds");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 3, 4, 5, 6, 1];
      V : constant Value_Array  := [3, 4, 5, 6, 7, 2];
      R : Knapsack_Result;
      Ok : Boolean := True;
   begin
      for Seed in 1 .. 8 loop
         R := Grasp_Knapsack
           (W, V, 10, Default_Parameters (0.35, 15, Seed));
         if R.Best_Construction > R.Best_Value then
            Ok := False;
         end if;
         if not Is_Feasible (W, R.Selected (1 .. 6), 10) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "8 seeds: construction ≤ final and feasible");
   end;

   New_Line;
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILURES");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
