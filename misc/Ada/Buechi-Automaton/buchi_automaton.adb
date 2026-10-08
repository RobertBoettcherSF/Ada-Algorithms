package body Buchi_Automaton is

   -- Validation for Deterministic Büchi Automata
   function Is_Valid (A : DBA) return Boolean is
   begin
      if not A.States.Contains (A.Initial_State) then
         return False;
      end if;
      if not A.Accepting_States.Is_Subset (A.States) then
         return False;
      end if;
      for Pos in A.Transitions.Iterate loop
         if not A.States.Contains (DBA_Transitions.Key (Pos).Source) then
            return False;
         end if;
         if not A.States.Contains (DBA_Transitions.Element (Pos)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid;

   -- Validation for Nondeterministic Büchi Automata
   function Is_Valid (A : NBA) return Boolean is
   begin
      if not A.Initial_States.Is_Subset (A.States) then
         return False;
      end if;
      if not A.Accepting_States.Is_Subset (A.States) then
         return False;
      end if;
      for Pos in A.Transitions.Iterate loop
         if not A.States.Contains (NBA_Transitions.Key (Pos).Source) then
            return False;
         end if;
         if not NBA_Transitions.Element (Pos).Is_Subset (A.States) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid;

   -- Validation for Generalized Büchi Automata
   function Is_Valid (A : GBA) return Boolean is
   begin
      if not A.Initial_States.Is_Subset (A.States) then
         return False;
      end if;
      for Pos in A.Transitions.Iterate loop
         if not A.States.Contains (NBA_Transitions.Key (Pos).Source) then
            return False;
         end if;
         if not NBA_Transitions.Element (Pos).Is_Subset (A.States) then
            return False;
         end if;
      end loop;
      for Set of A.Acceptance_Sets loop
         if not Set.Is_Subset (A.States) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid;

   -- Simulates prefix U, then finds the periodic cycle of repeating V
   function Accepts_Periodic_Word (A : DBA; U, V : String) return Boolean is
      Current : State_Type;
   begin
      if not Is_Valid (A) or else V'Length = 0 then
         raise Invalid_Automaton;
      end if;

      Current := A.Initial_State;
      -- 1. Consume Prefix U
      for C of U loop
         declare
            Key : constant Transition_Key := (Current, C);
         begin
            if not A.Transitions.Contains (Key) then
               return False;
            end if;
            Current := A.Transitions.Element (Key);
         end;
      end loop;

      -- 2. Find Loop Start State (Lasso discovery)
      declare
         Seen_Boundaries  : State_Set;
         Loop_Start_State : State_Type := Current;
      begin
         loop
            if Seen_Boundaries.Contains (Current) then
               Loop_Start_State := Current;
               exit;
            end if;
            Seen_Boundaries.Insert (Current);

            -- Consume V
            for C of V loop
               declare
                  Key : constant Transition_Key := (Current, C);
               begin
                  if not A.Transitions.Contains (Key) then
                     return False;
                  end if;
                  Current := A.Transitions.Element (Key);
               end;
            end loop;
         end loop;

         -- 3. Check if loop contains an Accepting State
         declare
            Check_State : State_Type := Loop_Start_State;
         begin
            loop
               for C of V loop
                  if A.Accepting_States.Contains (Check_State) then
                     return True;
                  end if;
                  Check_State := A.Transitions.Element ((Check_State, C));
               end loop;
               exit when Check_State = Loop_Start_State;
            end loop;
         end;
      end;
      return False;
   end Accepts_Periodic_Word;

   -- Emptiness check for DBA simply delegates to NBA emptiness checking
   function Is_Empty (A : DBA) return Boolean is
   begin
      return Is_Empty (To_NBA (A));
   end Is_Empty;

   -- Helper for NBA Emptiness: Retrieve all target states for a given source
   function Get_Successors (A : NBA; S : State_Type) return State_Set is
      Result : State_Set;
   begin
      for Pos in A.Transitions.Iterate loop
         if NBA_Transitions.Key (Pos).Source = S then
            Result.Union (NBA_Transitions.Element (Pos));
         end if;
      end loop;
      return Result;
   end Get_Successors;

   -- Emptiness check for NBA using Nested Depth-First Search (NDFS)
   function Is_Empty (A : NBA) return Boolean is
      Outer_Visited : State_Set;
      Inner_Visited : State_Set;
      On_Stack      : State_Set;

      function Inner_DFS (S : State_Type) return Boolean is
         Succs : constant State_Set := Get_Successors (A, S);
      begin
         Inner_Visited.Insert (S);
         for T of Succs loop
            if On_Stack.Contains (T) then
               return False; -- Cycle containing accepting state found
            elsif not Inner_Visited.Contains (T) then
               if not Inner_DFS (T) then
                  return False;
               end if;
            end if;
         end loop;
         return True;
      end Inner_DFS;

      function Outer_DFS (S : State_Type) return Boolean is
         Succs : constant State_Set := Get_Successors (A, S);
      begin
         Outer_Visited.Insert (S);
         On_Stack.Insert (S);

         for T of Succs loop
            if not Outer_Visited.Contains (T) then
               if not Outer_DFS (T) then
                  return False;
               end if;
            end if;
         end loop;

         if A.Accepting_States.Contains (S) then
            if not Inner_DFS (S) then
               return False;
            end if;
         end if;

         On_Stack.Exclude (S);
         return True;
      end Outer_DFS;

   begin
      if not Is_Valid (A) then
         raise Invalid_Automaton;
      end if;

      for Init_State of A.Initial_States loop
         if not Outer_Visited.Contains (Init_State) then
            if not Outer_DFS (Init_State) then
               return False; -- Language is NOT empty
            end if;
         end if;
      end loop;
      return True; -- Language is empty
   end Is_Empty;

   -- Conversion: Deterministic to Nondeterministic
   function To_NBA (A : DBA) return NBA is
      Result : NBA;
   begin
      Result.States := A.States;
      Result.Initial_States.Insert (A.Initial_State);
      Result.Accepting_States := A.Accepting_States;

      for Pos in A.Transitions.Iterate loop
         declare
            K : constant Transition_Key := DBA_Transitions.Key (Pos);
            V : constant State_Type     := DBA_Transitions.Element (Pos);
            Target_Set : State_Set;
         begin
            Target_Set.Insert (V);
            Result.Transitions.Insert (K, Target_Set);
         end;
      end loop;
      return Result;
   end To_NBA;

   -- Conversion: Generalized to Nondeterministic
   function To_NBA (A : GBA) return NBA is
      Result : NBA;
      K      : constant Natural := Natural (A.Acceptance_Sets.Length);

      -- Maps a state Q in level I to a unique integer
      function Map_State (S : State_Type; I : Positive) return State_Type is
      begin
         if K = 0 then return S; end if;
         return State_Type ((Natural (S) - 1) * K + I);
      end Map_State;
   begin
      -- Edge case: zero acceptance sets implies all infinite runs are accepted.
      if K = 0 then
         Result.States := A.States;
         Result.Initial_States := A.Initial_States;
         Result.Transitions := A.Transitions;
         Result.Accepting_States := A.States;
         return Result;
      end if;

      -- Create States for each layer 1..K
      for S of A.States loop
         for I in 1 .. K loop
            Result.States.Insert (Map_State (S, I));
         end loop;
      end loop;

      -- Initial States belong to layer 1
      for S of A.Initial_States loop
         Result.Initial_States.Insert (Map_State (S, 1));
      end loop;

      -- Build Transistions mapping levels based on Acceptance condition fulfillment
      for Pos in A.Transitions.Iterate loop
         declare
            Key     : constant Transition_Key := NBA_Transitions.Key (Pos);
            Targets : constant State_Set      := NBA_Transitions.Element (Pos);
            Q       : constant State_Type     := Key.Source;
            Sym     : constant Symbol_Type    := Key.Symbol;
         begin
            for I in 1 .. K loop
               declare
                  Next_I         : Positive := I;
                  Mapped_Targets : State_Set;
               begin
                  if A.Acceptance_Sets.Element (I).Contains (Q) then
                     Next_I := (I mod K) + 1;
                  end if;
                  for T of Targets loop
                     Mapped_Targets.Insert (Map_State (T, Next_I));
                  end loop;
                  Result.Transitions.Insert ((Map_State (Q, I), Sym), Mapped_Targets);
               end;
            end loop;
         end;
      end loop;

      -- Accepting states: The copy corresponding to set 1
      for S of A.Acceptance_Sets.Element (1) loop
         Result.Accepting_States.Insert (Map_State (S, 1));
      end loop;

      return Result;
   end To_NBA;

   -- Helper to safely append to NBA transition target sets
   procedure Add_NBA_Trans (A : in out NBA; Src : State_Type; Sym : Symbol_Type; Tgt : State_Type) is
      Key : constant Transition_Key := (Src, Sym);
      S   : State_Set;
   begin
      if A.Transitions.Contains (Key) then
         S := A.Transitions.Element (Key);
      end if;
      S.Insert (Tgt);
      A.Transitions.Include (Key, S);
   end Add_NBA_Trans;

   -- Helper to safely append to GBA transition target sets
   procedure Add_GBA_Trans (A : in out GBA; Src : State_Type; Sym : Symbol_Type; Tgt : State_Type) is
      Key : constant Transition_Key := (Src, Sym);
      S   : State_Set;
   begin
      if A.Transitions.Contains (Key) then
         S := A.Transitions.Element (Key);
      end if;
      S.Insert (Tgt);
      A.Transitions.Include (Key, S);
   end Add_GBA_Trans;

end Buchi_Automaton;
