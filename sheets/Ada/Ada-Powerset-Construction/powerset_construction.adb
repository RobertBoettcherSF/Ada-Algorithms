--  Powerset Construction Algorithm Implementation

with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;

package body Powerset_Construction is

   use State_Sets;

   -- Instantiate a list of State_Type for stack operations
   package State_List_Pkg is new Ada.Containers.Doubly_Linked_Lists(State_Type);
   use State_List_Pkg;

   -- Instantiate a vector of State_Set for DFA states with State_Type index
   package State_Set_Vectors is new Ada.Containers.Vectors
     (Index_Type   => State_Type,
      Element_Type => State_Set);
   use State_Set_Vectors;

   -- Instantiate a list of State_Set for BFS queue
   package State_Set_List_Pkg is new Ada.Containers.Doubly_Linked_Lists(State_Set);
   use State_Set_List_Pkg;

   -- Helper: Check if two State_Sets are equivalent
   function State_Sets_Equal (Left, Right : State_Set) return Boolean is
   begin
      if Left.Length /= Right.Length then
         return False;
      end if;
      for Item of Left loop
         if not Right.Contains(Item) then
            return False;
         end if;
      end loop;
      return True;
   end State_Sets_Equal;

   -- Helper: Find the index of a State_Set in a vector
   function Find_State_Set_Index
     (States : State_Set_Vectors.Vector; Target : State_Set) return State_Type
   is
   begin
      for I in 0 .. State_Type(States.Length - 1) loop
         if State_Sets_Equal(States.Element(I), Target) then
            return I;
         end if;
      end loop;
      return State_Type'Last;
   end Find_State_Set_Index;

   -- Helper: Compute ε-closure for a single state
   function Epsilon_Closure_For_State
     (NFA : NFA_Type; State : State_Type) return State_Set
   is
      Result : State_Set;
      Stack  : State_List_Pkg.List;
      Visited : State_Set;
   begin
      Stack.Append(State);
      Visited.Insert(State);

      while not Stack.Is_Empty loop
         declare
            Current : constant State_Type := Stack.First_Element;
         begin
            Stack.Delete_First;
            Result.Insert(Current);

            if NFA.Transitions /= null and then
               Current in NFA.Transitions.all'Range and then
               NFA.Transitions(Current) /= null and then
               NFA.Transitions(Current).all'Length > 0 then
               -- Assume symbol 0 is ε (for simplicity; in practice, use a dedicated ε symbol)
               for S of NFA.Transitions(Current)(0) loop
                  if not Visited.Contains(S) then
                     Visited.Insert(S);
                     Stack.Append(S);
                  end if;
               end loop;
            end if;
         end;
      end loop;

      return Result;
   end Epsilon_Closure_For_State;

   -- Helper: Compute ε-closure for a set of states
   function Epsilon_Closure (NFA : NFA_Type; States : State_Set) return State_Set is
      Result : State_Set;
   begin
      for S of States loop
         Result.Union(Epsilon_Closure_For_State(NFA, S));
      end loop;
      return Result;
   end Epsilon_Closure;

   -- Helper: Compute the next state set for a given state set and symbol
   function Next_State_Set
     (NFA : NFA_Type; Current : State_Set; Symbol : Symbol_Type) return State_Set
   is
      Result : State_Set;
   begin
      for S of Current loop
         if NFA.Transitions /= null and then
            S in NFA.Transitions.all'Range and then
            NFA.Transitions(S) /= null and then
            Symbol in NFA.Transitions(S).all'Range and then
            NFA.Transitions(S)(Symbol).Length > 0 then
            Result.Union(NFA.Transitions(S)(Symbol));
         end if;
      end loop;
      return Result;
   end Next_State_Set;

   -- Basic powerset construction (no ε-moves)
   function Basic_Powerset_Construction (NFA : NFA_Type) return DFA_Type is
      -- Vector of DFA states (State_Set)
      DFA_States : State_Set_Vectors.Vector;

      -- Current DFA state index
      Next_State_Index : State_Type := 0;

      -- Initialize DFA states with ε-closure of NFA initial state
      Initial_Set : State_Set := NFA.Initial;
      DFA_Initial : State_Type;

      -- Queue for BFS traversal
      Queue_Sets : State_Set_List_Pkg.List;

   begin
      if NFA.States.Length = 0 then
         raise Empty_NFA_Error with "NFA has no states";
      end if;

      -- Compute initial DFA state
      Initial_Set := Epsilon_Closure(NFA, Initial_Set);
      DFA_States.Append(Initial_Set);
      DFA_Initial := Next_State_Index;
      Next_State_Index := Next_State_Index + 1;
      Queue_Sets.Append(Initial_Set);

      -- Process each DFA state using BFS
      while not Queue_Sets.Is_Empty loop
         declare
            Current_Set : constant State_Set := Queue_Sets.First_Element;
         begin
            Queue_Sets.Delete_First;

            -- For each symbol in the alphabet
            for Sym of NFA.Alphabet loop
               declare
                  Next_Set : State_Set := Next_State_Set(NFA, Current_Set, Sym);
               begin
                  if Next_Set.Length > 0 then
                     Next_Set := Epsilon_Closure(NFA, Next_Set);
                     -- Check if this set is already a DFA state
                     if Find_State_Set_Index(DFA_States, Next_Set) = State_Type'Last then
                        DFA_States.Append(Next_Set);
                        Queue_Sets.Append(Next_Set);
                        Next_State_Index := Next_State_Index + 1;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;

      -- Build DFA
      declare
         DFA : DFA_Type;
         DFA_Transitions_Array : constant Transition_Array_Access :=
           new Transition_Array'(0 .. Next_State_Index - 1 => null);
      begin
         -- Populate DFA.States from DFA_States indices
         for I in 0 .. State_Type(DFA_States.Length - 1) loop
            DFA.States.Insert(I);
         end loop;

         DFA.Alphabet := NFA.Alphabet;
         DFA.Initial := DFA_Initial;
         DFA.Transitions := DFA_Transitions_Array;

         -- Build DFA transitions
         for I in 0 .. State_Type(DFA_States.Length - 1) loop
            declare
               Current_Set : constant State_Set := DFA_States.Element(I);
               Trans_Map : constant Transition_Map_Access :=
                 new Transition_Map'(0 .. Symbol_Type(NFA.Alphabet.Length - 1) => <>);
            begin
               DFA.Transitions(I) := Trans_Map;
               for Sym of NFA.Alphabet loop
                  declare
                     Next_Set : State_Set := Next_State_Set(NFA, Current_Set, Sym);
                     Next_Index : State_Type;
                  begin
                     if Next_Set.Length > 0 then
                        Next_Set := Epsilon_Closure(NFA, Next_Set);
                        Next_Index := Find_State_Set_Index(DFA_States, Next_Set);
                        if Next_Index /= State_Type'Last then
                           DFA.Transitions(I)(Sym).Insert(Next_Index);
                        end if;
                     end if;
                  end;
               end loop;
            end;
         end loop;

         -- Build DFA accepting states
         for I in 0 .. State_Type(DFA_States.Length - 1) loop
            declare
               State_Set_Key : constant State_Set := DFA_States.Element(I);
            begin
               for A of NFA.Accepting loop
                  if State_Set_Key.Contains(A) then
                     DFA.Accepting.Insert(I);
                     exit;
                  end if;
               end loop;
            end;
         end loop;

         return DFA;
      end;
   end Basic_Powerset_Construction;

   -- Powerset construction with ε-closure (for ε-NFA)
   function Powerset_Construction_With_Epsilon (NFA : NFA_Type) return DFA_Type is
   begin
      -- For ε-NFA, the basic powerset construction already handles ε-closure
      return Basic_Powerset_Construction(NFA);
   end Powerset_Construction_With_Epsilon;

end Powerset_Construction;
