--  Standalone test suite for Delayed_Column_Generation (main program).

pragma Ada_2022;

with Ada.Text_IO;
with Delayed_Column_Generation; use Delayed_Column_Generation;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Default_Cfg : constant Config :=
     (Max_Iters => 64, Max_Columns => 64, Max_Pivots => 800, Tol => 1.0E-9);

begin
   Ada.Text_IO.Put_Line ("Delayed_Column_Generation test suite");
   Ada.Text_IO.Put_Line ("====================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Vec_Near");
   ---------------------------------------------------------------------
   declare
      U : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      W : constant Vector (1 .. 3) := [1.0, 2.0, 4.0];
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
      Check (Vec_Near (U, V), "Vec_Near equal");
      Check (not Vec_Near (U, W), "Vec_Near rejects");
      Check (Vec_Near (U, W, 1.5), "Vec_Near loose Tol");
      Check (not Near (1.0, 2.0, 0.1), "Near reject mid");
      Check (Near (1.0, 1.05, 0.1), "Near accept mid");
      Check (Near (0.0, 0.0), "Near zeros");
      Check (Near (-1.0E-12, 1.0E-12, 1.0E-10), "Near both tiny");
      Check (not Near (-1.0, 1.0), "Near opposite signs");
   end;

   ---------------------------------------------------------------------
   Section ("2. Pattern helpers / trivial columns");
   ---------------------------------------------------------------------
   declare
      Pool : Column_Pool;
      N_Cols : Column_Count;
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      C1, C2 : Pattern_Counts;
      Wrod : constant Width_Value := 5;
   begin
      Clear_Pool (Pool, N_Cols);
      Check (N_Cols = 0, "Clear_Pool empty");
      Check (not Pool (1).Valid, "Clear invalidates");

      Init_Trivial_Patterns (Pool, N_Cols, Widths, Wrod, 2);
      Check (N_Cols = 2, "trivial: 2 patterns");
      Check (Pool (1).Counts (1) = 2, "trivial item1: floor(5/2)=2");
      Check (Pool (1).Counts (2) = 0, "trivial item1 only");
      Check (Pool (2).Counts (2) = 1, "trivial item2: floor(5/3)=1");
      Check (Pool (2).Counts (1) = 0, "trivial item2 only");
      Check (Pattern_Width (Pool (1).Counts, Widths, 2) = 4,
             "width of (2,0)=4");
      Check (Pattern_Width (Pool (2).Counts, Widths, 2) = 3,
             "width of (0,1)=3");

      C1 := [1 => 1, 2 => 1, others => 0];
      C2 := [1 => 1, 2 => 1, others => 0];
      Check (Patterns_Equal (C1, C2, 2), "Patterns_Equal yes");
      C2 (2) := 0;
      Check (not Patterns_Equal (C1, C2, 2), "Patterns_Equal no");
      Check (not Pattern_Exists (Pool, N_Cols, C1, 2),
             "mixed pattern not in trivial pool");
      Add_Column (Pool, N_Cols, C1, 1.0);
      Check (N_Cols = 3, "Add_Column grows pool");
      Check (Pattern_Exists (Pool, N_Cols, C1, 2), "Pattern_Exists after add");
      Check (Approx (Reduced_Cost (C1, [0.5, 0.5], 2, 1.0), 0.0),
             "Reduced_Cost 1-0.5-0.5=0");
      Check (Approx (Reduced_Cost (C1, [0.6, 0.6], 2, 1.0), -0.2),
             "Reduced_Cost improving");
      Check (Reduced_Cost (Pool (1).Counts, [0.5, 1.0], 2) > -1.0E-9,
             "trivial (2,0) rc with π=(0.5,1)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Price_Knapsack correctness");
   ---------------------------------------------------------------------
   declare
      P : Pricing_Result;
      Duals : Vector (1 .. 2);
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
   begin
      Duals := [0.5, 1.0];
      P := Price_Knapsack (Duals, Widths, 5, 2, 1.0);
      Check (P.Feasible, "price feasible");
      Check (P.Improving, "π=(0.5,1) improving vs cost 1");
      Check (Approx (P.Value, 1.5), "best value (1,1)=1.5");
      Check (P.Counts (1) = 1 and then P.Counts (2) = 1,
             "pattern (1,1)");
      Check (Approx (P.Reduced_Cost, -0.5), "rc = 1-1.5");

      Duals := [0.5, 0.5];
      P := Price_Knapsack (Duals, Widths, 5, 2, 1.0);
      Check (not P.Improving, "π=(0.5,0.5) not improving");
      Check (P.Value <= 1.0 + 1.0E-9, "value ≤ 1");

      Duals := [1.0, 1.0];
      P := Price_Knapsack (Duals, Widths, 5, 2, 1.0);
      Check (P.Improving, "π=(1,1) improving");
      Check (P.Value >= 2.0 - 1.0E-9, "can pack value ≥ 2");

      --  Single item
      declare
         D1 : constant Vector (1 .. 1) := [0.4];
         W1 : constant Vector (1 .. 1) := [3.0];
      begin
         P := Price_Knapsack (D1, W1, 10, 1, 1.0);
         --  floor(10/3)=3, value=1.2 > 1 ⇒ improving
         Check (P.Improving, "three copies value 1.2");
         Check (P.Counts (1) = 3, "a1=3");
         Check (Approx (P.Value, 1.2), "value 1.2");
      end;

      Duals := [0.0, 0.0];
      P := Price_Knapsack (Duals, Widths, 5, 2, 1.0);
      Check (not P.Improving, "zero duals not improving");
      Check (Approx (P.Value, 0.0), "zero duals value 0");

      Duals := [0.3, 0.3];
      P := Price_Knapsack (Duals, Widths, 5, 2, 1.0);
      Check (not P.Improving, "small duals");
      Check (P.Value < 1.0, "value < 1");

      --  Exact boundary Value = Cost
      Duals := [0.5, 0.0];
      P := Price_Knapsack (Duals, Widths, 4, 2, 1.0);
      --  (2,0) value 1.0
      Check (Approx (P.Value, 1.0), "boundary value=1");
      Check (not P.Improving, "Value=Cost not improving");
   end;

   ---------------------------------------------------------------------
   Section ("4. Embedded simplex smoke / RMP tiny");
   ---------------------------------------------------------------------
   declare
      --  max 3x+5y s.t. x≤4, 2y≤12, 3x+2y≤18 → opt 36 at (2,6)
      A : constant Matrix (1 .. 3, 1 .. 2) :=
        [[1.0, 0.0],
         [0.0, 2.0],
         [3.0, 2.0]];
      B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
      C : constant Vector (1 .. 2) := [3.0, 5.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      R : RMP_Result;
      Cfg : constant Config := Default_Cfg;
   begin
      Check (Tab.M = 3, "tableau M=3");
      Check (Tab.N_Decision = 2, "N_Decision=2");
      Check (Tab.N_Artificial = 0, "no arts when b≥0");
      Check (Is_Optimal_LP (Tab) = False, "not optimal at start");
      Check (Select_Entering (Tab) = 1, "Bland enters col 1");
      R := Solve_Tableau (Tab, Cfg);
      Check (R.Success, "simplex smoke success");
      Check (Approx (R.Objective, 36.0), "obj=36");
      Check (Approx (R.Lambda (1), 2.0), "x=2");
      Check (Approx (R.Lambda (2), 6.0), "y=6");
   end;

   ---------------------------------------------------------------------
   Section ("5. Solve_RMP on trivial cutting-stock patterns");
   ---------------------------------------------------------------------
   declare
      Pool : Column_Pool;
      N_Cols : Column_Count;
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      R : RMP_Result;
   begin
      Init_Trivial_Patterns (Pool, N_Cols, Widths, 5, 2);
      R := Solve_RMP (Pool, N_Cols, Demand, 2);
      Check (R.Success, "RMP trivial success");
      --  2λ1 ≥ 3, λ2 ≥ 2 → λ1=1.5, λ2=2, obj=3.5
      Check (Approx (R.Objective, 3.5), "RMP obj 3.5");
      Check (Approx (R.Lambda (1), 1.5), "λ1=1.5");
      Check (Approx (R.Lambda (2), 2.0), "λ2=2");
      Check (Approx (R.Duals (1), 0.5), "π1=0.5");
      Check (Approx (R.Duals (2), 1.0), "π2=1");
      Check (R.N_Columns = 2, "RMP N_Columns");
      Check (R.N_Items = 2, "RMP N_Items");
   end;

   ---------------------------------------------------------------------
   Section ("6. Column gen reduces objective vs initial");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      Pool : Column_Pool;
      N_Cols : Column_Count;
      Init_R : RMP_Result;
      Full : Result;
   begin
      Init_Trivial_Patterns (Pool, N_Cols, Widths, 5, 2);
      Init_R := Solve_RMP (Pool, N_Cols, Demand, 2);
      Full := Solve_Cutting_Stock (Widths, Demand, 5);
      Check (Full.Success, "CG success W=5");
      Check (Full.Stat = Optimal, "CG Optimal");
      Check (Approx (Full.Objective, 2.5), "CG obj 2.5");
      Check (Full.Objective < Init_R.Objective - 1.0E-6,
             "CG improves vs trivial RMP");
      Check (Full.N_Columns >= 3, "added at least one column");
      Check (Full.N_Iters >= 1, "at least one outer iter");
      --  Duals at opt should not admit improving column
      declare
         P : constant Pricing_Result :=
           Price_Knapsack
             (Full.Duals (1 .. 2), Widths, 5, 2, 1.0);
      begin
         Check (not P.Improving, "terminal duals: no improving column");
         Check (P.Value <= 1.0 + 1.0E-6, "π·a ≤ 1 at termination");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Single-item / edge cutting stock");
   ---------------------------------------------------------------------
   declare
      W1 : constant Vector (1 .. 1) := [1.0];
      D1 : constant Vector (1 .. 1) := [1.0];
      R : Result;
   begin
      R := Solve_Cutting_Stock (W1, D1, 1);
      Check (R.Success, "1x1 success");
      Check (Approx (R.Objective, 1.0), "1x1 obj=1");
      Check (R.N_Columns = 1, "only trivial column");
   end;

   declare
      W1 : constant Vector (1 .. 1) := [2.0];
      D1 : constant Vector (1 .. 1) := [5.0];
      R : Result;
   begin
      --  W=10 → pattern a=5 per rod; need λ*5≥5 → λ=1
      R := Solve_Cutting_Stock (W1, D1, 10);
      Check (R.Success, "single width success");
      Check (Approx (R.Objective, 1.0), "obj=1 rod");
   end;

   declare
      W1 : constant Vector (1 .. 1) := [3.0];
      D1 : constant Vector (1 .. 1) := [4.0];
      R : Result;
   begin
      --  W=5 → a=1 per rod; λ≥4 → obj=4
      R := Solve_Cutting_Stock (W1, D1, 5);
      Check (R.Success, "wasteful single success");
      Check (Approx (R.Objective, 4.0), "obj=4");
   end;

   ---------------------------------------------------------------------
   Section ("8. Three-item small instance");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 3) := [3.0, 5.0, 7.0];
      Demand : constant Vector (1 .. 3) := [4.0, 2.0, 1.0];
      R : Result;
      Init_R : RMP_Result;
      Pool : Column_Pool;
      N_Cols : Column_Count;
   begin
      Init_Trivial_Patterns (Pool, N_Cols, Widths, 20, 3);
      Init_R := Solve_RMP (Pool, N_Cols, Demand, 3);
      R := Solve_Cutting_Stock (Widths, Demand, 20);
      Check (R.Success, "3-item success");
      Check (R.Stat = Optimal, "3-item Optimal");
      Check (R.Objective <= Init_R.Objective + 1.0E-6,
             "CG ≤ initial obj");
      Check (R.Objective > 0.0, "positive rods");
      Check (R.N_Items = 3, "N_Items=3");
      for I in 1 .. 3 loop
         Check (R.Duals (I) >= -1.0E-8, "dual nonnegative");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Termination / caps");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      Cfg : Config := Default_Cfg;
      R : Result;
   begin
      Cfg.Max_Iters := 1;
      Cfg.Max_Columns := 2;  -- only trivial fit
      R := Solve_Cutting_Stock (Widths, Demand, 5, Cfg);
      --  After first RMP, pricing wants a column but Cap=2 → Column_Limit
      Check (R.Stat = Column_Limit or else R.Stat = Optimal
             or else R.Stat = Iteration_Limit,
             "cap yields limit or early opt");
      Check (R.N_Columns <= 2, "respects Max_Columns=2");
   end;

   declare
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      Cfg : Config := Default_Cfg;
      R : Result;
   begin
      Cfg.Max_Iters := 100;
      R := Solve_Cutting_Stock (Widths, Demand, 5, Cfg);
      Check (R.Success and then R.Stat = Optimal, "ample iters → Optimal");
   end;

   ---------------------------------------------------------------------
   Section ("10. Zero demand / mixed demand");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 2) := [2.0, 4.0];
      Demand : constant Vector (1 .. 2) := [0.0, 3.0];
      R : Result;
   begin
      R := Solve_Cutting_Stock (Widths, Demand, 8);
      Check (R.Success, "zero demand item ok");
      --  pattern for item2: floor(8/4)=2; need 2λ≥3 → λ=1.5
      Check (Approx (R.Objective, 1.5), "obj from item2 only");
   end;

   ---------------------------------------------------------------------
   Section ("11. Pricing more shapes");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 3) := [2.0, 3.0, 4.0];
      Duals : Vector (1 .. 3);
      P : Pricing_Result;
   begin
      Duals := [0.1, 0.1, 0.1];
      P := Price_Knapsack (Duals, Widths, 10, 3);
      Check (not P.Improving, "tiny duals 3-item");

      Duals := [2.0, 0.0, 0.0];
      P := Price_Knapsack (Duals, Widths, 10, 3);
      Check (P.Improving, "large π1");
      Check (P.Counts (1) = 5, "five width-2 pieces");
      Check (Approx (P.Value, 10.0), "value 10");

      Duals := [0.0, 0.0, 0.9];
      P := Price_Knapsack (Duals, Widths, 9, 3);
      --  two of width 4? 8≤9 value 1.8; or ...
      Check (P.Improving, "π3=0.9 two copies");
      Check (P.Counts (3) >= 2, "at least two item3");

      Duals := [0.25, 0.25, 0.25];
      P := Price_Knapsack (Duals, Widths, 5, 3);
      Check (P.Value <= 1.0 + 1.0E-9 or else P.Improving,
             "consistent improving flag");
      Check (Pattern_Width (P.Counts, Widths, 3) <= 5,
             "priced pattern fits W");
   end;

   ---------------------------------------------------------------------
   Section ("12. Reduced_Cost batch");
   ---------------------------------------------------------------------
   declare
      Counts : Pattern_Counts := [others => 0];
      Duals : constant Vector (1 .. 3) := [0.2, 0.3, 0.5];
   begin
      Counts (1) := 1;
      Check (Approx (Reduced_Cost (Counts, Duals, 3), 0.8), "rc 0.8");
      Counts (2) := 2;
      Check (Approx (Reduced_Cost (Counts, Duals, 3), 0.2), "rc 0.2");
      Counts (3) := 1;
      Check (Approx (Reduced_Cost (Counts, Duals, 3), -0.3), "rc -0.3");
      Check (Approx (Reduced_Cost (Counts, Duals, 3, 2.0), 0.7),
             "costed column rc");
      Counts := [others => 0];
      Check (Approx (Reduced_Cost (Counts, Duals, 3), 1.0), "empty pattern");
   end;

   ---------------------------------------------------------------------
   Section ("13. RMP with added improving column");
   ---------------------------------------------------------------------
   declare
      Pool : Column_Pool;
      N_Cols : Column_Count;
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      Mix : Pattern_Counts := [others => 0];
      R0, R1 : RMP_Result;
   begin
      Init_Trivial_Patterns (Pool, N_Cols, Widths, 5, 2);
      R0 := Solve_RMP (Pool, N_Cols, Demand, 2);
      Mix (1) := 1;
      Mix (2) := 1;
      Add_Column (Pool, N_Cols, Mix);
      R1 := Solve_RMP (Pool, N_Cols, Demand, 2);
      Check (R1.Success, "RMP with mix success");
      Check (Approx (R1.Objective, 2.5), "obj 2.5 with mix");
      Check (R1.Objective < R0.Objective - 1.0E-6, "mix improves RMP");
      Check (Approx (R1.Duals (1), 0.5), "π1=0.5 after mix");
      Check (Approx (R1.Duals (2), 0.5), "π2=0.5 after mix");
   end;

   ---------------------------------------------------------------------
   Section ("14. Bland helpers / pivot path");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 1, 1 .. 1) := [[1.0]];
      B : constant Vector (1 .. 1) := [2.0];
      C : constant Vector (1 .. 1) := [1.0];
      Tab : Tableau := Build_Tableau (A, B, C);
      Leave : Natural;
   begin
      Check (Active_Obj_Row (Tab) = 0, "active row 0");
      Check (Select_Entering (Tab) = 1, "enter x");
      Leave := Select_Leaving (Tab, 1);
      Check (Leave = 1, "leave slack row");
      Pivot (Tab, 1, 1);
      Check (Tab.Basic (1) = 1, "x basic");
      Check (Is_Optimal_LP (Tab), "optimal after one pivot");
      Check (Approx (Tab.T (0, 0), 2.0), "z=2");
      declare
         X : constant Vector := Extract_Primal (Tab, 1);
      begin
         Check (Approx (X (1), 2.0), "primal x=2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Infeasible RMP (empty cover impossible)");
   ---------------------------------------------------------------------
   --  Demands with zero-width columns cannot happen via API; instead
   --  feed a pool whose patterns never cover item 2.
   declare
      Pool : Column_Pool;
      N_Cols : Column_Count := 0;
      Only : Pattern_Counts := [others => 0];
      Demand : constant Vector (1 .. 2) := [1.0, 1.0];
      R : RMP_Result;
   begin
      Only (1) := 1;
      Add_Column (Pool, N_Cols, Only);
      R := Solve_RMP (Pool, N_Cols, Demand, 2);
      Check (not R.Success, "uncovered demand infeasible");
      Check (R.Stat = Infeasible, "Stat Infeasible");
   end;

   ---------------------------------------------------------------------
   Section ("16. Larger W / more columns still Optimal");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 4) := [5.0, 7.0, 9.0, 11.0];
      Demand : constant Vector (1 .. 4) := [3.0, 3.0, 2.0, 1.0];
      R : Result;
   begin
      R := Solve_Cutting_Stock (Widths, Demand, 30);
      Check (R.Success, "4-item W=30 success");
      Check (R.Stat = Optimal, "4-item Optimal");
      Check (R.N_Columns >= 4, "at least trivial columns");
      Check (R.Objective >= 1.0, "at least one rod");
      declare
         P : constant Pricing_Result :=
           Price_Knapsack (R.Duals (1 .. 4), Widths, 30, 4);
      begin
         Check (not P.Improving, "4-item terminal duals optimal");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("17. Pattern_Exists / Clear / costed Add");
   ---------------------------------------------------------------------
   declare
      Pool : Column_Pool;
      N_Cols : Column_Count;
      C : Pattern_Counts := [others => 0];
   begin
      Clear_Pool (Pool, N_Cols);
      C (1) := 2;
      Check (not Pattern_Exists (Pool, 0, C, 1), "empty pool miss");
      Add_Column (Pool, N_Cols, C, 2.5);
      Check (Approx (Pool (1).Cost, 2.5), "custom cost stored");
      Check (Pattern_Exists (Pool, N_Cols, C, 1), "exists");
      C (1) := 3;
      Check (not Pattern_Exists (Pool, N_Cols, C, 1), "different miss");
      Clear_Pool (Pool, N_Cols);
      Check (N_Cols = 0, "cleared again");
   end;

   ---------------------------------------------------------------------
   Section ("18. Demand covering identity");
   ---------------------------------------------------------------------
   --  After CG, Σ_j a_{ij} λ_j ≥ demand_i for each i (LP relaxation).
   declare
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      R : constant Result := Solve_Cutting_Stock (Widths, Demand, 5);
      Cover : Real;
   begin
      Check (R.Success, "cover check success");
      for I in 1 .. 2 loop
         Cover := 0.0;
         for J in 1 .. R.N_Columns loop
            Cover := Cover
              + Real (R.Pool (J).Counts (I)) * R.Lambda (J);
         end loop;
         Check (Cover + 1.0E-6 >= Demand (I),
                "cover item" & Integer'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("19. Dual feasibility A^T π ≤ 1 at opt");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      R : constant Result := Solve_Cutting_Stock (Widths, Demand, 5);
      Dot : Real;
   begin
      Check (R.Success, "dual feas success");
      for J in 1 .. R.N_Columns loop
         Dot := 0.0;
         for I in 1 .. 2 loop
            Dot := Dot
              + R.Duals (I) * Real (R.Pool (J).Counts (I));
         end loop;
         Check (Dot <= 1.0 + 1.0E-5,
                "A^Tπ ≤ 1 col" & Integer'Image (J));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("20. Strong duality rough check");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 2) := [2.0, 3.0];
      Demand : constant Vector (1 .. 2) := [3.0, 2.0];
      R : constant Result := Solve_Cutting_Stock (Widths, Demand, 5);
      Dual_Obj : Real := 0.0;
   begin
      for I in 1 .. 2 loop
         Dual_Obj := Dual_Obj + R.Duals (I) * Demand (I);
      end loop;
      Check (Approx (Dual_Obj, R.Objective, 1.0E-5),
             "primal obj ≈ dual obj");
   end;

   ---------------------------------------------------------------------
   Section ("21. More Near / knapsack edge");
   ---------------------------------------------------------------------
   Check (Near (2.5, 2.5), "Near 2.5");
   Check (not Near (2.5, 2.6, 0.01), "Near 0.01 reject");
   Check (Near (2.5, 2.509, 0.01), "Near 0.01 accept");

   declare
      Widths : constant Vector (1 .. 1) := [50.0];
      Duals : constant Vector (1 .. 1) := [2.0];
      P : Pricing_Result;
   begin
      P := Price_Knapsack (Duals, Widths, 50, 1);
      Check (P.Counts (1) = 1, "W=50 width=50 one piece");
      Check (Approx (P.Value, 2.0), "value 2");
      Check (P.Improving, "improving");
   end;

   declare
      Widths : constant Vector (1 .. 2) := [10.0, 20.0];
      Duals : constant Vector (1 .. 2) := [-1.0, 0.5];
      P : Pricing_Result;
   begin
      --  Negative dual ignored for packing (π>0 branch)
      P := Price_Knapsack (Duals, Widths, 40, 2);
      Check (P.Counts (1) = 0, "neg dual not packed");
      Check (P.Counts (2) = 2, "two of item2");
   end;

   ---------------------------------------------------------------------
   Section ("22. Iteration counts / pool validity");
   ---------------------------------------------------------------------
   declare
      Widths : constant Vector (1 .. 2) := [4.0, 5.0];
      Demand : constant Vector (1 .. 2) := [2.0, 2.0];
      R : Result;
   begin
      R := Solve_Cutting_Stock (Widths, Demand, 9);
      Check (R.Success, "4,5 on 9 success");
      for J in 1 .. R.N_Columns loop
         Check (R.Pool (J).Valid, "pool valid");
         Check (Pattern_Width (R.Pool (J).Counts, Widths, 2) <= 9,
                "pattern fits");
      end loop;
      Check (R.N_Pivots >= 1, "some pivots performed");
   end;

   --  Summary
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("====================================");
   Ada.Text_IO.Put_Line
     ("Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("RESULT: FAILED");
   else
      Ada.Text_IO.Put_Line ("RESULT: ALL PASSED");
   end if;
end Tests;
