pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  Climbing N stairs one or two steps at a time.
--
--  Ways (N), the number of different climbs, follows from the first step:
--  a climb of N >= 2 stairs starts with a single step (then N - 1 stairs
--  remain) or with a double step (then N - 2 remain), so
--  Ways (N) = Ways (N - 1) + Ways (N - 2), with Ways (0) = Ways (1) = 1.
--
--  Limit: N <= 45. Ways (45) = 1_836_311_903 fits Natural, Ways (46) =
--  2_971_215_073 does not (both proved in Facts), and every value the
--  dynamic program computes is at most the final one.
package Climbing_Stairs with SPARK_Mode => On is
   Max_Stairs : constant := 45;
   subtype Steps is Natural range 0 .. Max_Stairs;
   subtype Step is Positive range 1 .. 2;
   type Step_List is array (Positive range <>) of Step;

   --  Ways (N) for N <= 45, read from a ghost table of values (no code
   --  runs at elaboration). Facts states that the table satisfies the
   --  recurrence above, which fixes every entry; Lemma_Facts proves it and
   --  the tests regenerate the values. The executable code does not read
   --  the table.
   function Ways (N : Natural) return Big_Integer
   with Ghost, Pre => N <= Max_Stairs;

   function Facts return Boolean is
     (Ways (0) = 1 and then Ways (1) = 1
      and then (for all J in 2 .. Max_Stairs => Ways (J) = Ways (J - 1) + Ways (J - 2))
      and then (for all J in Steps => Ways (J) >= 1 and then Ways (J) <= Ways (Max_Stairs))
      and then Ways (Max_Stairs) = 1_836_311_903
      --  Ways (46) = Ways (45) + Ways (44) would not fit Natural.
      and then Ways (Max_Stairs) + Ways (Max_Stairs - 1) > To_Big_Integer (Natural'Last))
   with Ghost;

   procedure Lemma_Facts
   with Ghost, Global => null, Post => Facts;

   --  Number of climbs, by the dynamic program.
   function Count (N : Steps) return Positive
   with Global => null, Post => To_Big_Integer (Count'Result) = Ways (N);

   --  Sum of the first J steps of a climb.
   function Prefix_Sum (A : Step_List; J : Natural) return Natural
   with
     Ghost,
     Pre                => A'First = 1 and then A'Last <= Max_Stairs and then J <= A'Last,
     Post               => Prefix_Sum'Result <= 2 * J,
     Subprogram_Variant => (Decreases => J);

   --  Position of a climb of N stairs in dictionary order (single step
   --  before double step): every double step at position J skips the
   --  Ways (R - 1) climbs that take a single step there, R being the
   --  stairs still left before position J.
   function Rank_Upto (A : Step_List; N : Steps; J : Natural) return Big_Integer
   with
     Ghost,
     Pre                => A'First = 1 and then A'Last <= Max_Stairs and then J <= A'Last
                           and then Prefix_Sum (A, J) <= N,
     Subprogram_Variant => (Decreases => J);

   --  The K-th climb of N stairs in dictionary order, counting from 0.
   function Climb (N : Steps; K : Natural) return Step_List
   with
     Global => null,
     Pre    => K < Count (N),
     Post   => Climb'Result'First = 1 and then Climb'Result'Last <= N
               and then Prefix_Sum (Climb'Result, Climb'Result'Last) = N
               and then Rank_Upto (Climb'Result, N, Climb'Result'Last) = To_Big_Integer (K);

private
   function Ways_Value (N : Steps) return Positive is
     (case N is
        when 0 => 1,
        when 1 => 1,
        when 2 => 2,
        when 3 => 3,
        when 4 => 5,
        when 5 => 8,
        when 6 => 13,
        when 7 => 21,
        when 8 => 34,
        when 9 => 55,
        when 10 => 89,
        when 11 => 144,
        when 12 => 233,
        when 13 => 377,
        when 14 => 610,
        when 15 => 987,
        when 16 => 1_597,
        when 17 => 2_584,
        when 18 => 4_181,
        when 19 => 6_765,
        when 20 => 10_946,
        when 21 => 17_711,
        when 22 => 28_657,
        when 23 => 46_368,
        when 24 => 75_025,
        when 25 => 121_393,
        when 26 => 196_418,
        when 27 => 317_811,
        when 28 => 514_229,
        when 29 => 832_040,
        when 30 => 1_346_269,
        when 31 => 2_178_309,
        when 32 => 3_524_578,
        when 33 => 5_702_887,
        when 34 => 9_227_465,
        when 35 => 14_930_352,
        when 36 => 24_157_817,
        when 37 => 39_088_169,
        when 38 => 63_245_986,
        when 39 => 102_334_155,
        when 40 => 165_580_141,
        when 41 => 267_914_296,
        when 42 => 433_494_437,
        when 43 => 701_408_733,
        when 44 => 1_134_903_170,
        when 45 => 1_836_311_903)
   with Ghost;

   function Ways (N : Natural) return Big_Integer is (To_Big_Integer (Ways_Value (N)));

   function Prefix_Sum (A : Step_List; J : Natural) return Natural is
     (if J = 0 then 0 else Prefix_Sum (A, J - 1) + A (J));

   function Rank_Upto (A : Step_List; N : Steps; J : Natural) return Big_Integer is
     (if J = 0 then To_Big_Integer (0)
      elsif A (J) = 1 then Rank_Upto (A, N, J - 1)
      else Rank_Upto (A, N, J - 1) + Ways (N - Prefix_Sum (A, J - 1) - 1));
end Climbing_Stairs;
