--  Rounding_Functions — Ada 2023 educational package for Wikipedia
--  "Rounding" / "Floor and ceiling functions": classic directed rounding
--  (floor, ceiling, truncate, away-from-zero) and tie-breaking nearest
--  modes (half-up, half-away-from-zero, half-to-even / banker's,
--  half-toward-zero). Long_Float → Integer for whole-number modes;
--  Round_To_Decimals returns Long_Float. Educational definitions —
--  not a thin wrapper over Ada 'Floor / 'Rounding attributes alone.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Rounding
--  https://en.wikipedia.org/wiki/Floor_and_ceiling_functions
--  Spreadsheet / overview:
--  https://en.wikipedia.org/wiki/Rounding_functions
--  Siblings (README): Ada-Spigot-Algorithm; upcoming Newton’s method
--  (multiplicative inverses), Multiplicative inverse Algorithms,
--  Toom–Cook.

pragma Ada_2022;

package Rounding_Functions
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float → Integer)
   ---------------------------------------------------------------------------

   --  Safe absolute magnitude for Integer results. Leaves headroom so
   --  Floor / Ceiling near ±Max_Abs_Arg cannot overflow Integer'First
   --  / Integer'Last when adjusting by ±1 on ties or directed modes.
   --  Values with |X| > Max_Abs_Arg raise Out_Of_Range.
   Max_Abs_Arg : constant Long_Float := 1.0E9;

   --  Decimal places accepted by Round_To_Decimals (scale 10^N fits
   --  comfortably in Long_Float for classroom demos).
   Max_Decimals : constant := 9;

   subtype Decimal_Count is Natural range 0 .. Max_Decimals;

   Out_Of_Range     : exception;
   Invalid_Argument : exception;

   Near_Tol : constant Long_Float := 1.0E-12;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   --  |A − B| ≤ Tol (default Near_Tol). Used heavily by tests.
   function Near
     (A, B : Long_Float;
      Tol  : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  Classical sign: −1, 0, or +1 as Long_Float.
   function Sign (X : Long_Float) return Long_Float
     with Global => null;

   --  True when |X| ≤ Max_Abs_Arg (finite educational domain).
   function In_Domain (X : Long_Float) return Boolean
     with Global => null;

   --  Signed fractional part: X − Truncate(X). Same sign as X (or 0).
   --  Distinct from the unit interval {X} = X − Floor(X) ∈ [0,1).
   function Frac (X : Long_Float) return Long_Float
     with Global => null;

   --  Unit-interval fractional part: X − Floor(X) ∈ [0, 1).
   function Floor_Frac (X : Long_Float) return Long_Float
     with Global => null;

   --  True when X is (exactly) an integer value in Long_Float.
   function Is_Integer (X : Long_Float) return Boolean
     with Global => null;

   --  True when the absolute distance to the nearest integer is exactly
   --  one half (binary-exact .5 ties for modest magnitudes).
   function Is_Half_Tie (X : Long_Float) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Directed rounding → Integer
   ---------------------------------------------------------------------------

   --  Floor: ⌊X⌋ — largest integer ≤ X (toward −∞).
   function Floor (X : Long_Float) return Integer
     with Global => null;

   --  Ceiling: ⌈X⌉ — smallest integer ≥ X (toward +∞).
   function Ceiling (X : Long_Float) return Integer
     with Global => null;

   --  Truncate / toward zero: integer part of X (discard fraction).
   function Truncate (X : Long_Float) return Integer
     with Global => null;

   --  Away from zero: ⌈|X|⌉ with the sign of X.
   function Round_Away_From_Zero (X : Long_Float) return Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Round-to-nearest with tie-breaking → Integer
   ---------------------------------------------------------------------------

   --  Half up (half toward +∞): ⌊X + 1/2⌋.
   --  Ties at *.5 always round toward +∞ (23.5→24, −23.5→−23).
   function Round_Half_Up (X : Long_Float) return Integer
     with Global => null;

   --  Half down (half toward −∞): ⌈X − 1/2⌉.
   function Round_Half_Down (X : Long_Float) return Integer
     with Global => null;

   --  Half away from zero (common school rule): ties move away from 0.
   --  2.5→3, −2.5→−3.
   function Round_Half_Away_From_Zero (X : Long_Float) return Integer
     with Global => null;

   --  Half toward zero: ties move toward 0.
   --  2.5→2, −2.5→−2.
   function Round_Half_Toward_Zero (X : Long_Float) return Integer
     with Global => null;

   --  Half to even / banker's rounding: on a .5 tie, choose the even
   --  integer. 2.5→2, 3.5→4, −2.5→−2, −3.5→−4.
   function Round_Half_To_Even (X : Long_Float) return Integer
     with Global => null;

   --  Half to odd: on a .5 tie, choose the odd integer.
   function Round_Half_To_Odd (X : Long_Float) return Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Round to N decimal places → Long_Float
   ---------------------------------------------------------------------------

   --  Scale by 10^N, apply Round_Half_Away_From_Zero, scale back.
   --  Raises Invalid_Argument if N > Max_Decimals (subtype normally
   --  prevents this); raises Out_Of_Range if the scaled value leaves
   --  the Integer domain.
   function Round_To_Decimals
     (X : Long_Float;
      N : Decimal_Count) return Long_Float
     with Global => null;

   --  Same scaling with banker's (half-to-even) tie-break.
   function Round_To_Decimals_Even
     (X : Long_Float;
      N : Decimal_Count) return Long_Float
     with Global => null;

end Rounding_Functions;
