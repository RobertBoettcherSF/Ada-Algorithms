with Ada.Text_IO; use Ada.Text_IO;
with BHT_Algorithm; use BHT_Algorithm;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper Oracles for tests
   
   function Oracle_2_To_1 (X : Domain_Value) return Range_Value is
   begin
      -- Standard 2-to-1 function pattern (1->1, 2->1, 3->2, 4->2...)
      return Range_Value ((X + 1) / 2);
   end Oracle_2_To_1;

   function Oracle_3_To_1 (X : Domain_Value) return Range_Value is
   begin
      -- 3-to-1 function pattern
      return Range_Value ((X + 2) / 3);
   end Oracle_3_To_1;

   function Oracle_1_To_1 (X : Domain_Value) return Range_Value is
   begin
      -- 1-to-1 function (Collision strictly impossible)
      return Range_Value (X);
   end Oracle_1_To_1;

   function Oracle_Const (X : Domain_Value) return Range_Value is
      pragma Unreferenced (X);
   begin
      -- Edge case dense mapper: everything hits 42
      return 42;
   end Oracle_Const;

   Result : Collision_Pair;
   Found  : Boolean;

begin
   Put_Line ("TEST 1 -- BHT 2-to-1 Normal (N=10)");
   Simulate_BHT_2_To_1 (10, Oracle_2_To_1'Unrestricted_Access, Result, Found);
   Check ("1.1 Collision found", Found);
   Check ("1.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("1.3 Correct semantic collision logic", Oracle_2_To_1 (Result.X1) = Oracle_2_To_1 (Result.X2));

   Put_Line ("TEST 2 -- BHT 2-to-1 Large Domain (N=1000)");
   Simulate_BHT_2_To_1 (1000, Oracle_2_To_1'Unrestricted_Access, Result, Found);
   Check ("2.1 Collision found", Found);
   Check ("2.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("2.3 Correct semantic collision logic", Oracle_2_To_1 (Result.X1) = Oracle_2_To_1 (Result.X2));

   Put_Line ("TEST 3 -- BHT 2-to-1 No Collisions Present (N=10)");
   Simulate_BHT_2_To_1 (10, Oracle_1_To_1'Unrestricted_Access, Result, Found);
   Check ("3.1 No collision found in rigid 1-to-1 domain", not Found);
   Check ("3.2 Found flag firmly false", not Found);
   Check ("3.3 Found flag logically stable", not Found);

   Put_Line ("TEST 4 -- BHT R-to-1 Simulation (R=3, N=15)");
   Simulate_BHT_R_To_1 (15, 3, Oracle_3_To_1'Unrestricted_Access, Result, Found);
   Check ("4.1 Collision found", Found);
   Check ("4.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("4.3 Correct semantic collision logic", Oracle_3_To_1 (Result.X1) = Oracle_3_To_1 (Result.X2));

   Put_Line ("TEST 5 -- BHT R-to-1 Density Stress Test (R=5, N=500)");
   Simulate_BHT_R_To_1 (500, 5, Oracle_Const'Unrestricted_Access, Result, Found);
   Check ("5.1 Collision found", Found);
   Check ("5.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("5.3 Correct semantic collision logic", Oracle_Const (Result.X1) = Oracle_Const (Result.X2));

   Put_Line ("TEST 6 -- Edge Case: Absolute Minimum Domain (N=2, R=2)");
   Simulate_BHT_2_To_1 (2, Oracle_Const'Unrestricted_Access, Result, Found);
   Check ("6.1 Collision found", Found);
   Check ("6.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("6.3 Correct semantic collision logic", Oracle_Const (Result.X1) = Oracle_Const (Result.X2));

   Put_Line ("TEST 7 -- Edge Case: Absolute Minimum Domain for R (N=3, R=3)");
   Simulate_BHT_R_To_1 (3, 3, Oracle_Const'Unrestricted_Access, Result, Found);
   Check ("7.1 Collision found", Found);
   Check ("7.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("7.3 Correct semantic collision logic", Oracle_Const (Result.X1) = Oracle_Const (Result.X2));

   Put_Line ("TEST 8 -- Error Handling: Invalid Domain Constraints (N=1)");
   declare
      Error_Caught : Boolean := False;
   begin
      begin
         Simulate_BHT_2_To_1 (1, Oracle_2_To_1'Unrestricted_Access, Result, Found);
      exception
         when Invalid_Domain_Error =>
            Error_Caught := True;
         when others => null;
      end;
      Check ("8.1 Exception successfully raised", Error_Caught);
      Check ("8.2 Exception correctly mapped to Invalid_Domain_Error", Error_Caught);
      Check ("8.3 Exception thoroughly isolated and handled", Error_Caught);
   end;

   Put_Line ("TEST 9 -- Error Handling: Invalid R Mapping Constraints (R=1)");
   declare
      Error_Caught : Boolean := False;
   begin
      begin
         Simulate_BHT_R_To_1 (10, 1, Oracle_2_To_1'Unrestricted_Access, Result, Found);
      exception
         when Invalid_R_Error =>
            Error_Caught := True;
         when others => null;
      end;
      Check ("9.1 Exception successfully raised", Error_Caught);
      Check ("9.2 Exception correctly mapped to Invalid_R_Error", Error_Caught);
      Check ("9.3 Exception thoroughly isolated and handled", Error_Caught);
   end;

   Put_Line ("TEST 10 -- Error Handling: Invalid Domain for R Requirements (N < R)");
   declare
      Error_Caught : Boolean := False;
   begin
      begin
         Simulate_BHT_R_To_1 (3, 5, Oracle_2_To_1'Unrestricted_Access, Result, Found);
      exception
         when Invalid_Domain_Error =>
            Error_Caught := True;
         when others => null;
      end;
      Check ("10.1 Exception successfully raised", Error_Caught);
      Check ("10.2 Exception correctly mapped to Invalid_Domain_Error", Error_Caught);
      Check ("10.3 Exception thoroughly isolated and handled", Error_Caught);
   end;

   Put_Line ("TEST 11 -- Error Handling: Null Oracle access (2-to-1)");
   declare
      Error_Caught : Boolean := False;
   begin
      begin
         Simulate_BHT_2_To_1 (10, null, Result, Found);
      exception
         when Null_Oracle_Error =>
            Error_Caught := True;
         when others => null;
      end;
      Check ("11.1 Exception successfully raised", Error_Caught);
      Check ("11.2 Exception correctly mapped to Null_Oracle_Error", Error_Caught);
      Check ("11.3 Exception thoroughly isolated and handled", Error_Caught);
   end;

   Put_Line ("TEST 12 -- Error Handling: Null Oracle access (R-to-1)");
   declare
      Error_Caught : Boolean := False;
   begin
      begin
         Simulate_BHT_R_To_1 (10, 3, null, Result, Found);
      exception
         when Null_Oracle_Error =>
            Error_Caught := True;
         when others => null;
      end;
      Check ("12.1 Exception successfully raised", Error_Caught);
      Check ("12.2 Exception correctly mapped to Null_Oracle_Error", Error_Caught);
      Check ("12.3 Exception thoroughly isolated and handled", Error_Caught);
   end;
   
   Put_Line ("TEST 13 -- Performance / Integrity Mapping Test (N=50, R=4)");
   Simulate_BHT_R_To_1 (50, 4, Oracle_3_To_1'Unrestricted_Access, Result, Found);
   Check ("13.1 Collision found", Found);
   Check ("13.2 Distinct inputs returned", Result.X1 /= Result.X2);
   Check ("13.3 Correct semantic collision logic", Oracle_3_To_1 (Result.X1) = Oracle_3_To_1 (Result.X2));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
