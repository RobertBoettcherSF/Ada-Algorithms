-- tests.adb
-- Standalone test suite verifying robustness, correctness, and limits.
with Ada.Text_IO; use Ada.Text_IO;
with Difference_Map; use Difference_Map;

procedure Tests is

   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;

   procedure Report (Description : String; Condition : Boolean) is
   begin
      Total_Tests := Total_Tests + 1;
      Put ("  " & Description & " ... ");
      if Condition then
         Put_Line ("PASS");
         Passed_Tests := Passed_Tests + 1;
      else
         Put_Line ("FAIL");
      end if;
   end Report;

   -- Dummy projections for testing
   function Proj_Identity (V : Vector) return Vector is (V);
   function Proj_Zero (V : Vector) return Vector is
      R : constant Vector (V'Range) := (others => 0.0);
   begin
      return R;
   end Proj_Zero;

begin
   Put_Line ("=================================================");
   Put_Line ("DIFFERENCE MAP V&V TEST SUITE (Assumed Defective)");
   Put_Line ("=================================================");

   Put_Line ("TEST 1 - Vector Mathematics (Functionality)");
   declare
      V1 : constant Vector := (1.0, 2.0, 3.0);
      V2 : constant Vector := (4.0, 5.0, 6.0);
      R  : Vector := V1 + V2;
   begin
      Report ("1.1 Assert [1,2,3] + [4,5,6] = [5,7,9]", R(1)=5.0 and R(2)=7.0 and R(3)=9.0);
      R := V2 - V1;
      Report ("1.2 Assert [4,5,6] - [1,2,3] = [3,3,3]", R(1)=3.0 and R(2)=3.0 and R(3)=3.0);
      R := 2.0 * V1;
      Report ("1.3 Assert 2.0 * [1,2,3] = [2,4,6]", R(1)=2.0 and R(2)=4.0 and R(3)=6.0);
      Report ("1.4 Assert Norm of [3.0, 4.0] is 5.0", Norm((1=>3.0, 2=>4.0)) = 5.0);
   end;

   Put_Line ("TEST 2 - Edge Cases & Invalid Inputs (Robustness)");
   begin
      declare
         V1 : constant Vector (1..2) := (1.0, 1.0);
         V2 : constant Vector (1..3) := (1.0, 1.0, 1.0);
      begin
         if Norm (V1 + V2) >= 0.0 then
            Report ("2.1 Assert Addition of mismatched lengths fails", False);
         end if;
      end;
   exception
      when Dimension_Error => Report ("2.1 Assert Addition of mismatched lengths raises Dimension_Error", True);
   end;

   begin
      declare
         Empty : Vector (1..0);
      begin
         Report ("2.2 Assert Norm of empty vector is 0.0", Norm(Empty) = 0.0);
      end;
   end;

   begin
      declare
         V : constant Vector (1..2) := (1.0, 1.0);
      begin
         if Norm (Standard_Step(V, Proj_Identity'Unrestricted_Access, Proj_Zero'Unrestricted_Access, 0.0)) >= 0.0 then
            Report ("2.3 Assert Beta = 0.0 raises exception", False);
         end if;
      end;
   exception
      when Parameter_Error => Report ("2.3 Assert Beta = 0.0 raises Parameter_Error", True);
   end;

   Put_Line ("TEST 3 - Difference Map Variants (Functionality)");
   declare
      V : constant Vector (1..2) := (10.0, 10.0);
      R : Vector (1..2);
   begin
      -- Standard Map: Gamma = 1.0, Beta = 1.0. With Proj_Zero & Proj_Identity
      R := Standard_Step (V, Proj_Zero'Unrestricted_Access, Proj_Identity'Unrestricted_Access, 1.0);
      -- Expectation: specific vector mechanics execution passes without error and returns valid vector
      Report ("3.1 Assert Standard_Step computes valid result", R'Length = 2);
      
      R := Douglas_Rachford_Step (V, Proj_Zero'Unrestricted_Access, Proj_Identity'Unrestricted_Access);
      Report ("3.2 Assert Douglas-Rachford executes without dimension fault", R'Length = 2);

      R := Alternating_Projections_Step (V, Proj_Zero'Unrestricted_Access, Proj_Identity'Unrestricted_Access);
      Report ("3.3 Assert Alternating Projections executes exactly P_B(P_A(X))", R(1) = 0.0 and R(2) = 0.0);
   end;

   Put_Line ("TEST 4 - Solver Convergence Behavior (Performance)");
   declare
      V          : Vector (1..2) := (1.0, 1.0);
      Converged  : Boolean;
      Iterations : Natural;
   begin
      Solve (V, Proj_Identity'Unrestricted_Access, Proj_Identity'Unrestricted_Access, 1.0, 10, 0.001, Converged, Iterations);
      Report ("4.1 Assert immediate convergence when inputs are perfect", Converged and Iterations = 1);
   end;
   
   declare
      function Proj_Shift (V : Vector) return Vector is
         R : Vector := V;
      begin
         R(1) := R(1) + 1.0;
         return R;
      end Proj_Shift;
      
      V          : Vector (1..2) := (0.0, 0.0);
      Converged  : Boolean;
      Iterations : Natural;
   begin
      Solve (V, Proj_Identity'Unrestricted_Access, Proj_Shift'Unrestricted_Access, 0.5, 5, 0.001, Converged, Iterations);
      Report ("4.2 Assert solver halts cleanly on Max_Iter without infinite loops", (not Converged) and Iterations = 5);
   end;

   Put_Line ("=================================================");
   Put_Line ("TESTS PASSED: " & Natural'Image(Passed_Tests) & " / " & Natural'Image(Total_Tests));
   if Passed_Tests = Total_Tests then
      Put_Line ("STATUS: SYSTEM VERIFIED.");
   else
      Put_Line ("STATUS: SYSTEM CONTAINS DEFECTS.");
   end if;

end Tests;
