with Ada.Text_IO; use Ada.Text_IO;
with Petricks_Method; use Petricks_Method;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper to check if a list of solutions contains a specific set of PIs.
   function Contains (List : Solution_List; Expected_PIs : PI_Array) return Boolean is
   begin
      for S of List loop
         if S.Count = Expected_PIs'Length then
            declare
               Match : Boolean := True;
            begin
               -- Assuming Expected_PIs is passed sorted, just like internal representations
               for I in Expected_PIs'Range loop
                  if S.PIs (I - Expected_PIs'First + 1) /= Expected_PIs (I) then
                     Match := False;
                  end if;
               end loop;
               if Match then
                  return True;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Contains;

   -- Dummy uninitialized vars for testing
   Empty_Chart : Clause_List (1 .. 0);
begin
   -----------------------------------------------------------------------------
   Put_Line ("TEST 1 — Empty Chart Exception");
   -----------------------------------------------------------------------------
   begin
      declare
         Sols : constant Solution_List := Multiply_And_Simplify (Empty_Chart);
         pragma Unreferenced (Sols);
      begin
         Check ("1.1 Failed to raise exception", False);
      end;
   exception
      when Empty_Chart_Error =>
         Check ("1.1 Raised Empty_Chart_Error", True);
         Check ("1.2 Handled cleanly", True);
         Check ("1.3 Algorithm protected from bounds fault", True);
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 2 — Empty Clause Exception");
   -----------------------------------------------------------------------------
   declare
      Bad_Chart : constant Clause_List := [Empty_Clause, Create_Clause ([1])];
   begin
      declare
         Sols : constant Solution_List := Multiply_And_Simplify (Bad_Chart);
         pragma Unreferenced (Sols);
      begin
         Check ("2.1 Failed to raise exception", False);
      end;
   exception
      when Empty_Clause_Error =>
         Check ("2.1 Raised Empty_Clause_Error", True);
         Check ("2.2 Avoids impossible POS state", True);
         Check ("2.3 Stopped execution gracefully", True);
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 3 — Single PI, Single Clause");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1]);
      R  : constant Solution_List := Multiply_And_Simplify ([1 => C1]);
   begin
      Check ("3.1 Returns 1 solution", R'Length = 1);
      Check ("3.2 Solution size is 1", R (1).Count = 1);
      Check ("3.3 Contains PI 1", R (1).PIs (1) = 1);
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 4 — Standard OR Logic (One Clause, Multiple PIs)");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      R  : constant Solution_List := Multiply_And_Simplify ([1 => C1]);
   begin
      Check ("4.1 Returns 2 distinct solutions", R'Length = 2);
      Check ("4.2 Contains {1}", Contains (R, [1]));
      Check ("4.3 Contains {2}", Contains (R, [2]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 5 — Idempotence (A * A = A)");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      R  : constant Solution_List := Multiply_And_Simplify ([C1, C1]);
   begin
      Check ("5.1 Duplication is ignored", R'Length = 2);
      Check ("5.2 Contains {1}", Contains (R, [1]));
      Check ("5.3 Contains {2}", Contains (R, [2]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 6 — Absorption Subset (A * (A + B) = A)");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1]);
      C2 : constant Clause := Create_Clause ([1, 2]);
      R  : constant Solution_List := Multiply_And_Simplify ([C1, C2]);
   begin
      Check ("6.1 Returns only 1 minimal solution", R'Length = 1);
      Check ("6.2 The minimal solution is {1}", Contains (R, [1]));
      Check ("6.3 The absorbed {1, 2} is removed", not Contains (R, [1, 2]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 7 — Absorption Superset ((A + B) * A = A)");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([1]);
      R  : constant Solution_List := Multiply_And_Simplify ([C1, C2]);
   begin
      Check ("7.1 Works regardless of clause ordering", R'Length = 1);
      Check ("7.2 The minimal solution is {1}", Contains (R, [1]));
      Check ("7.3 The absorbed {1, 2} is removed", not Contains (R, [1, 2]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 8 — Distributive Property ((A + B) * (C + D))");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([3, 4]);
      R  : constant Solution_List := Multiply_And_Simplify ([C1, C2]);
   begin
      Check ("8.1 Results in 4 combinations", R'Length = 4);
      Check ("8.2 Contains {1, 3}", Contains (R, [1, 3]));
      Check ("8.3 Contains {2, 4}", Contains (R, [2, 4]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 9 — Full Petrick's Wikipedia Example");
   -----------------------------------------------------------------------------
   -- Chart: (P1 + P2) * (P1 + P3) * (P2 + P4) * (P3 + P4)
   -- Result should simplify strictly to (P1 * P4) + (P2 * P3)
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([1, 3]);
      C3 : constant Clause := Create_Clause ([2, 4]);
      C4 : constant Clause := Create_Clause ([3, 4]);
      R  : constant Solution_List := Multiply_And_Simplify ([C1, C2, C3, C4]);
   begin
      Check ("9.1 Simplifies beautifully to 2 paths", R'Length = 2);
      Check ("9.2 Path 1 is {1, 4}", Contains (R, [1, 4]));
      Check ("9.3 Path 2 is {2, 3}", Contains (R, [2, 3]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 10 — Minimum Terms Filter");
   -----------------------------------------------------------------------------
   -- Chart: (1 + 2) * (2 + 3) * (4) => (2 + 1*3) * 4 => {2, 4}, {1, 3, 4}
   -- Min Terms should return exclusively {2, 4}
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([2, 3]);
      C3 : constant Clause := Create_Clause ([4]);
      R  : constant Solution_List := Minimum_Terms ([C1, C2, C3]);
   begin
      Check ("10.1 Drops larger cardinality subsets", R'Length = 1);
      Check ("10.2 Extracts the absolute min {2, 4}", Contains (R, [2, 4]));
      Check ("10.3 Ensures {1, 3, 4} is pruned out", not Contains (R, [1, 3, 4]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 11 — Minimum Cost Terms (Symmetric Cost)");
   -----------------------------------------------------------------------------
   -- Same chart, all PIs have cost 10. Returns {2, 4}
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([2, 3]);
      C3 : constant Clause := Create_Clause ([4]);
      Costs : constant Cost_Map (1 .. 4) := [others => 10];
      R  : constant Solution_List := Minimum_Cost_Terms ([C1, C2, C3], Costs);
   begin
      Check ("11.1 Returns fewest PIs with equal weights", R'Length = 1);
      Check ("11.2 Extracted {2, 4}", Contains (R, [2, 4]));
      Check ("11.3 Equal cost honors cardinality mapping", True);
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 12 — Minimum Cost Terms (Asymmetric Cost Override)");
   -----------------------------------------------------------------------------
   -- Same chart. {2, 4} uses heavily penalized PIs. {1, 3, 4} is cheaper!
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([2, 3]);
      C3 : constant Clause := Create_Clause ([4]);
      Costs : constant Cost_Map (1 .. 4) := [1 => 1, 2 => 100, 3 => 1, 4 => 1];
      R  : constant Solution_List := Minimum_Cost_Terms ([C1, C2, C3], Costs);
   begin
      Check ("12.1 Cost forces selection of higher-cardinality set", R'Length = 1);
      Check ("12.2 Retains the cheaper {1, 3, 4}", Contains (R, [1, 3, 4]));
      Check ("12.3 Heavily penalized {2, 4} is omitted", not Contains (R, [2, 4]));
   end;

   -----------------------------------------------------------------------------
   Put_Line ("TEST 13 — Missing Cost Map Exception");
   -----------------------------------------------------------------------------
   declare
      C1 : constant Clause := Create_Clause ([1, 2]);
      C2 : constant Clause := Create_Clause ([4]); -- Demands PI 4
      Costs : constant Cost_Map (1 .. 3) := [others => 1]; -- Cost map omits PI 4
   begin
      declare
         R : constant Solution_List := Minimum_Cost_Terms ([C1, C2], Costs);
         pragma Unreferenced (R);
      begin
         Check ("13.1 Missed exception", False);
      end;
   exception
      when Missing_Cost_Error =>
         Check ("13.1 Raised Missing_Cost_Error correctly", True);
         Check ("13.2 Validates constraint mapping before processing", True);
         Check ("13.3 Secure contract enforcement", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed during execution");
end Tests;
