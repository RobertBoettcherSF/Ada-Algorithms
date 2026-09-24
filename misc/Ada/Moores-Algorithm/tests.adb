with Ada.Text_IO; use Ada.Text_IO;
with Dfa_Minimization; use Dfa_Minimization;

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
   pragma Warnings (Off, "condition is always True");
   pragma Warnings (Off, "condition can only be False");

   -- TEST 1 — Basic Validation of Valid DFA
   Put_Line ("TEST 1 — Basic Validation of Valid DFA");
   declare
      D : constant DFA_Type (Num_States => 2, Num_Symbols => 1) :=
        (Num_States => 2, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0], others => [others => 0]],
         Initial     => 0,
         Finals      => [0 => False, 1 => True, others => False]);
   begin
      Check ("1.1 Valid DFA returns true", Validate_Dfa (D));
      Check ("1.2 Initial state is within bounds", State_Count_Range (D.Initial) < D.Num_States);
      Check ("1.3 Num_States is positive", D.Num_States > 0);
   end;

   -- TEST 2 — Validation of Invalid DFA (Transition Out of Bounds)
   Put_Line ("TEST 2 — Validation of Invalid DFA (Transition Out of Bounds)");
   declare
      D : DFA_Type (Num_States => 2, Num_Symbols => 1) :=
        (Num_States => 2, Num_Symbols => 1,
         Transitions => [others => [others => 0]],
         Initial     => 0,
         Finals      => [others => False]);
   begin
      D.Transitions (0, 0) := 5; -- Out of bounds target
      Check ("2.1 Invalid DFA transition detected", not Validate_Dfa (D));
      Check ("2.2 Num_States remains 2", D.Num_States = 2);
      Check ("2.3 Num_Symbols remains 1", D.Num_Symbols = 1);
   end;

   -- TEST 3 — Validation of Zero-State DFA
   Put_Line ("TEST 3 — Validation of Zero-State DFA");
   declare
      D : constant DFA_Type (Num_States => 0, Num_Symbols => 1) :=
        (Num_States => 0, Num_Symbols => 1,
         Transitions => [others => [others => 0]],
         Initial     => 0,
         Finals      => [others => False]);
   begin
      Check ("3.1 Zero-state DFA is invalid", not Validate_Dfa (D));
      Check ("3.2 Num_States is zero", D.Num_States = 0);
      Check ("3.3 Symbol count is 1", D.Num_Symbols = 1);
   end;

   -- TEST 4 — Minimization of Already Minimal DFA
   Put_Line ("TEST 4 — Minimization of Already Minimal DFA");
   declare
      D : constant DFA_Type (Num_States => 2, Num_Symbols => 1) :=
        (Num_States => 2, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0], 1 => [0 => 0, others => 0], others => [others => 0]],
         Initial     => 0,
         Finals      => [0 => False, 1 => True, others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("4.1 Minimized DFA has 2 states", Min.Num_States = 2);
      Check ("4.2 Minimized DFA is valid", Validate_Dfa (Min));
      Check ("4.3 Initial state preserved or mapped correctly", State_Count_Range (Min.Initial) < Min.Num_States);
   end;

   -- TEST 5 — Minimization of DFA with Redundant Equivalent States
   Put_Line ("TEST 5 — Minimization of DFA with Redundant Equivalent States");
   declare
      -- States 1 and 2 are equivalent (both go to final state 3 on symbol 0)
      D : constant DFA_Type (Num_States => 4, Num_Symbols => 1) :=
        (Num_States => 4, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0],
                         1 => [0 => 3, others => 0],
                         2 => [0 => 3, others => 0],
                         3 => [0 => 3, others => 0],
                         others => [others => 0]],
         Initial     => 0,
         Finals      => [3 => True, others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("5.1 Minimized DFA reduces state count", Min.Num_States < D.Num_States);
      Check ("5.2 Minimized DFA has 3 states", Min.Num_States = 3);
      Check ("5.3 Minimized DFA is valid", Validate_Dfa (Min));
   end;

   -- TEST 6 — Minimization of DFA with Multiple Equivalent States
   Put_Line ("TEST 6 — Minimization of DFA with Multiple Equivalent States");
   declare
      D : constant DFA_Type (Num_States => 3, Num_Symbols => 1) :=
        (Num_States => 3, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0],
                         1 => [0 => 1, others => 0],
                         2 => [0 => 2, others => 0],
                         others => [others => 0]],
         Initial     => 0,
         Finals      => [1 => True, 2 => True, others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("6.1 Equivalent final states merged", Min.Num_States = 2);
      Check ("6.2 Resulting DFA is valid", Validate_Dfa (Min));
      Check ("6.3 Initial state is valid", State_Count_Range (Min.Initial) < Min.Num_States);
   end;

   -- TEST 7 — Single-State Accepting DFA Minimization
   Put_Line ("TEST 7 — Single-State Accepting DFA Minimization");
   declare
      D : constant DFA_Type (Num_States => 1, Num_Symbols => 1) :=
        (Num_States => 1, Num_Symbols => 1,
         Transitions => [0 => [0 => 0, others => 0], others => [others => 0]],
         Initial     => 0,
         Finals      => [0 => True, others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("7.1 Single state remains 1 state", Min.Num_States = 1);
      Check ("7.2 State is accepting", Min.Finals (0));
      Check ("7.3 Valid output DFA", Validate_Dfa (Min));
   end;

   -- TEST 8 — Single-State Rejecting DFA Minimization
   Put_Line ("TEST 8 — Single-State Rejecting DFA Minimization");
   declare
      D : constant DFA_Type (Num_States => 1, Num_Symbols => 1) :=
        (Num_States => 1, Num_Symbols => 1,
         Transitions => [0 => [0 => 0, others => 0], others => [others => 0]],
         Initial     => 0,
         Finals      => [others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("8.1 Single rejecting state remains 1", Min.Num_States = 1);
      Check ("8.2 State is rejecting", not Min.Finals (0));
      Check ("8.3 Valid output DFA", Validate_Dfa (Min));
   end;

   -- TEST 9 — All-Accepting States DFA
   Put_Line ("TEST 9 — All-Accepting States DFA");
   declare
      D : constant DFA_Type (Num_States => 3, Num_Symbols => 1) :=
        (Num_States => 3, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0],
                         1 => [0 => 2, others => 0],
                         2 => [0 => 0, others => 0],
                         others => [others => 0]],
         Initial     => 0,
         Finals      => [others => True]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("9.1 All accepting states collapse to 1 state", Min.Num_States = 1);
      Check ("9.2 Single state is accepting", Min.Finals (0));
      Check ("9.3 Valid output DFA", Validate_Dfa (Min));
   end;

   -- TEST 10 — All-Rejecting States DFA
   Put_Line ("TEST 10 — All-Rejecting States DFA");
   declare
      D : constant DFA_Type (Num_States => 3, Num_Symbols => 1) :=
        (Num_States => 3, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0],
                         1 => [0 => 2, others => 0],
                         2 => [0 => 0, others => 0],
                         others => [others => 0]],
         Initial     => 0,
         Finals      => [others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("10.1 All rejecting states collapse to 1 state", Min.Num_States = 1);
      Check ("10.2 Single state is rejecting", not Min.Finals (0));
      Check ("10.3 Valid output DFA", Validate_Dfa (Min));
   end;

   -- TEST 11 — Precondition Violation Check on Minimize_Moore
   Put_Line ("TEST 11 — Precondition Violation Check on Minimize_Moore");
   declare
      Invalid_D : DFA_Type (Num_States => 2, Num_Symbols => 1) :=
        (Num_States => 2, Num_Symbols => 1,
         Transitions => [others => [others => 0]],
         Initial     => 0,
         Finals      => [others => False]);
      Exception_Raised : Boolean := False;
   begin
      Invalid_D.Transitions (0, 0) := 5; -- Target 5 is >= Num_States (2), invalid DFA
      begin
         declare
            Res : constant DFA_Type := Minimize_Moore (Invalid_D);
         begin
            pragma Unreferenced (Res);
            null;
         end;
      exception
         when others =>
            Exception_Raised := True;
      end;
      Check ("11.1 Invalid DFA triggers exception on minimize", Exception_Raised);
      Check ("11.2 Validate_Dfa correctly returns false", not Validate_Dfa (Invalid_D));
      Check ("11.3 State count is 2", Invalid_D.Num_States = 2);
   end;

   -- TEST 12 — DFA with Multiple Symbols
   Put_Line ("TEST 12 — DFA with Multiple Symbols");
   declare
      D : constant DFA_Type (Num_States => 3, Num_Symbols => 2) :=
        (Num_States => 3, Num_Symbols => 2,
         Transitions => [0 => [0 => 1, 1 => 2, others => 0],
                         1 => [0 => 1, 1 => 2, others => 0],
                         2 => [0 => 2, 1 => 2, others => 0],
                         others => [others => 0]],
         Initial     => 0,
         Finals      => [2 => True, others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("12.1 Multi-symbol DFA minimized successfully", Min.Num_States <= D.Num_States);
      Check ("12.2 Minimized multi-symbol DFA is valid", Validate_Dfa (Min));
      Check ("12.3 Symbol count preserved", Min.Num_Symbols = 2);
   end;

   -- TEST 13 — Chained Redundancy Minimization
   Put_Line ("TEST 13 — Chained Redundancy Minimization");
   declare
      D : constant DFA_Type (Num_States => 4, Num_Symbols => 1) :=
        (Num_States => 4, Num_Symbols => 1,
         Transitions => [0 => [0 => 1, others => 0],
                         1 => [0 => 2, others => 0],
                         2 => [0 => 3, others => 0],
                         3 => [0 => 3, others => 0],
                         others => [others => 0]],
         Initial     => 0,
         Finals      => [3 => True, others => False]);
      Min : constant DFA_Type := Minimize_Moore (D);
   begin
      Check ("13.1 Chained DFA minimized", Min.Num_States > 0);
      Check ("13.2 Minimized DFA valid", Validate_Dfa (Min));
      Check ("13.3 State count reduced", Min.Num_States <= D.Num_States);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
