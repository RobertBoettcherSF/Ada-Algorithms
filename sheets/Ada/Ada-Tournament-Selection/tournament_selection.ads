--  Tournament_Selection — Ada 2023 educational package for Wikipedia
--  "Tournament selection": draw K contestants from a population (with
--  or without replacement), then return the fittest (deterministic
--  tournament, P = 1) or a soft-tournament pick with probability
--  P · (1−P)^r for rank r among the contestants.
--  Selection pressure rises with K; K = 1 is equivalent to uniform
--  random selection. Supports Maximize / Minimize fitness senses.
--  Primary source:
--  https://en.wikipedia.org/wiki/Tournament_selection
--  Siblings: Ada-Truncation-Selection; Stochastic universal sampling
--  forthcoming; Ada-Memetic-Algorithm uses k-tournament (README links;
--  no package deps).

pragma Ada_2022;

package Tournament_Selection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Non_Negative is Real range 0.0 .. Real'Last;

   --  Fitness comparison direction.
   --  Maximize: higher Fitness is better (typical GA fitness).
   --  Minimize: lower Fitness is better (cost / objective value).
   type Fitness_Sense is (Maximize, Minimize);

   --  Candidate solution carrier. Tag is an opaque identity for tests /
   --  callers (not used by the selection logic itself).
   type Individual is record
      Fitness : Real    := 0.0;
      Tag     : Natural := 0;
   end record;

   type Population is array (Positive range <>) of Individual;

   --  Indices into a population (1-based within the array bounds).
   type Index_List is array (Positive range <>) of Positive;

   ---------------------------------------------------------------------------
   -- Configuration
   ---------------------------------------------------------------------------

   --  K               : tournament size (contestants drawn per bout).
   --  P               : soft-tournament probability for the best
   --                    contestant; P = 1.0 ⇒ deterministic (always
   --                    return the fittest of the K). Soft ranks use
   --                    Prob(rank r) = P · (1−P)^r for r = 0 .. K−2,
   --                    with the last rank absorbing the remainder.
   --  With_Replacement: True ⇒ contestants drawn independently
   --                    (duplicates allowed); False ⇒ distinct
   --                    contestants (requires K ≤ N).
   --  Sense           : Maximize or Minimize.
   --  Seed            : initial LCG seed (informational / for
   --                    Make_Config + Seed_RNG convenience).
   type Config is record
      K                : Positive      := 2;
      P                : Unit_Interval := 1.0;
      With_Replacement : Boolean       := True;
      Sense            : Fitness_Sense := Maximize;
      Seed             : Natural       := 1;
   end record;

   function Default_Config return Config
     with Global => null;

   function Make_Config
     (K                : Positive      := 2;
      P                : Unit_Interval := 1.0;
      With_Replacement : Boolean       := True;
      Sense            : Fitness_Sense := Maximize;
      Seed             : Natural       := 1) return Config
     with Global => null;

   --  True when Cfg is usable for a population of size Pop_Size:
   --  Pop_Size ≥ 1; if not With_Replacement then K ≤ Pop_Size.
   function Valid_Config
     (Cfg : Config; Pop_Size : Natural) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Exceptions / numeric helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  True iff A is strictly better than B under Sense.
   function Better
     (A, B : Real; Sense : Fitness_Sense) return Boolean
     with Global => null;

   --  True iff A is better than or equal to B under Sense.
   function Better_Or_Equal
     (A, B : Real; Sense : Fitness_Sense) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible draws
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   --  Seed State from Cfg.Seed.
   procedure Seed_RNG (State : out RNG_State; Cfg : Config)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   --  Uniform integer in Lo .. Hi inclusive.
   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Contestant draw / ranking helpers
   ---------------------------------------------------------------------------

   --  Draw K population indices as contestants.
   --  With replacement: independent uniform draws.
   --  Without: distinct indices (Fisher–Yates style partial sample).
   --  Raises Invalid_Argument if Pop empty, or (not With_Replacement
   --  and K > Pop'Length).
   function Draw_Contestants
     (Pop              : Population;
      K                : Positive;
      With_Replacement : Boolean;
      State            : in out RNG_State) return Index_List
     with Global => null;

   --  Soft (or deterministic) pick among Contestant indices already
   --  drawn from Pop. Contestants are ranked by fitness under Sense;
   --  rank 0 (best) is chosen with probability P, rank 1 with
   --  P·(1−P), …; last rank takes the residual mass. P = 1 ⇒ always
   --  the best. Returns a population index.
   --  Raises Invalid_Argument if Contestants empty or Pop empty.
   function Soft_Pick
     (Pop         : Population;
      Contestants : Index_List;
      P           : Unit_Interval;
      Sense       : Fitness_Sense;
      State       : in out RNG_State) return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core selection API
   ---------------------------------------------------------------------------

   --  One tournament bout: draw K contestants, return the (soft)
   --  winner's population index.
   --  Raises Invalid_Argument if not Valid_Config (Cfg, Pop'Length).
   function Tournament_Winner
     (Pop   : Population;
      Cfg   : Config;
      State : in out RNG_State) return Positive
     with Global => null;

   --  Same bout, returning the winning Individual record.
   function Select_One
     (Pop   : Population;
      Cfg   : Config;
      State : in out RNG_State) return Individual
     with Global => null;

   --  Run Count independent tournaments; return the winners as
   --  Individuals (each bout re-draws contestants).
   function Select_Parents
     (Pop   : Population;
      Count : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Population
     with Global => null;

   --  Same as Select_Parents, returning winner indices.
   function Select_Parents
     (Pop   : Population;
      Count : Positive;
      Cfg   : Config;
      State : in out RNG_State) return Index_List
     with Global => null;

end Tournament_Selection;
