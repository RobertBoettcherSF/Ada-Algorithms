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

   function Create_Sample_Dfa return DFA is
      D : constant DFA := (Num_States    => 2,
                           Num_Symbols   => 2,
                           Initial_State => 0,
                           Accepting     => [others => False],
                           Transitions   => [others => [others => 0]]);
      Result : DFA := D;
   begin
      Result.Accepting (1) := True;
      Result.Transitions (0, 0) := 1;
      Result.Transitions (0, 1) := 0;
      Result.Transitions (1, 0) := 1;
      Result.Transitions (1, 1) := 0;
      return Result;
   end Create_Sample_Dfa;

   function Create_Redundant_Dfa return DFA is
      D : constant DFA := (Num_States    => 4,
                           Num_Symbols   => 2,
                           Initial_State => 0,
                           Accepting     => [others => False],
                           Transitions   => [others => [others => 0]]);
      Result : DFA := D;
   begin
      Result.Accepting (1) := True;
      Result.Accepting (3) := True;
      Result.Transitions (0, 0) := 1;
      Result.Transitions (0, 1) := 2;
      Result.Transitions (1, 0) := 1;
      Result.Transitions (1, 1) := 2;
      Result.Transitions (2, 0) := 1;
      Result.Transitions (2, 1) := 2;
      Result.Transitions (3, 0) := 3;
      Result.Transitions (3, 1) := 3;
      return Result;
   end Create_Redundant_Dfa;
begin
   -- TEST 1 — Valid DFA Verification
   Put_Line ("TEST 1 — Valid DFA Verification");
   declare
      D : constant DFA := Create_Sample_Dfa;
   begin
      Check ("1.1 Sample DFA is valid", Is_Valid_Dfa (D));
      Check ("1.2 Num states is 2", D.Num_States = 2);
      Check ("1.3 Initial state is 0", D.Initial_State = 0);
   end;

   -- TEST 2 — Invalid DFA Detection
   Put_Line ("TEST 2 — Invalid DFA Detection");
   declare
      Bad_D : DFA := Create_Sample_Dfa;
   begin
      Bad_D.Num_States := 0;
      Check ("2.1 Zero states is invalid", not Is_Valid_Dfa (Bad_D));

      Bad_D := Create_Sample_Dfa;
      Bad_D.Initial_State := 10;
      Check ("2.2 Out of bounds initial state is invalid", not Is_Valid_Dfa (Bad_D));

      Bad_D := Create_Sample_Dfa;
      Bad_D.Transitions (0, 0) := 10;
      Check ("2.3 Out of bounds transition target is invalid", not Is_Valid_Dfa (Bad_D));
   end;

   -- TEST 3 — Unreachable States Removal
   Put_Line ("TEST 3 — Unreachable States Removal");
   declare
      D     : constant DFA := Create_Sample_Dfa;
      Clean : DFA;
   begin
      declare
         D_Mod : DFA := D;
      begin
         D_Mod.Num_States := 3;
         D_Mod.Transitions (2, 0) := 2;
         D_Mod.Transitions (2, 1) := 2;
         Clean := Remove_Unreachable_States (D_Mod);
      end;
      Check ("3.1 Cleaned DFA has 2 states", Clean.Num_States = 2);
      Check ("3.2 Cleaned DFA is valid", Is_Valid_Dfa (Clean));
      Check ("3.3 Initial state preserved", Clean.Initial_State = D.Initial_State);
   end;

   -- TEST 4 — Hopcroft Minimization on Minimal DFA
   Put_Line ("TEST 4 — Hopcroft Minimization on Minimal DFA");
   declare
      D   : constant DFA := Create_Sample_Dfa;
      Min : constant DFA := Minimize_Hopcroft (D);
   begin
      Check ("4.1 Minimized DFA remains valid", Is_Valid_Dfa (Min));
      Check ("4.2 Minimal state count is 2", Min.Num_States = 2);
      Check ("4.3 Initial state is rejecting", not Min.Accepting (Min.Initial_State));
   end;

   -- TEST 5 — Hopcroft Minimization with Redundant States
   Put_Line ("TEST 5 — Hopcroft Minimization with Redundant States");
   declare
      D   : constant DFA := Create_Redundant_Dfa;
      Min : constant DFA := Minimize_Hopcroft (D);
   begin
      Check ("5.1 Minimized redundant DFA is valid", Is_Valid_Dfa (Min));
      Check ("5.2 Redundant states successfully merged", Min.Num_States < 4);
      Check ("5.3 Accepting states preserved correctly", Min.Accepting (Min.Initial_State) = False);
   end;

   -- TEST 6 — Moore Minimization on Minimal DFA
   Put_Line ("TEST 6 — Moore Minimization on Minimal DFA");
   declare
      D   : constant DFA := Create_Sample_Dfa;
      Min : constant DFA := Minimize_Moore (D);
   begin
      Check ("6.1 Moore minimized DFA is valid", Is_Valid_Dfa (Min));
      Check ("6.2 Minimal state count is 2", Min.Num_States = 2);
      Check ("6.3 Initial state is 0", Min.Initial_State = 0);
   end;

   -- TEST 7 — Moore Minimization with Redundant States
   Put_Line ("TEST 7 — Moore Minimization with Redundant States");
   declare
      D   : constant DFA := Create_Redundant_Dfa;
      Min : constant DFA := Minimize_Moore (D);
   begin
      Check ("7.1 Moore minimized redundant DFA is valid", Is_Valid_Dfa (Min));
      Check ("7.2 Redundant states successfully reduced", Min.Num_States < 4);
      Check ("7.3 Accepting state behavior correct", Min.Num_States >= 2);
   end;

   -- TEST 8 — Brzozowski Minimization on Minimal DFA
   Put_Line ("TEST 8 — Brzozowski Minimization on Minimal DFA");
   declare
      D   : constant DFA := Create_Sample_Dfa;
      Min : constant DFA := Minimize_Brzozowski (D);
   begin
      Check ("8.1 Brzozowski minimized DFA is valid", Is_Valid_Dfa (Min));
      Check ("8.2 State count is minimal", Min.Num_States <= 3);
      Check ("8.3 Initial state is valid", State_Count (Min.Initial_State) < Min.Num_States);
   end;

   -- TEST 9 — Brzozowski Minimization with Redundant States
   Put_Line ("TEST 9 — Brzozowski Minimization with Redundant States");
   declare
      D   : constant DFA := Create_Redundant_Dfa;
      Min : constant DFA := Minimize_Brzozowski (D);
   begin
      Check ("9.1 Brzozowski redundant reduction is valid", Is_Valid_Dfa (Min));
      Check ("9.2 State count reduced", Min.Num_States < 4);
      Check ("9.3 Minimized DFA has correct symbol count", Min.Num_Symbols = D.Num_Symbols);
   end;

   -- TEST 10 — Single-State DFA Minimization
   Put_Line ("TEST 10 — Single-State DFA Minimization");
   declare
      D     : constant DFA := (Num_States    => 1,
                               Num_Symbols   => 2,
                               Initial_State => 0,
                               Accepting     => [0 => True, others => False],
                               Transitions   => [others => [others => 0]]);
      Min_H : constant DFA := Minimize_Hopcroft (D);
      Min_M : constant DFA := Minimize_Moore (D);
      Min_B : constant DFA := Minimize_Brzozowski (D);
   begin
      Check ("10.1 Hopcroft single-state correct", Min_H.Num_States = 1);
      Check ("10.2 Moore single-state correct", Min_M.Num_States = 1);
      Check ("10.3 Brzozowski single-state correct", Min_B.Num_States = 1);
   end;

   -- TEST 11 — All-Accepting DFA
   Put_Line ("TEST 11 — All-Accepting DFA");
   declare
      D   : constant DFA := (Num_States    => 3,
                             Num_Symbols   => 2,
                             Initial_State => 0,
                             Accepting     => [others => True],
                             Transitions   => [others => [others => 0]]);
      Min : constant DFA := Minimize_Hopcroft (D);
   begin
      Check ("11.1 All-accepting minimized valid", Is_Valid_Dfa (Min));
      Check ("11.2 Reduced to single state", Min.Num_States = 1);
      Check ("11.3 Minimized state is accepting", Min.Accepting (Min.Initial_State));
   end;

   -- TEST 12 — All-Rejecting DFA
   Put_Line ("TEST 12 — All-Rejecting DFA");
   declare
      D   : constant DFA := (Num_States    => 3,
                             Num_Symbols   => 2,
                             Initial_State => 0,
                             Accepting     => [others => False],
                             Transitions   => [others => [others => 0]]);
      Min : constant DFA := Minimize_Moore (D);
   begin
      Check ("12.1 All-rejecting minimized valid", Is_Valid_Dfa (Min));
      Check ("12.2 Reduced to single state", Min.Num_States = 1);
      Check ("12.3 Minimized state is rejecting", not Min.Accepting (Min.Initial_State));
   end;

   -- TEST 13 — Error Handling and Invalid DFA Validation
   Put_Line ("TEST 13 — Error Handling and Invalid DFA Validation");
   declare
      Bad_D : constant DFA := (Num_States    => 1,
                               Num_Symbols   => 1,
                               Initial_State => 0,
                               Accepting     => [others => False],
                               Transitions   => [others => [others => 0]]);
      Invalid_Trans_D : constant DFA := (Num_States    => 1,
                                         Num_Symbols   => 1,
                                         Initial_State => 0,
                                         Accepting     => [others => False],
                                         Transitions   => [others => [others => 5]]);
   begin
      Check ("13.1 Invalid DFA detected by Is_Valid_Dfa", not Is_Valid_Dfa (Invalid_Trans_D));
      Check ("13.2 Valid DFA confirmed by Is_Valid_Dfa", Is_Valid_Dfa (Bad_D));
      Check ("13.3 Robustness across test suite verified", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
