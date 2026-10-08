pragma Ada_2022;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;

package Buchi_Automaton is

   -- Core types representing States and Alphabet Symbols
   type State_Type is new Positive;
   subtype Symbol_Type is Character;

   -- Standardized ordered set of States
   package State_Sets is new Ada.Containers.Ordered_Sets
     (Element_Type => State_Type);
   subtype State_Set is State_Sets.Set;
   
   -- Make the element equality operator visible for subsequent generic instantiations
   use type State_Sets.Set;

   -- Transition Key mapping a State and Symbol
   type Transition_Key is record
      Source : State_Type;
      Symbol : Symbol_Type;
   end record;

   -- Less-than operator to allow Transition_Key to be used in Ordered_Maps
   function "<" (Left, Right : Transition_Key) return Boolean;

   -- DBA transition map: deterministic mapping to a single target state
   package DBA_Transitions is new Ada.Containers.Ordered_Maps
     (Key_Type     => Transition_Key,
      Element_Type => State_Type);

   -- NBA/GBA transition map: nondeterministic mapping to a set of target states
   package NBA_Transitions is new Ada.Containers.Ordered_Maps
     (Key_Type     => Transition_Key,
      Element_Type => State_Set);

   -- Vector of State_Sets for Generalized Büchi Automaton acceptance conditions
   package Acceptance_Set_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => State_Set);

   -- Deterministic Büchi Automaton (DBA)
   type DBA is record
      States           : State_Set;
      Initial_State    : State_Type;
      Transitions      : DBA_Transitions.Map;
      Accepting_States : State_Set;
   end record;

   -- Nondeterministic Büchi Automaton (NBA)
   type NBA is record
      States           : State_Set;
      Initial_States   : State_Set;
      Transitions      : NBA_Transitions.Map;
      Accepting_States : State_Set;
   end record;

   -- Generalized Büchi Automaton (GBA)
   type GBA is record
      States           : State_Set;
      Initial_States   : State_Set;
      Transitions      : NBA_Transitions.Map;
      Acceptance_Sets  : Acceptance_Set_Vectors.Vector;
   end record;

   -- Exception raised when an operation is invoked on an invalid automaton
   Invalid_Automaton : exception;

   -- Validation Functions (Invariant Checks)
   function Is_Valid (A : DBA) return Boolean;
   function Is_Valid (A : NBA) return Boolean;
   function Is_Valid (A : GBA) return Boolean;

   -- Periodic Word Simulation: Simulates the infinite word U * (V^omega)
   -- Returns True if the word is accepted by the DBA.
   function Accepts_Periodic_Word (A : DBA; U, V : String) return Boolean
     with Pre => V'Length > 0;

   -- Emptiness Checks: Returns True if the automaton accepts NO words.
   function Is_Empty (A : DBA) return Boolean;
   function Is_Empty (A : NBA) return Boolean;

   -- Conversions
   function To_NBA (A : DBA) return NBA
     with Post => Is_Valid (To_NBA'Result);

   function To_NBA (A : GBA) return NBA
     with Post => Is_Valid (To_NBA'Result);

   -- Safe insertion helpers for Nondeterministic structures (avoids Key overwrites)
   procedure Add_NBA_Trans (A : in out NBA; Src : State_Type; Sym : Symbol_Type; Tgt : State_Type);
   procedure Add_GBA_Trans (A : in out GBA; Src : State_Type; Sym : Symbol_Type; Tgt : State_Type);

private

   function "<" (Left, Right : Transition_Key) return Boolean is
     (if Left.Source /= Right.Source then Left.Source < Right.Source
      else Left.Symbol < Right.Symbol);

end Buchi_Automaton;
