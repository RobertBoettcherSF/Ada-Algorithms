with Ada.Text_IO; use Ada.Text_IO;
with Powerset_Construction; use Powerset_Construction;
with Ada.Containers; use Ada.Containers;

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

   -- Helper to create a simple NFA for testing
   function Create_Simple_NFA return NFA_Type is
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0, T1 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.States.Insert(1);
      NFA.Alphabet.Insert(0);
      NFA.Alphabet.Insert(1);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(1);

      T0 := new Transition_Map'(0 => <>, 1 => <>);
      T0(0).Insert(0);
      T0(1).Insert(1);
      T1 := new Transition_Map'(0 => <>, 1 => <>);
      T1(0).Insert(1);
      T1(1).Insert(1);

      NFA.Transitions := new Transition_Array'(0 => T0, 1 => T1);
      return NFA;
   end Create_Simple_NFA;

   -- Helper to create an ε-NFA for testing
   function Create_Epsilon_NFA return NFA_Type is
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0, T1, T2 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.States.Insert(1);
      NFA.States.Insert(2);
      NFA.Alphabet.Insert(0);
      NFA.Alphabet.Insert(1);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(2);

      -- ε-transitions (symbol 0 is ε)
      T0 := new Transition_Map'(0 => <>, 1 => <>);
      T0(0).Insert(1); -- ε-transition from 0 to 1
      T0(1).Insert(1);
      T1 := new Transition_Map'(0 => <>, 1 => <>);
      T1(0).Insert(2); -- ε-transition from 1 to 2
      T1(1).Insert(2);
      T2 := new Transition_Map'(0 => <>, 1 => <>);
      T2(0).Insert(2);
      T2(1).Insert(2);

      NFA.Transitions := new Transition_Array'(0 => T0, 1 => T1, 2 => T2);
      return NFA;
   end Create_Epsilon_NFA;

begin
   -- TEST 1 — Basic Powerset Construction: Non-empty NFA
   Put_Line ("TEST 1 — Basic Powerset Construction: Non-empty NFA");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
   begin
      Check("1.1 DFA has states", DFA.States.Length > 0);
      Check("1.2 DFA has initial state", DFA.States.Contains(DFA.Initial));
      Check("1.3 DFA has accepting states", DFA.Accepting.Length > 0);
   end;

   -- TEST 2 — Basic Powerset Construction: Edge case (empty NFA)
   Put_Line ("TEST 2 — Basic Powerset Construction: Edge case (empty NFA)");
   declare
      NFA : constant NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
   begin
      begin
         declare
            DFA : DFA_Type := Basic_Powerset_Construction(NFA);
         begin
            pragma Unreferenced (DFA);
            Check("2.1 Empty NFA raises exception", False);
         end;
      exception
         when Empty_NFA_Error =>
            Check("2.1 Empty NFA raises exception", True);
            Check("2.2 Exception message is correct", True);
            Check("2.3 No DFA is returned", True);
      end;
   end;

   -- TEST 3 — Basic Powerset Construction: Single state NFA
   Put_Line ("TEST 3 — Basic Powerset Construction: Single state NFA");
   declare
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.Alphabet.Insert(0);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(0);
      T0 := new Transition_Map'(0 => <>);
      NFA.Transitions := new Transition_Array'(0 => T0);
      declare
         DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
      begin
         Check("3.1 DFA has one state", DFA.States.Length = 1);
         Check("3.2 DFA initial state is accepting", DFA.Accepting.Contains(DFA.Initial));
         Check("3.3 DFA has transitions array", DFA.Transitions /= null);
      end;
   end;

   -- TEST 4 — Powerset Construction with Epsilon: Non-empty ε-NFA
   Put_Line ("TEST 4 — Powerset Construction with Epsilon: Non-empty ε-NFA");
   declare
      NFA : constant NFA_Type := Create_Epsilon_NFA;
      DFA : constant DFA_Type := Powerset_Construction_With_Epsilon(NFA);
   begin
      Check("4.1 DFA has states", DFA.States.Length > 0);
      Check("4.2 DFA has initial state", DFA.States.Contains(DFA.Initial));
      Check("4.3 DFA has accepting states", DFA.Accepting.Length > 0);
   end;

   -- TEST 5 — Powerset Construction with Epsilon: Edge case (empty ε-NFA)
   Put_Line ("TEST 5 — Powerset Construction with Epsilon: Edge case (empty ε-NFA)");
   declare
      NFA : constant NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
   begin
      begin
         declare
            DFA : DFA_Type := Powerset_Construction_With_Epsilon(NFA);
         begin
            pragma Unreferenced (DFA);
            Check("5.1 Empty ε-NFA raises exception", False);
         end;
      exception
         when Empty_NFA_Error =>
            Check("5.1 Empty ε-NFA raises exception", True);
            Check("5.2 Exception message is correct", True);
            Check("5.3 No DFA is returned", True);
      end;
   end;

   -- TEST 6 — Powerset Construction with Epsilon: Single state ε-NFA
   Put_Line ("TEST 6 — Powerset Construction with Epsilon: Single state ε-NFA");
   declare
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.Alphabet.Insert(0);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(0);
      T0 := new Transition_Map'(0 => <>);
      NFA.Transitions := new Transition_Array'(0 => T0);
      declare
         DFA : constant DFA_Type := Powerset_Construction_With_Epsilon(NFA);
      begin
         Check("6.1 DFA has one state", DFA.States.Length = 1);
         Check("6.2 DFA initial state is accepting", DFA.Accepting.Contains(DFA.Initial));
         Check("6.3 DFA has transitions array", DFA.Transitions /= null);
      end;
   end;

   -- TEST 7 — Epsilon Closure: Single state
   Put_Line ("TEST 7 — Epsilon Closure: Single state");
   declare
      NFA : constant NFA_Type := Create_Epsilon_NFA;
      States : State_Set;
   begin
      States.Insert(0);
      declare
         Closure : constant State_Set := Epsilon_Closure(NFA, States);
      begin
         Check("7.1 Closure includes state 0", Closure.Contains(0));
         Check("7.2 Closure includes state 1", Closure.Contains(1));
         Check("7.3 Closure includes state 2", Closure.Contains(2));
      end;
   end;

   -- TEST 8 — Epsilon Closure: Multiple states
   Put_Line ("TEST 8 — Epsilon Closure: Multiple states");
   declare
      NFA : constant NFA_Type := Create_Epsilon_NFA;
      States : State_Set;
   begin
      States.Insert(0);
      States.Insert(1);
      declare
         Closure : constant State_Set := Epsilon_Closure(NFA, States);
      begin
         Check("8.1 Closure includes state 0", Closure.Contains(0));
         Check("8.2 Closure includes state 1", Closure.Contains(1));
         Check("8.3 Closure includes state 2", Closure.Contains(2));
      end;
   end;

   -- TEST 9 — Next State Set: Non-empty
   Put_Line ("TEST 9 — Next State Set: Non-empty");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      States : State_Set;
   begin
      States.Insert(0);
      declare
         Next : constant State_Set := Next_State_Set(NFA, States, 0);
      begin
         Check("9.1 Next state set is non-empty", Next.Length > 0);
         Check("9.2 Next state set contains state 0", Next.Contains(0));
         Check("9.3 Next state set does not contain state 1", not Next.Contains(1));
      end;
   end;

   -- TEST 10 — Next State Set: Empty
   Put_Line ("TEST 10 — Next State Set: Empty");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      States : State_Set;
   begin
      States.Insert(1);
      declare
         Next : constant State_Set := Next_State_Set(NFA, States, 1);
      begin
         Check("10.1 Next state set is non-empty", Next.Length > 0);
         Check("10.2 Next state set contains state 1", Next.Contains(1));
         Check("10.3 Next state set does not contain state 0", not Next.Contains(0));
      end;
   end;

   -- TEST 11 — DFA Accepting States: Correct
   Put_Line ("TEST 11 — DFA Accepting States: Correct");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
   begin
      Check("11.1 DFA has accepting states", DFA.Accepting.Length > 0);
      Check("11.2 DFA accepting states are in DFA states",
            (for all S of DFA.Accepting => DFA.States.Contains(S)));
      Check("11.3 DFA initial state is valid", DFA.States.Contains(DFA.Initial));
   end;

   -- TEST 12 — DFA Transitions: Valid
   Put_Line ("TEST 12 — DFA Transitions: Valid");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
   begin
      Check("12.1 DFA transitions array is non-null", DFA.Transitions /= null);
      Check("12.2 DFA transitions for initial state exist",
            DFA.Transitions(DFA.Initial) /= null);
      Check("12.3 DFA transitions for initial state are non-empty",
            DFA.Transitions(DFA.Initial).all'Length > 0);
   end;

   -- TEST 13 — DFA Alphabet: Matches NFA
   Put_Line ("TEST 13 — DFA Alphabet: Matches NFA");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
   begin
      Check("13.1 DFA alphabet is non-empty", DFA.Alphabet.Length > 0);
      Check("13.2 DFA alphabet matches NFA alphabet",
            DFA.Alphabet.Length = NFA.Alphabet.Length);
      Check("13.3 DFA alphabet size is correct",
            DFA.Alphabet.Length = NFA.Alphabet.Length);
   end;

   -- Summary
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
