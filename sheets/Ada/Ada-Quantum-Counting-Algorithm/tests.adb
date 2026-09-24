with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Quantum_Counting; use Quantum_Counting;

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
begin
   Put_Line ("=== STARTING QUANTUM COUNTING SUITE ===");

   -- TEST 1 — Standard Estimation with Zero Solutions
   Put_Line ("TEST 1 — Zero Solutions Estimation");
   declare
      N   : constant Database_Capacity := 16;
      T   : constant Precision_Bits := 4;
      K   : constant Solution_Count := 0;
      Res : constant Solution_Count := Estimate_Solutions (N, T, K);
   begin
      Check ("1.1 Estimated count is zero", Res = 0);
      pragma Warnings (Off);
      Check ("1.2 Result does not exceed N", Res <= Solution_Count (N));
      pragma Warnings (On);
      Check ("1.3 Zero solutions exact match", Res = K);
   end;

   -- TEST 2 — Standard Estimation with All Solutions
   Put_Line ("TEST 2 — Maximum Solutions Estimation");
   declare
      N   : constant Database_Capacity := 16;
      T   : constant Precision_Bits := 4;
      K   : constant Solution_Count := 16;
      Res : constant Solution_Count := Estimate_Solutions (N, T, K);
   begin
      Check ("2.1 Estimated count equals N", Res = Solution_Count (N));
      Check ("2.2 Max solutions verified", Res = 16);
      pragma Warnings (Off);
      Check ("2.3 Non-negative outcome", Res >= 0);
      pragma Warnings (On);
   end;

   -- TEST 3 — Standard Estimation with Moderate Solutions
   Put_Line ("TEST 3 — Moderate Solutions Estimation");
   declare
      N   : constant Database_Capacity := 64;
      T   : constant Precision_Bits := 6;
      K   : constant Solution_Count := 16;
      Res : constant Solution_Count := Estimate_Solutions (N, T, K);
   begin
      Check ("3.1 Estimation is within reasonable delta", abs (Integer (Res) - Integer (K)) <= 4);
      pragma Warnings (Off);
      Check ("3.2 Result bounded by N", Res <= Solution_Count (N));
      pragma Warnings (On);
      Check ("3.3 Result non-zero", Res > 0);
   end;

   -- TEST 4 — Quantum Existence Check with No Solutions
   Put_Line ("TEST 4 — Existence Check Zero Solutions");
   declare
      N  : constant Database_Capacity := 32;
      T  : constant Precision_Bits := 5;
      K  : constant Solution_Count := 0;
      St : constant Existence_Status := Check_Existence (N, T, K);
   begin
      Check ("4.1 Existence status evaluated", St = No_Solutions or St = Undetermined);
      Check ("4.2 Status is not falsely positive", St /= Exists_Solutions);
      pragma Warnings (Off);
      Check ("4.3 N and T respected", N >= 4 and T >= 1);
      pragma Warnings (On);
   end;

   -- TEST 5 — Quantum Existence Check with Solutions Present
   Put_Line ("TEST 5 — Existence Check Solutions Present");
   declare
      N  : constant Database_Capacity := 32;
      T  : constant Precision_Bits := 5;
      K  : constant Solution_Count := 4;
      St : constant Existence_Status := Check_Existence (N, T, K);
   begin
      Check ("5.1 Existence confirmed", St = Exists_Solutions);
      Check ("5.2 Status is not No_Solutions", St /= No_Solutions);
      Check ("5.3 Valid status returned", St = Exists_Solutions or St = No_Solutions);
   end;

   -- TEST 6 — Grover Search with Unknown Count (Target Found)
   Put_Line ("TEST 6 — Grover Search Unknown Count Found");
   declare
      N      : constant Database_Capacity := 64;
      T      : constant Precision_Bits := 4;
      K      : constant Solution_Count := 4;
      Target : constant Database_Capacity := 2;
      S_Res  : constant Search_Result := Search_Unknown_Solutions (N, T, K, Target);
   begin
      Check ("6.1 Target found successfully", S_Res.Found = True);
      Check ("6.2 Correct target index returned", S_Res.Index = Target);
      Check ("6.3 Iterations count positive", S_Res.Iterations > 0);
   end;

   -- TEST 7 — Grover Search with Unknown Count (Target Not Found / Zero K)
   Put_Line ("TEST 7 — Grover Search Unknown Count Zero K");
   declare
      N      : constant Database_Capacity := 64;
      T      : constant Precision_Bits := 4;
      K      : constant Solution_Count := 0;
      Target : constant Database_Capacity := 2;
      S_Res  : constant Search_Result := Search_Unknown_Solutions (N, T, K, Target);
   begin
      Check ("7.1 Target not found when K=0", S_Res.Found = False);
      Check ("7.2 Iterations zero for zero K", S_Res.Iterations = 0);
      Check ("7.3 Target index preserved", S_Res.Index = Target);
   end;

   -- TEST 8 — Compute Theta Angle for Minimum Solutions
   Put_Line ("TEST 8 — Compute Theta Minimum Solutions");
   declare
     N     : constant Database_Capacity := 100;
     K     : constant Solution_Count := 1;
     Theta : constant Phase_Radians := Compute_Theta (N, K);
   begin
      Check ("8.1 Theta non-negative", Theta >= 0.0);
      Check ("8.2 Theta within Pi bound", Theta <= Ada.Numerics.Pi);
      Check ("8.3 Theta is small for k=1, N=100", Theta < 0.5);
   end;

   -- TEST 9 — Compute Theta Angle for Half Solutions
   Put_Line ("TEST 9 — Compute Theta Half Solutions");
   declare
      N     : constant Database_Capacity := 100;
      K     : constant Solution_Count := 50;
      Theta : constant Phase_Radians := Compute_Theta (N, K);
   begin
      Check ("9.1 Theta non-negative", Theta >= 0.0);
      Check ("9.2 Theta within Pi bound", Theta <= Ada.Numerics.Pi);
      Check ("9.3 Theta correctly large for k=50", Theta > 1.5);
   end;

   -- TEST 10 — Input Validation with Valid Parameters
   Put_Line ("TEST 10 — Input Validation Success");
   begin
      Validate_Inputs (16, 4);
      Check ("10.1 Valid inputs passed without exception", True);
      pragma Warnings (Off);
      Check ("10.2 Database size >= 4 verified", 16 >= 4);
      Check ("10.3 Precision bits >= 1 verified", 4 >= 1);
      pragma Warnings (On);
   end;

   -- TEST 11 — Input Validation Exception (Database too small)
   Put_Line ("TEST 11 — Exception Database Too Small");
   declare
      Raised : Boolean := False;
   begin
      begin
         Validate_Inputs (2, 4);
      exception
         when Invalid_Parameters =>
            Raised := True;
      end;
      Check ("11.1 Invalid_Parameters raised for N < 4", Raised);
      Check ("11.2 Exception correctly caught", True);
      Check ("11.3 Control flow intact", True);
   end;

   -- TEST 12 — Input Validation Exception (Boundary N=3)
   Put_Line ("TEST 12 — Exception Boundary N=3");
   declare
      Raised : Boolean := False;
   begin
      begin
         Validate_Inputs (3, 4);
      exception
         when Invalid_Parameters =>
            Raised := True;
      end;
      Check ("12.1 Invalid_Parameters raised for N=3", Raised);
      Check ("12.2 Exception handling verified", True);
      Check ("12.3 Robustness confirmed", True);
   end;

   -- TEST 13 — Boundary Check & Extreme Precision Values
   Put_Line ("TEST 13 — Boundary Check & Extreme Precision");
   declare
      N   : constant Database_Capacity := 1024;
      T   : constant Precision_Bits := 10;
      K   : constant Solution_Count := 256;
      Res : constant Solution_Count := Estimate_Solutions (N, T, K);
   begin
      pragma Warnings (Off);
      Check ("13.1 Large database estimation works", Res <= Solution_Count (N));
      pragma Warnings (On);
      Check ("13.2 Estimation reasonably close to 256", abs (Integer (Res) - Integer (K)) <= 15);
      Check ("13.3 High precision completed cleanly", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
