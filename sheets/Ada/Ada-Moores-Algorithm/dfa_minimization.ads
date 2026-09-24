--  DFA Minimization package implementing Moore's algorithm in Ada 2023.
--  Provides deterministic finite automaton representation, validation, and minimization.

package Dfa_Minimization is

   Max_States_Count  : constant := 32;
   Max_Symbols_Count : constant := 8;

   subtype State_Range is Natural range 0 .. Max_States_Count - 1;
   subtype Symbol_Range is Natural range 0 .. Max_Symbols_Count - 1;

   type State_Count_Range is range 0 .. Max_States_Count;
   type Symbol_Count_Range is range 0 .. Max_Symbols_Count;

   type Transition_Table is array (State_Range, Symbol_Range) of State_Range;
   type State_Set is array (State_Range) of Boolean;

   type DFA_Type (Num_States : State_Count_Range; Num_Symbols : Symbol_Count_Range) is record
      Transitions : Transition_Table := [others => [others => 0]];
      Initial     : State_Range      := 0;
      Finals      : State_Set        := [others => False];
   end record;

   -- Exceptions for error handling
   Invalid_Dfa_Exception : exception;
   State_Out_Of_Bounds   : exception;

   -- Validates structural integrity of a DFA (e.g., initial state in range,
   -- transition targets within Num_States, etc.)
   function Validate_Dfa (Dfa : DFA_Type) return Boolean;

   -- Minimizes a DFA using Moore's algorithm.
   function Minimize_Moore (Dfa : DFA_Type) return DFA_Type
     with Pre  => Validate_Dfa (Dfa) and then Dfa.Num_States > 0,
          Post => Minimize_Moore'Result.Num_States <= Dfa.Num_States
                  and then Validate_Dfa (Minimize_Moore'Result);

end Dfa_Minimization;
