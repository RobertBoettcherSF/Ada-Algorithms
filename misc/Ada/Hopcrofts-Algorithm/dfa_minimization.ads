--  DFA Minimization package implementing Hopcroft's, Moore's, and Brzozowski's algorithms.
package Dfa_Minimization is

   Max_States  : constant := 32;
   Max_Symbols : constant := 8;

   type State_Id is range 0 .. Max_States - 1;
   type Symbol_Id is range 0 .. Max_Symbols - 1;

   subtype State_Count is Natural range 0 .. Max_States;
   subtype Symbol_Count is Natural range 0 .. Max_Symbols;

   type Transition_Table is array (State_Id, Symbol_Id) of State_Id;
   type State_Set is array (State_Id) of Boolean;

   type DFA is record
      Num_States    : State_Count;
      Num_Symbols   : Symbol_Count;
      Initial_State : State_Id;
      Accepting     : State_Set;
      Transitions   : Transition_Table;
   end record;

   Invalid_Dfa : exception;

   function Is_Valid_Dfa (D : DFA) return Boolean;

   --  Removes unreachable states from the DFA.
   function Remove_Unreachable_States (Original : DFA) return DFA
     with Pre  => Is_Valid_Dfa (Original),
          Post => Is_Valid_Dfa (Remove_Unreachable_States'Result);

   --  Variant 1: Hopcroft's Algorithm (O(n log n))
   function Minimize_Hopcroft (Original : DFA) return DFA
     with Pre  => Is_Valid_Dfa (Original),
          Post => Is_Valid_Dfa (Minimize_Hopcroft'Result);

   --  Variant 2: Moore's Algorithm (O(n^2))
   function Minimize_Moore (Original : DFA) return DFA
     with Pre  => Is_Valid_Dfa (Original),
          Post => Is_Valid_Dfa (Minimize_Moore'Result);

   --  Variant 3: Brzozowski's Algorithm (Reversal & Powerset Construction twice)
   function Minimize_Brzozowski (Original : DFA) return DFA
     with Pre  => Is_Valid_Dfa (Original),
          Post => Is_Valid_Dfa (Minimize_Brzozowski'Result);

end Dfa_Minimization;
