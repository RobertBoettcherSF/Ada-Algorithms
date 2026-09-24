with Ada.Text_IO; use Ada.Text_IO;
with Buchi_Automaton; use Buchi_Automaton;

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

   -- Helpers for initial setup
   D  : DBA;
   D2 : DBA;
   N  : NBA;
   N2 : NBA;
   G  : GBA;
   G2 : GBA;

   Exception_Caught : Boolean;

begin
   -- TEST 1 - DBA Validation
   Put_Line ("TEST 1 — DBA Validation");
   D.States.Insert (1); D.States.Insert (2);
   D.Initial_State := 1;
   D.Accepting_States.Insert (2);
   D.Transitions.Insert ((1, 'a'), 2);
   D.Transitions.Insert ((2, 'a'), 2);
   
   Check ("1.1 Valid DBA is Valid", Is_Valid (D));
   
   D2 := D;
   D2.Initial_State := 99;
   Check ("1.2 Bad Initial State makes Invalid", not Is_Valid (D2));
   
   D2 := D;
   D2.Accepting_States.Insert (99);
   Check ("1.3 Bad Accepting State makes Invalid", not Is_Valid (D2));

   -- TEST 2 - NBA Validation
   Put_Line ("TEST 2 — NBA Validation");
   N.States.Insert (1); N.States.Insert (2);
   N.Initial_States.Insert (1);
   N.Accepting_States.Insert (2);
   Add_NBA_Trans (N, 1, 'a', 1);
   Add_NBA_Trans (N, 1, 'a', 2);
   
   Check ("2.1 Valid NBA is Valid", Is_Valid (N));
   
   N2 := N;
   N2.Initial_States.Insert (99);
   Check ("2.2 Bad Initial State in NBA makes Invalid", not Is_Valid (N2));
   
   N2 := N;
   Add_NBA_Trans (N2, 2, 'b', 99);
   Check ("2.3 Bad Transition Target makes Invalid", not Is_Valid (N2));

   -- TEST 3 - GBA Validation
   Put_Line ("TEST 3 — GBA Validation");
   G.States.Insert (1); G.States.Insert (2);
   G.Initial_States.Insert (1);
   declare
      F1 : State_Set;
   begin
      F1.Insert (2);
      G.Acceptance_Sets.Append (F1);
   end;
   Add_GBA_Trans (G, 1, 'x', 2);

   Check ("3.1 Valid GBA is Valid", Is_Valid (G));
   
   G2 := G;
   G2.States.Exclude (1);
   Check ("3.2 GBA missing Initial State invalidates", not Is_Valid (G2));
   
   G2 := G;
   declare
      F2 : State_Set;
   begin
      F2.Insert (99);
      G2.Acceptance_Sets.Append (F2);
   end;
   Check ("3.3 GBA bad Acceptance set invalidates", not Is_Valid (G2));

   -- TEST 4 - DBA Periodic Word Accept
   Put_Line ("TEST 4 — DBA Periodic Word Accept");
   Check ("4.1 Loop self immediately", Accepts_Periodic_Word (D, "", "a"));
   Check ("4.2 Prefix then loop", Accepts_Periodic_Word (D, "aaa", "a"));
   
   -- Build cyclical word accept DBA
   D2.States.Clear; D2.Transitions.Clear; D2.Accepting_States.Clear;
   D2.States.Insert (1); D2.States.Insert (2); D2.States.Insert (3);
   D2.Initial_State := 1;
   D2.Accepting_States.Insert (3);
   D2.Transitions.Insert ((1, 'a'), 2);
   D2.Transitions.Insert ((2, 'b'), 3);
   D2.Transitions.Insert ((3, 'c'), 2);
   Check ("4.3 Extended cycle accept", Accepts_Periodic_Word (D2, "a", "bc"));

   -- TEST 5 - DBA Periodic Word Reject
   Put_Line ("TEST 5 — DBA Periodic Word Reject");
   Check ("5.1 Reject word missing transition", not Accepts_Periodic_Word (D, "b", "a"));
   Check ("5.2 Reject word missing loop transition", not Accepts_Periodic_Word (D, "", "b"));
   
   D2.Accepting_States.Clear; 
   D2.Accepting_States.Insert (1); -- State 3 no longer accepting
   Check ("5.3 Reject loop lacking accepting state", not Accepts_Periodic_Word (D2, "a", "bc"));

   -- TEST 6 - DBA Periodic Word Exceptions
   Put_Line ("TEST 6 — DBA Periodic Word Exceptions");
   Exception_Caught := False;
   begin
      declare
         Res : constant Boolean := Accepts_Periodic_Word (D, "a", "");
         pragma Unreferenced (Res);
      begin null; end;
   exception
      when Invalid_Automaton => Exception_Caught := True;
   end;
   Check ("6.1 V empty raises error", Exception_Caught);

   D2.Initial_State := 99; -- Invalidates D2
   Exception_Caught := False;
   begin
      declare
         Res : constant Boolean := Accepts_Periodic_Word (D2, "a", "a");
         pragma Unreferenced (Res);
      begin null; end;
   exception
      when Invalid_Automaton => Exception_Caught := True;
   end;
   Check ("6.2 Invalid DBA raises error", Exception_Caught);

   Exception_Caught := False;
   begin
      declare
         Res : constant Boolean := Accepts_Periodic_Word (D2, "", "");
         pragma Unreferenced (Res);
      begin null; end;
   exception
      when Invalid_Automaton => Exception_Caught := True;
   end;
   Check ("6.3 Invalid DBA and Empty V error", Exception_Caught);

   -- TEST 7 - DBA Emptiness (Empty automata)
   Put_Line ("TEST 7 — DBA Emptiness (Empty)");
   D2 := D;
   D2.Accepting_States.Clear;
   Check ("7.1 DBA with no accepting states is empty", Is_Empty (D2));

   D2.Accepting_States.Insert (1);
   D2.Transitions.Clear;
   Check ("7.2 DBA with no transitions is empty", Is_Empty (D2));

   D2.Transitions.Insert ((1, 'a'), 2);
   Check ("7.3 DBA with dead end is empty", Is_Empty (D2));

   -- TEST 8 - DBA Emptiness (Non-empty automata)
   Put_Line ("TEST 8 — DBA Emptiness (Non-empty)");
   Check ("8.1 DBA with self-loop accepting is not empty", not Is_Empty (D));

   D2.Transitions.Clear;
   D2.Transitions.Insert ((1, 'a'), 2);
   D2.Transitions.Insert ((2, 'b'), 1);
   D2.Accepting_States.Clear;
   D2.Accepting_States.Insert (2);
   Check ("8.2 DBA with distant accepting cycle not empty", not Is_Empty (D2));

   D2.Accepting_States.Clear;
   D2.Accepting_States.Insert (1);
   Check ("8.3 DBA with initial accepting cycle not empty", not Is_Empty (D2));

   -- TEST 9 - NBA Emptiness (Empty automata)
   Put_Line ("TEST 9 — NBA Emptiness (Empty)");
   N2 := N;
   N2.Accepting_States.Clear;
   Check ("9.1 NBA with no accepting states is empty", Is_Empty (N2));

   N2 := N;
   N2.Transitions.Clear;
   Check ("9.2 NBA with no transitions is empty", Is_Empty (N2));

   N2 := N;
   N2.Initial_States.Clear;
   Check ("9.3 NBA with no initial states is empty", Is_Empty (N2));

   -- TEST 10 - NBA Emptiness (Non-empty automata)
   Put_Line ("TEST 10 — NBA Emptiness (Non-empty)");
   -- N's accepting state (2) previously had no outgoing transitions, making the language empty.
   -- We add a transition back to 1 to establish a valid cycle infinitely visiting state 2.
   Add_NBA_Trans (N, 2, 'b', 1);
   Check ("10.1 Nondeterministic paths finding cycle", not Is_Empty (N));

   N2 := To_NBA (D);
   Check ("10.2 DBA translated to NBA preserves non-emptiness", not Is_Empty (N2));

   Add_NBA_Trans (N, 2, 'z', 2);
   Check ("10.3 Extra nondeterministic loops don't break", not Is_Empty (N));

   -- TEST 11 - GBA to NBA Basic
   Put_Line ("TEST 11 — GBA to NBA Conversion Basics");
   N2 := To_NBA (G);
   Check ("11.1 GBA translation produces valid NBA", Is_Valid (N2));
   
   Check ("11.2 Size of states multiplies by K", Natural (N2.States.Length) = Natural (G.States.Length) * 1);
   Check ("11.3 Empty checks match expected behavior", Is_Empty (N2)); -- G has no cycles

   -- TEST 12 - GBA to NBA Completeness
   Put_Line ("TEST 12 — GBA to NBA Completeness");
   G.States.Insert (3);
   G.Acceptance_Sets.Clear;
   declare
      F1, F2 : State_Set;
   begin
      F1.Insert (2); G.Acceptance_Sets.Append (F1);
      F2.Insert (3); G.Acceptance_Sets.Append (F2);
   end;
   Add_GBA_Trans (G, 2, 'y', 3);
   Add_GBA_Trans (G, 3, 'z', 1);
   
   N2 := To_NBA (G);
   Check ("12.1 Multi-layer GBA translates cleanly", Is_Valid (N2));
   Check ("12.2 Multi-layer NBA state count correct", Natural (N2.States.Length) = Natural (G.States.Length) * 2);
   Check ("12.3 Multi-layer converted NBA catches cyclic language", not Is_Empty (N2));

   -- TEST 13 - GBA to NBA Zero Sets
   Put_Line ("TEST 13 — GBA to NBA Empty Acceptance Sets");
   G.Acceptance_Sets.Clear;
   N2 := To_NBA (G);
   
   Check ("13.1 GBA with 0 acceptance sets valid translation", Is_Valid (N2));
   Check ("13.2 State counts identical (K=0 fallback)", Natural (N2.States.Length) = Natural (G.States.Length));
   Check ("13.3 All states accepting when K=0", Natural (N2.Accepting_States.Length) = Natural (G.States.Length));


   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
