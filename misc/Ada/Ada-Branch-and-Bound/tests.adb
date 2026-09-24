--  Standalone test suite for Branch_And_Bound (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Branch_And_Bound; use Branch_And_Bound;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Branch_And_Bound test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Caps and utilities");
   ---------------------------------------------------------------------
   declare
      P : Parameters := Default_Parameters;
      function Cap_Ok (C : Natural) return Boolean is (C <= Max_Capacity);
      function N_Ok (N : Natural) return Boolean is (N <= Max_Items);
   begin
      Check (N_Ok (32), "N_Ok accepts 32");
      Check (not N_Ok (33), "N_Ok rejects 33");
      Check (Cap_Ok (10_000), "Cap_Ok accepts 10000");
      Check (not Cap_Ok (10_001), "Cap_Ok rejects 10001");
      Check (P.Sort_By_Density, "Default Sort_By_Density");
      Check (not P.Verbose_Stats, "Default Verbose_Stats");
      P.Sort_By_Density := False;
      P.Verbose_Stats := True;
      Check (not P.Sort_By_Density, "Params mutable sort");
      Check (P.Verbose_Stats, "Params mutable verbose");
   end;

   declare
      W : constant Weight_Array := [2, 3, 4];
      V : constant Value_Array  := [3, 4, 5];
      S : constant Selection (1 .. 3) := [True, False, True];
      Z : constant Selection (1 .. 3) := [others => False];
   begin
      Check (Total_Weight (W, S) = 6, "Total_Weight selected");
      Check (Total_Value (V, S) = 8, "Total_Value selected");
      Check (Total_Weight (W, Z) = 0, "Total_Weight empty");
      Check (Total_Value (V, Z) = 0, "Total_Value empty");
      Check (Is_Feasible (W, S, 6), "Is_Feasible exact");
      Check (Is_Feasible (W, S, 10), "Is_Feasible room");
      Check (not Is_Feasible (W, S, 5), "Is_Feasible reject");
      Check (Approx (Density (10, 2), 5.0), "Density 10/2");
      Check (Approx (Density (0, 5), 0.0), "Density 0/5");
      Check (Density (5, 0) > 1.0E6, "Density infinite sentinel");
      Check (Approx (Density (0, 0), 0.0), "Density 0/0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Density_Order");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [4, 2, 3];
      V : constant Value_Array  := [4, 6, 3];  -- dens 1, 3, 1
      O : constant Index_Array := Density_Order (W, V);
   begin
      Check (O'Length = 3, "Order length 3");
      Check (O (1) = 2, "Highest density item 2 first");
      Check ((O (2) = 1 and O (3) = 3) or (O (2) = 3 and O (3) = 1),
             "Remaining items after densest");
      Check (Density (V (O (1)), W (O (1)))
               >= Density (V (O (2)), W (O (2))),
             "Order nonincreasing dens 1-2");
      Check (Density (V (O (2)), W (O (2)))
               >= Density (V (O (3)), W (O (3))),
             "Order nonincreasing dens 2-3");
   end;

   declare
      W : constant Weight_Array := [1];
      V : constant Value_Array  := [9];
      O : constant Index_Array := Density_Order (W, V);
   begin
      Check (O'Length = 1 and then O (1) = 1, "Order singleton");
   end;

   ---------------------------------------------------------------------
   Section ("3. Fractional_Bound (Dantzig) correctness");
   ---------------------------------------------------------------------
   declare
      --  Classic: items (w,v)=(2,6),(3,5),(4,4) dens 3, 5/3, 1; C=5
      --  Take item1 (2,6), then 3/3 of item2 -> +5; bound = 11
      W : constant Weight_Array := [2, 3, 4];
      V : constant Value_Array  := [6, 5, 4];
      B : constant Real := Fractional_Bound (W, V, 5);
   begin
      Check (Approx (B, 11.0), "Dantzig bound classic = 11");
      Check (B >= 6.0, "Bound >= best single item");
      Check (B >= Real (Knapsack_Exhaustive (W, V, 5).Best_Value),
             "Bound >= exhaustive optimum");
   end;

   declare
      W : constant Weight_Array := [5, 5, 5];
      V : constant Value_Array  := [10, 10, 10];
      B : constant Real := Fractional_Bound (W, V, 5);
   begin
      Check (Approx (B, 10.0), "Bound one full item C=5");
   end;

   declare
      W : constant Weight_Array := [10];
      V : constant Value_Array  := [7];
      B : constant Real := Fractional_Bound (W, V, 5);
   begin
      Check (Approx (B, 3.5), "Pure fractional half item");
   end;

   declare
      W : constant Weight_Array := [1, 1, 1];
      V : constant Value_Array  := [5, 4, 3];
      B : constant Real := Fractional_Bound (W, V, 2);
   begin
      Check (Approx (B, 9.0), "Bound take two densest");
   end;

   declare
      W : constant Weight_Array := [3, 3];
      V : constant Value_Array  := [9, 6];
      Ord : constant Index_Array := Density_Order (W, V);
      B0  : constant Real :=
        Fractional_Bound (W, V, Ord, 1, 0);
      B1  : constant Real :=
        Fractional_Bound (W, V, Ord, Ord'Last + 1, 10);
   begin
      Check (Approx (B0, 0.0), "Bound zero capacity");
      Check (Approx (B1, 0.0), "Bound past last position");
   end;

   declare
      W : constant Weight_Array := [2, 2, 2, 2];
      V : constant Value_Array  := [5, 4, 3, 2];
      B : constant Real := Fractional_Bound (W, V, 5);
      --  take 2+2, then 1/2 of next densest remaining: 5+4+1.5=10.5
   begin
      Check (Approx (B, 10.5), "Bound with fractional remainder");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tiny optima match exhaustive");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 3, 4, 5];
      V : constant Value_Array  := [3, 4, 5, 6];
      Cap : constant Natural := 5;
      E : constant Result := Knapsack_Exhaustive (W, V, Cap);
      B : constant Result := Solve_Knapsack_BnB (W, V, Cap);
   begin
      Check (E.Success and B.Success, "Tiny success flags");
      Check (E.Best_Value = B.Best_Value, "Tiny value match");
      Check (Is_Feasible (W, B.Selected (1 .. 4), Cap),
             "Tiny BnB feasible");
      Check (Total_Value (V, B.Selected (1 .. 4)) = B.Best_Value,
             "Tiny value consistent");
      Check (B.Nodes > 0, "Tiny nodes > 0");
   end;

   declare
      W : constant Weight_Array := [1, 2, 3];
      V : constant Value_Array  := [10, 10, 10];
      E : constant Result := Knapsack_Exhaustive (W, V, 3);
      B : constant Result := Branch_Knapsack (W, V, 3);
   begin
      Check (E.Best_Value = 20, "Exhaustive known 20");
      Check (B.Best_Value = E.Best_Value, "Alias Branch_Knapsack match");
   end;

   declare
      W : constant Weight_Array := [5, 4, 6, 3];
      V : constant Value_Array  := [10, 40, 30, 50];
      Cap : constant Natural := 10;
      E : constant Result := Knapsack_Exhaustive (W, V, Cap);
      B : constant Result := Solve_Knapsack_BnB (W, V, Cap);
   begin
      --  Optimal: items 2+4 = weight 7 value 90
      Check (E.Best_Value = 90, "Classic knapsack opt 90");
      Check (B.Best_Value = 90, "BnB finds 90");
      Check (B.Pruned > 0, "Pruning occurred on classic");
   end;

   declare
      W : constant Weight_Array := [2, 2, 2, 2, 2];
      V : constant Value_Array  := [2, 2, 2, 2, 2];
      E : constant Result := Knapsack_Exhaustive (W, V, 6);
      B : constant Result := Solve_Knapsack_BnB (W, V, 6);
   begin
      Check (E.Best_Value = 6, "Uniform opt 6");
      Check (B.Best_Value = 6, "BnB uniform 6");
   end;

   declare
      W : constant Weight_Array := [9, 8, 7];
      V : constant Value_Array  := [1, 1, 1];
      E : constant Result := Knapsack_Exhaustive (W, V, 5);
      B : constant Result := Solve_Knapsack_BnB (W, V, 5);
   begin
      Check (E.Best_Value = 0 and B.Best_Value = 0,
             "Nothing fits => 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Empty / singleton / edge cases");
   ---------------------------------------------------------------------
   declare
      W : Weight_Array (1 .. 0);
      V : Value_Array (1 .. 0);
      B : constant Result := Solve_Knapsack_BnB (W, V, 10);
      E : constant Result := Knapsack_Exhaustive (W, V, 10);
   begin
      Check (B.Best_Value = 0 and E.Best_Value = 0, "Empty instance 0");
      Check (B.N_Items = 0, "Empty N_Items");
      Check (B.Success, "Empty success");
   end;

   declare
      W : constant Weight_Array := [4];
      V : constant Value_Array  := [7];
      B1 : constant Result := Solve_Knapsack_BnB (W, V, 4);
      B0 : constant Result := Solve_Knapsack_BnB (W, V, 3);
   begin
      Check (B1.Best_Value = 7 and B1.Selected (1), "Singleton take");
      Check (B0.Best_Value = 0 and not B0.Selected (1), "Singleton skip");
   end;

   declare
      W : constant Weight_Array := [0, 3];
      V : constant Value_Array  := [5, 4];
      B : constant Result := Solve_Knapsack_BnB (W, V, 3);
   begin
      Check (B.Best_Value = 9, "Zero-weight item taken");
      Check (B.Selected (1), "Zero-weight selected");
   end;

   declare
      W : constant Weight_Array := [1, 1];
      V : constant Value_Array  := [0, 0];
      B : constant Result := Solve_Knapsack_BnB (W, V, 5);
   begin
      Check (B.Best_Value = 0, "Zero values => 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Pruning and node stats");
   ---------------------------------------------------------------------
   declare
      --  High-density first item dominates; many prune opportunities.
      W : constant Weight_Array :=
        [1, 5, 5, 5, 5, 5, 5, 5];
      V : constant Value_Array :=
        [100, 1, 1, 1, 1, 1, 1, 1];
      B : constant Result := Solve_Knapsack_BnB (W, V, 10);
      E : constant Result := Knapsack_Exhaustive (W, V, 10);
   begin
      Check (B.Best_Value = E.Best_Value, "Dominated match exhaustive");
      Check (B.Best_Value = 101, "Dominated value 101");
      Check (B.Pruned > 0, "Dominated prune > 0");
      Check (B.Nodes < 2 ** 8, "Nodes less than full tree 256");
      Check (B.Nodes > B.Pruned, "Nodes > Pruned");
   end;

   declare
      W : constant Weight_Array :=
        [2, 3, 4, 5, 9, 8, 7, 6];
      V : constant Value_Array :=
        [6, 5, 4, 3, 2, 1, 10, 9];
      Cap : constant Natural := 15;
      With_Sort : constant Result :=
        Solve_Knapsack_BnB
          (W, V, Cap, (Sort_By_Density => True, Verbose_Stats => False));
      No_Sort : constant Result :=
        Solve_Knapsack_BnB
          (W, V, Cap, (Sort_By_Density => False, Verbose_Stats => False));
      E : constant Result := Knapsack_Exhaustive (W, V, Cap);
   begin
      Check (With_Sort.Best_Value = E.Best_Value, "Sorted matches exh");
      Check (No_Sort.Best_Value = E.Best_Value, "Unsorted matches exh");
      Check (With_Sort.Pruned > 0 or No_Sort.Pruned > 0,
             "Some pruning in either mode");
   end;

   ---------------------------------------------------------------------
   Section ("7. Larger random-ish batch vs exhaustive");
   ---------------------------------------------------------------------
   declare
      procedure Compare_One
        (W : Weight_Array; V : Value_Array; Cap : Natural; Label : String)
      is
         E : constant Result := Knapsack_Exhaustive (W, V, Cap);
         B : constant Result := Solve_Knapsack_BnB (W, V, Cap);
      begin
         Check (B.Best_Value = E.Best_Value, "Match " & Label);
         Check (Is_Feasible (W, B.Selected (1 .. W'Length), Cap),
                "Feasible " & Label);
         Check (Total_Value (V, B.Selected (1 .. W'Length)) = B.Best_Value,
                "Value ok " & Label);
      end Compare_One;
   begin
      Compare_One ([1, 2, 3, 4, 5, 6], [1, 2, 3, 4, 5, 6], 10, "id6");
      Compare_One ([4, 5, 6, 2, 2, 3], [12, 10, 8, 7, 6, 5], 12, "mix6");
      Compare_One
        ([3, 3, 3, 3, 3, 3, 3],
         [1, 2, 3, 4, 5, 6, 7], 12, "eqw7");
      Compare_One
        ([10, 20, 30, 40, 15],
         [60, 100, 120, 140, 50], 50, "big5");
      Compare_One
        ([1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
         [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 5, "ten5");
   end;

   ---------------------------------------------------------------------
   Section ("8. Bound never below integer optimum");
   ---------------------------------------------------------------------
   declare
      procedure Bound_Ge_Opt
        (W : Weight_Array; V : Value_Array; Cap : Natural; Label : String)
      is
         Opt : constant Natural :=
           Knapsack_Exhaustive (W, V, Cap).Best_Value;
         Bnd : constant Real := Fractional_Bound (W, V, Cap);
      begin
         Check (Bnd + 1.0E-9 >= Real (Opt), "Bound>=opt " & Label);
      end Bound_Ge_Opt;
   begin
      Bound_Ge_Opt ([2, 3, 4], [3, 4, 5], 5, "a");
      Bound_Ge_Opt ([5, 4, 6, 3], [10, 40, 30, 50], 10, "b");
      Bound_Ge_Opt ([1, 2, 3, 4, 5], [5, 4, 3, 2, 1], 7, "c");
      Bound_Ge_Opt ([8, 8, 8], [10, 10, 10], 20, "d");
      Bound_Ge_Opt ([1], [100], 0, "e");
   end;

   ---------------------------------------------------------------------
   Section ("9. Same_Selection and selection consistency");
   ---------------------------------------------------------------------
   declare
      A : Selection (1 .. Max_Items) := [others => False];
      B : Selection (1 .. Max_Items) := [others => False];
   begin
      A (1) := True;
      A (3) := True;
      B (1) := True;
      B (3) := True;
      Check (Same_Selection (A, B, 4), "Same_Selection equal");
      B (2) := True;
      Check (not Same_Selection (A, B, 4), "Same_Selection differ");
      Check (Same_Selection (A, A, 0), "Same_Selection N=0");
   end;

   declare
      W : constant Weight_Array := [2, 3, 5];
      V : constant Value_Array  := [6, 5, 10];
      R : constant Result := Solve_Knapsack_BnB (W, V, 5);
   begin
      Check (R.Best_Weight = Total_Weight (W, R.Selected (1 .. 3)),
             "Best_Weight matches selection");
      Check (R.N_Items = 3, "N_Items=3");
      Check (R.Exact, "Exact flag");
   end;

   ---------------------------------------------------------------------
   Section ("10. Alias Branch_Knapsack identity");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [4, 3, 2, 1];
      V : constant Value_Array  := [5, 4, 3, 2];
      R1 : constant Result := Solve_Knapsack_BnB (W, V, 6);
      R2 : constant Result := Branch_Knapsack (W, V, 6);
   begin
      Check (R1.Best_Value = R2.Best_Value, "Alias same value");
      Check (Same_Selection (R1.Selected, R2.Selected, 4),
             "Alias same selection");
      Check (R1.Nodes = R2.Nodes, "Alias same nodes");
      Check (R1.Pruned = R2.Pruned, "Alias same pruned");
   end;

   ---------------------------------------------------------------------
   Section ("11. Capacity extremes and params");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [1, 2, 3];
      V : constant Value_Array  := [3, 2, 1];
      R0 : constant Result := Solve_Knapsack_BnB (W, V, 0);
      RB : constant Result :=
        Solve_Knapsack_BnB
          (W, V, 100,
           (Sort_By_Density => True, Verbose_Stats => True));
   begin
      Check (R0.Best_Value = 0, "Capacity 0 => 0");
      Check (RB.Best_Value = 6, "Large cap take all");
      Check (RB.Success, "Verbose params success");
   end;

   declare
      W : constant Weight_Array :=
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2];
      V : constant Value_Array :=
        [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
      Cap : constant Natural := 20;
      B : constant Result := Solve_Knapsack_BnB (W, V, Cap);
      E : constant Result := Knapsack_Exhaustive (W, V, Cap);
   begin
      Check (B.Best_Value = E.Best_Value, "n=12 match exhaustive");
      Check (B.Nodes > 0, "n=12 nodes counted");
      Check (Is_Feasible (W, B.Selected (1 .. 12), Cap), "n=12 feasible");
   end;

   ---------------------------------------------------------------------
   Section ("12. Bound monotonicity helpers");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 4, 6];
      V : constant Value_Array  := [5, 6, 7];
      B5  : constant Real := Fractional_Bound (W, V, 5);
      B10 : constant Real := Fractional_Bound (W, V, 10);
      B20 : constant Real := Fractional_Bound (W, V, 20);
   begin
      Check (B10 + 1.0E-12 >= B5, "Bound mono cap 10>=5");
      Check (B20 + 1.0E-12 >= B10, "Bound mono cap 20>=10");
      Check (Approx (B20, Real (5 + 6 + 7)), "Full capacity all items");
   end;

   declare
      W : constant Weight_Array := [1, 3, 5, 7];
      V : constant Value_Array  := [2, 5, 8, 11];
      B3 : constant Real := Fractional_Bound (W, V, 3);
      B6 : constant Real := Fractional_Bound (W, V, 6);
      R  : constant Result := Solve_Knapsack_BnB (W, V, 6);
      E  : constant Result := Knapsack_Exhaustive (W, V, 6);
   begin
      Check (B6 + 1.0E-12 >= B3, "extra mono 6>=3");
      Check (R.Best_Value = E.Best_Value, "extra n=4 match");
      Check (R.Nodes >= 1, "extra nodes>=1");
      Check (Approx (Density (11, 7), Real (11) / Real (7)), "dens 11/7");
   end;

   ---------------------------------------------------------------------
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
