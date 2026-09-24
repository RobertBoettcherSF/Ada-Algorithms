--  Knuth_Bendix_Completion — Ada 2023 educational package for the
--  Knuth–Bendix completion algorithm over words (string / free-monoid
--  rewriting). Orient equations by shortlex, reduce to normal forms,
--  resolve critical pairs from left-hand-side overlaps, and attempt to
--  build a finite convergent rewrite system that decides the word problem.
--  Primary source:
--  https://en.wikipedia.org/wiki/Knuth–Bendix_completion_algorithm
--  Closely related (independently discovered): Buchberger's algorithm
--  for Gröbner bases (polynomial rings as an instance of the same idea).

pragma Ada_2022;

package Knuth_Bendix_Completion
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity (classroom bounds)
   ---------------------------------------------------------------------------

   --  Soft educational limits: keep words and rule sets tiny so critical-pair
   --  enumeration stays readable in tests and demos.
   Max_Word_Len     : constant Positive := 24;
   Max_Rules_Cap    : constant Positive := 32;
   Max_Steps_Cap    : constant Positive := 256;

   subtype Word_Length is Natural range 0 .. Max_Word_Len;
   subtype Rule_Count  is Natural range 0 .. Max_Rules_Cap;
   subtype Step_Count  is Natural range 0 .. Max_Steps_Cap;

   ---------------------------------------------------------------------------
   -- Words, equations, rules
   ---------------------------------------------------------------------------

   --  Word over an alphabet of Characters (free monoid). Empty word = Len 0.
   type Word is record
      Len  : Word_Length := 0;
      Text : String (1 .. Max_Word_Len) := [others => ' '];
   end record;

   --  Unoriented equation  Left = Right.
   type Equation is record
      Left, Right : Word;
   end record;

   --  Oriented rewrite rule  LHS → RHS  with Shortlex_Less (RHS, LHS).
   type Rule is record
      LHS, RHS : Word;
   end record;

   type Equation_Array is array (Positive range <>) of Equation;
   type Rule_Array     is array (Positive range <>) of Rule;

   --  Result of Complete: Success yields a (hopefully) convergent rule set;
   --  Did_Not_Complete means Max_Rules / Max_Steps / word-length bounds were
   --  hit — Knuth–Bendix is only a semi-decision procedure.
   type Outcome_Kind is (Success, Did_Not_Complete);

   type Complete_Result (Kind : Outcome_Kind; Count : Rule_Count) is record
      Rules      : Rule_Array (1 .. Count);
      Steps_Used : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Empty / oversized words, empty LHS after orientation attempt, bad bounds.

   ---------------------------------------------------------------------------
   -- Constructors / views
   ---------------------------------------------------------------------------

   --  Build a Word from a String. Raises Invalid_Argument if Length > Max_Word_Len.
   function To_Word (S : String) return Word
     with Global => null,
          SPARK_Mode => Off;

   --  Slice Text (1 .. Len).
   function Image (W : Word) return String
     with Global => null;

   function Make_Equation (Left, Right : String) return Equation
     with Global => null;

   function Make_Rule (Left, Right : String) return Rule
     with Global => null,
          SPARK_Mode => Off;
   --  Does not check orientation; used by tests to inject known rules.
   --  Raises Invalid_Argument if Left is empty or either side too long.

   ---------------------------------------------------------------------------
   -- Shortlex reduction order
   ---------------------------------------------------------------------------

   --  True iff A is strictly smaller than B in shortlex (length-lex) order:
   --    |A| < |B|, or |A| = |B| and A is lexicographically smaller than B
   --  (Ada Character order). Empty word is the unique minimum.
   function Shortlex_Less (A, B : Word) return Boolean
     with Global => null;

   function Shortlex_Less (A, B : String) return Boolean
     with Global => null;

   --  Orient A = B into a rule Larger → Smaller. Raises Invalid_Argument if
   --  A and B are equal (nothing to orient) or either exceeds Max_Word_Len.
   function Orient (A, B : Word) return Rule
     with Global => null;

   function Orient (A, B : String) return Rule
     with Global => null,
          SPARK_Mode => Off;

   ---------------------------------------------------------------------------
   -- Reduction / normal forms
   ---------------------------------------------------------------------------

   --  One leftmost-outermost rewrite step: scan W left-to-right; at the first
   --  position where some rule LHS matches as a contiguous factor, replace
   --  that factor by the RHS (rules tried in array order). Returns Changed.
   procedure Rewrite_Step
     (W       : in out Word;
      Rules   : Rule_Array;
      Changed : out Boolean)
     with Global => null,
          SPARK_Mode => Off;

   --  Iterate Rewrite_Step until irreducible. Terminates when every rule
   --  strictly decreases shortlex (as produced by Orient / Complete).
   --  Raises Invalid_Argument if an intermediate word would exceed Max_Word_Len
   --  (should not happen for length-nonincreasing shortlex rules).
   function Reduce (W : Word; Rules : Rule_Array) return Word
     with Global => null,
          SPARK_Mode => Off;

   function Reduce (W : String; Rules : Rule_Array) return String
     with Global => null,
          SPARK_Mode => Off;

   --  Alias for Reduce — unique when Rules is convergent.
   function Normal_Form (W : Word; Rules : Rule_Array) return Word
     with Global => null,
          SPARK_Mode => Off;

   function Normal_Form (W : String; Rules : Rule_Array) return String
     with Global => null,
          SPARK_Mode => Off;

   --  True iff Normal_Form (A) = Normal_Form (B).
   function Equivalent (A, B : Word; Rules : Rule_Array) return Boolean
     with Global => null,
          SPARK_Mode => Off;

   function Equivalent (A, B : String; Rules : Rule_Array) return Boolean
     with Global => null,
          SPARK_Mode => Off;

   ---------------------------------------------------------------------------
   -- Critical pairs (string overlaps)
   ---------------------------------------------------------------------------

   --  A critical pair is a pair of words (U, V) obtained by overlapping two
   --  rule left-hand sides and rewriting the peak in the two ways.
   type Critical_Pair is record
      U, V : Word;
   end record;

   type Critical_Pair_Array is array (Positive range <>) of Critical_Pair;

   --  Enumerate proper overlaps and inclusions of LHS(I) with LHS(J)
   --  (including I = J for self-overlaps). Returns pairs before reduction;
   --  callers typically reduce both sides. Raises Invalid_Argument on empty
   --  LHS. Result length is bounded; excess pairs are dropped (educational).
   function Critical_Pairs
     (Rules : Rule_Array;
      I, J  : Positive) return Critical_Pair_Array
     with Global => null,
          SPARK_Mode => Off;

   ---------------------------------------------------------------------------
   -- Completion
   ---------------------------------------------------------------------------

   --  Knuth–Bendix completion over the free monoid with shortlex.
   --  Orient Equations into an initial rule set, then repeatedly form
   --  critical pairs, reduce both sides, and add a new oriented rule when
   --  they differ, until no nontrivial pairs remain or a bound is hit.
   --
   --  Max_Rules  : maximum rules retained (1 .. Max_Rules_Cap).
   --  Max_Steps  : maximum critical-pair resolutions that add/examine work
   --               (1 .. Max_Steps_Cap).
   --
   --  Returns Kind => Success with a rule set that is locally confluent
   --  under the enumerated overlaps (hence convergent by Newman's lemma,
   --  since shortlex ensures termination), or Kind => Did_Not_Complete with
   --  a partial rule set when bounds prevent finishing.
   --
   --  Raises Invalid_Argument on empty Equations, oversized words, or
   --  Max_Rules / Max_Steps outside 1 .. Cap.
   function Complete
     (Equations : Equation_Array;
      Max_Rules : Positive := Max_Rules_Cap;
      Max_Steps : Positive := Max_Steps_Cap) return Complete_Result
     with Global => null,
          SPARK_Mode => Off;

   --  True iff every critical pair of Rules reduces to a common normal form
   --  (local confluence check on the finite overlap set we enumerate).
   function Is_Locally_Confluent (Rules : Rule_Array) return Boolean
     with Global => null,
          SPARK_Mode => Off;

end Knuth_Bendix_Completion;
