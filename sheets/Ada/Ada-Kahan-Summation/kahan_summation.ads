--  Kahan_Summation — Ada 2023 educational package for Wikipedia
--  "Kahan summation algorithm" (compensated summation): naïve sum,
--  Kahan (running correction c), Neumaier (improved Kahan–Babuška),
--  optional pairwise divide-and-conquer, and a running Accumulator.
--  Cap n ≤ 10_000; educational Float. Long_Float used as oracle in tests.
--  Primary source:
--  https://en.wikipedia.org/wiki/Kahan_summation_algorithm
--  Siblings (README): Binary splitting, nth root, square roots,
--  Alpha max plus beta min, Spigot, …

pragma Ada_2022;

package Kahan_Summation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_Length : constant Positive := 10_000;

   subtype Term_Count is Natural range 0 .. Max_Length;
   subtype Term_Index is Positive range 1 .. Max_Length;

   type Float_Array is array (Term_Index range <>) of Float;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  |A − B| in Float (absolute error of A vs reference B).
   function Abs_Error (A, B : Float) return Float
     with Global => null;

   --  |Approx − Exact| where Exact is Long_Float (oracle), cast back.
   function Abs_Error_Exact (Approx : Float; Exact : Long_Float) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Array summation
   ---------------------------------------------------------------------------

   --  Naïve left-to-right sum: s := s + x_i. Educational contrast only.
   function Sum_Naive (Data : Float_Array) return Float
     with Global => null;
   --  Empty → 0.0. Length > Max_Length → Invalid_Argument.

   --  Kahan compensated summation with running correction c:
   --    y := x − c;  t := sum + y;  c := (t − sum) − y;  sum := t
   function Sum_Kahan (Data : Float_Array) return Float
     with Global => null;

   --  Neumaier improved Kahan–Babuška: compensation also when |x| > |sum|,
   --  then return sum + c once at the end.
   function Sum_Neumaier (Data : Float_Array) return Float
     with Global => null;

   --  Pairwise (recursive) summation: split, sum halves, add. O(log n)
   --  error growth vs O(n) for naïve. Base case: naïve of ≤ 16 terms.
   function Sum_Pairwise (Data : Float_Array) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Running Accumulator (Kahan online)
   ---------------------------------------------------------------------------

   type Accumulator is private;

   function Make_Empty return Accumulator
     with Global => null;

   procedure Reset (Acc : in out Accumulator)
     with Global => null;

   procedure Add (Acc : in out Accumulator; X : Float)
     with Global => null;
   --  One Kahan step into the accumulator.

   procedure Add_Many (Acc : in out Accumulator; Data : Float_Array)
     with Global => null;
   --  Add each element; raises Invalid_Argument if Length > Max_Length.

   function Total (Acc : Accumulator) return Float
     with Global => null;
   --  Current compensated sum (same as Sum_Kahan of all Adds so far).

   function Count (Acc : Accumulator) return Natural
     with Global => null;

   function Compensation (Acc : Accumulator) return Float
     with Global => null;
   --  Current running correction c (educational introspection).

   ---------------------------------------------------------------------------
   -- Sample / pathological builders (for demos & tests)
   ---------------------------------------------------------------------------

   --  N copies of Value (1 .. N). N = 0 → empty slice bounds 1 .. 0.
   function Make_Constant
     (N : Term_Count; Value : Float) return Float_Array
     with Global => null;

   --  Data(1) = Large; Data(2 .. N) = Small. Classic lost-digits setup when
   --  |Small| ≪ ulp(Large). Requires N ≥ 1.
   function Make_Large_Then_Small
     (N : Term_Count; Large, Small : Float) return Float_Array
     with Pre => N >= 1, Global => null;

   --  Peters / Neumaier example shape: [A, Huge, A, −Huge] (length 4).
   --  Kahan often yields ~0; Neumaier recovers ~2A when Huge ≫ A.
   function Make_Neumaier_Peters
     (A : Float := 1.0; Huge : Float := 1.0E+20) return Float_Array
     with Global => null;

private

   type Accumulator is record
      Sum   : Float := 0.0;
      C     : Float := 0.0;  -- running compensation
      Count : Natural := 0;
   end record;

end Kahan_Summation;
