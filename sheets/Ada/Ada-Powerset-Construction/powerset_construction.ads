--  Powerset Construction Algorithm Specification
--  Converts an NFA (including ε-NFA) to an equivalent DFA.

with Ada.Containers.Hashed_Sets;
use Ada.Containers;

package Powerset_Construction is

   -- Custom types for the algorithm domain
   type State_Type is range 0 .. Integer'Last;
   type Symbol_Type is range 0 .. Integer'Last;

   -- For sets of states (DFA states are sets of NFA states)
   function State_Hash (S : State_Type) return Hash_Type;
   package State_Sets is new Hashed_Sets
     (Element_Type        => State_Type,
      Hash                => State_Hash,
      Equivalent_Elements => "=");
   subtype State_Set is State_Sets.Set;

   -- For sets of symbols (alphabet)
   function Symbol_Hash (S : Symbol_Type) return Hash_Type;
   package Symbol_Sets is new Hashed_Sets
     (Element_Type        => Symbol_Type,
      Hash                => Symbol_Hash,
      Equivalent_Elements => "=");
   subtype Symbol_Set is Symbol_Sets.Set;

   -- Transition type: from symbol to set of states
   type Transition_Map is array (Symbol_Type range <>) of State_Set;
   type Transition_Map_Access is access Transition_Map;

   -- Transition array: from state to transition map
   type Transition_Array is array (State_Type range <>) of Transition_Map_Access;
   type Transition_Array_Access is access Transition_Array;

   -- NFA and DFA types
   type NFA_Type is record
      States      : State_Set;
      Alphabet    : Symbol_Set;
      Transitions : Transition_Array_Access;
      Initial     : State_Set;
      Accepting   : State_Set;
   end record;

   type DFA_Type is record
      States      : State_Set;
      Alphabet    : Symbol_Set;
      Transitions : Transition_Array_Access;
      Initial     : State_Type;
      Accepting   : State_Set;
   end record;

   -- Exceptions
   Empty_NFA_Error : exception;
   Invalid_Transition_Error : exception;

   -- Basic powerset construction (no ε-moves)
   function Basic_Powerset_Construction (NFA : NFA_Type) return DFA_Type
     with Pre => NFA.States.Length > 0,
          Post => Basic_Powerset_Construction'Result.States.Length > 0;

   -- Powerset construction with ε-closure (for ε-NFA)
   function Powerset_Construction_With_Epsilon (NFA : NFA_Type) return DFA_Type
     with Pre => NFA.States.Length > 0,
          Post => Powerset_Construction_With_Epsilon'Result.States.Length > 0;

   -- Helper: Compute ε-closure for a set of states
   function Epsilon_Closure (NFA : NFA_Type; States : State_Set) return State_Set;

   -- Helper: Compute the next state set for a given state set and symbol
   function Next_State_Set
     (NFA : NFA_Type; Current : State_Set; Symbol : Symbol_Type) return State_Set;

private
   -- Hash functions for State_Type and Symbol_Type
   function State_Hash (S : State_Type) return Hash_Type is
     (Hash_Type(S));

   function Symbol_Hash (S : Symbol_Type) return Hash_Type is
     (Hash_Type(S));

end Powerset_Construction;
