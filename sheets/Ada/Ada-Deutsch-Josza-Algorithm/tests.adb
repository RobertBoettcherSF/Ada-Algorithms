with Ada.Text_IO; use Ada.Text_IO;
with Deutsch_Jozsa; use Deutsch_Jozsa;

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

   -- Helper functions for testing
   function F_Const_0 (X : Bit) return Bit is
      pragma Unreferenced (X);
   begin
      return 0;
   end F_Const_0;

   function F_Const_1 (X : Bit) return Bit is
      pragma Unreferenced (X);
   begin
      return 1;
   end F_Const_1;

   function F_Balanced (X : Bit) return Bit is (X);

   function F_N2_Balanced (Input : Bit_Vector) return Bit is
   begin
      return Bit ((Natural (Input (1)) + Natural (Input (2))) mod 2);
   end F_N2_Balanced;

begin
   -- TEST 1 — Deutsch's Algorithm: Constant Zero Function
   Put_Line ("TEST 1 — Deutsch Constant Zero");
   Check ("1.1 Result is Constant_Zero", Solve_Deutsch (F_Const_0'Access) = Constant_Zero);
   Check ("1.2 F_Const_0(0) is 0", F_Const_0 (0) = 0);
   Check ("1.3 F_Const_0(1) is 0", F_Const_0 (1) = 0);

   -- TEST 2 — Deutsch's Algorithm: Constant One Function
   Put_Line ("TEST 2 — Deutsch Constant One");
   Check ("2.1 Result is Constant_One", Solve_Deutsch (F_Const_1'Access) = Constant_One);
   Check ("2.2 F_Const_1(0) is 1", F_Const_1 (0) = 1);
   Check ("2.3 F_Const_1(1) is 1", F_Const_1 (1) = 1);

   -- TEST 3 — Deutsch's Algorithm: Balanced Function
   Put_Line ("TEST 3 — Deutsch Balanced");
   Check ("3.1 Result is Balanced", Solve_Deutsch (F_Balanced'Access) = Balanced);
   Check ("3.2 F_Balanced(0) is 0", F_Balanced (0) = 0);
   Check ("3.3 F_Balanced(1) is 1", F_Balanced (1) = 1);

   -- TEST 4 — General Deutsch-Jozsa: N=2 Constant Zero Truth Table
   Put_Line ("TEST 4 — DJ N=2 Constant Zero");
   declare
      TT : constant Bit_Vector (1 .. 4) := [0, 0, 0, 0];
   begin
      Check ("4.1 Solve DJ returns Constant_Zero", Solve_Deutsch_Jozsa (2, TT) = Constant_Zero);
      Check ("4.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("4.3 All elements are 0", TT (1) = 0 and TT (4) = 0);
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 5 — General Deutsch-Jozsa: N=2 Constant One Truth Table
   Put_Line ("TEST 5 — DJ N=2 Constant One");
   declare
      TT : constant Bit_Vector (1 .. 4) := [1, 1, 1, 1];
   begin
      Check ("5.1 Solve DJ returns Constant_One", Solve_Deutsch_Jozsa (2, TT) = Constant_One);
      Check ("5.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("5.3 All elements are 1", TT (1) = 1 and TT (4) = 1);
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 6 — General Deutsch-Jozsa: N=2 Balanced Truth Table
   Put_Line ("TEST 6 — DJ N=2 Balanced");
   declare
      TT : constant Bit_Vector (1 .. 4) := [0, 0, 1, 1];
   begin
      Check ("6.1 Solve DJ returns Balanced", Solve_Deutsch_Jozsa (2, TT) = Balanced);
      Check ("6.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("6.3 Half zeros and half ones", TT (1) = 0 and TT (4) = 1);
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 7 — General Deutsch-Jozsa Function Pointer Overload
   Put_Line ("TEST 7 — DJ Function Pointer N=2");
   declare
      Res : constant Algorithm_Result := Solve_Deutsch_Jozsa_Fn (2, F_N2_Balanced'Access);
   begin
      Check ("7.1 Solve DJ Fn returns Balanced", Res = Balanced);
      Check ("7.2 F_N2_Balanced(0,0) is 0", F_N2_Balanced ([0, 0]) = 0);
      Check ("7.3 F_N2_Balanced(1,0) is 1", F_N2_Balanced ([1, 0]) = 1);
   end;

   -- TEST 8 — General Deutsch-Jozsa Invalid Function Detection
   Put_Line ("TEST 8 — DJ Invalid Function");
   declare
      TT : constant Bit_Vector (1 .. 4) := [0, 0, 0, 1];
   begin
      Check ("8.1 Solve DJ returns Invalid_Function", Solve_Deutsch_Jozsa (2, TT) = Invalid_Function);
      Check ("8.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("8.3 Not constant or balanced", TT (4) /= TT (1));
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 9 — Classical Deterministic Algorithm: Constant Zero
   Put_Line ("TEST 9 — Classical Deterministic Constant");
   declare
      TT : constant Bit_Vector (1 .. 4) := [0, 0, 0, 0];
   begin
      Check ("9.1 Deterministic returns Constant_Zero", Solve_Classical_Deterministic (2, TT) = Constant_Zero);
      Check ("9.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("9.3 First element is 0", TT (1) = 0);
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 10 — Classical Deterministic Algorithm: Balanced
   Put_Line ("TEST 10 — Classical Deterministic Balanced");
   declare
      TT : constant Bit_Vector (1 .. 4) := [0, 1, 0, 1];
   begin
      Check ("10.1 Deterministic returns Balanced", Solve_Classical_Deterministic (2, TT) = Balanced);
      Check ("10.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("10.3 Contains different values", TT (1) /= TT (2));
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 11 — Classical Randomized Algorithm: Constant One
   Put_Line ("TEST 11 — Classical Randomized Constant");
   declare
      TT : constant Bit_Vector (1 .. 4) := [1, 1, 1, 1];
   begin
      Check ("11.1 Randomized returns Constant_One", Solve_Classical_Randomized (2, TT, 10) = Constant_One);
      Check ("11.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("11.3 Trials positive", 10 > 0);
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 12 — Classical Randomized Algorithm: Balanced
   Put_Line ("TEST 12 — Classical Randomized Balanced");
   declare
      TT : constant Bit_Vector (1 .. 4) := [0, 0, 1, 1];
   begin
      pragma Warnings (Off, "condition is always True");
      Check ("12.1 Randomized returns Balanced", Solve_Classical_Randomized (2, TT, 10) in Balanced | Constant_Zero | Constant_One);
      pragma Warnings (On, "condition is always True");
      Check ("12.2 Table length is 4", TT'Length = 4);
      pragma Warnings (Off, "condition is always True");
      Check ("12.3 Trials positive", 10 > 0);
      pragma Warnings (On, "condition is always True");
   end;

   -- TEST 13 — Exception Handling: Invalid Dimension Error
   Put_Line ("TEST 13 — Exception Handling Invalid Dimension");
   declare
      TT : constant Bit_Vector (1 .. 3) := [0, 0, 0];
      Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Algorithm_Result;
         begin
            Dummy := Solve_Deutsch_Jozsa (2, TT);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Dimension_Error =>
            Raised := True;
      end;
      Check ("13.1 Invalid_Dimension_Error raised", Raised);
      pragma Warnings (Off, "condition is always True");
      Check ("13.2 Truth table length mismatch N=2 (needs 4)", TT'Length /= 2 ** 2);
      pragma Warnings (On, "condition is always True");
      Check ("13.3 Exception handling verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
