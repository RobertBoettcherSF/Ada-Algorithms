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

   --  The recurrence above. It is read from a ghost table that the package
   --  body builds once by the recurrence (Compute, whose postcondition
   --  states the recurrence, the limit values and the monotonicity), so
   --  that a ghost check costs one lookup.
   function Ways (N : Natural) return Big_Integer
   with Ghost, Pre => N <= Max_Stairs + 1;

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
   function Prefix_Sum (A : Step_List; J : Natural) return Natural is
     (if J = 0 then 0 else Prefix_Sum (A, J - 1) + A (J));

   function Rank_Upto (A : Step_List; N : Steps; J : Natural) return Big_Integer is
     (if J = 0 then To_Big_Integer (0)
      elsif A (J) = 1 then Rank_Upto (A, N, J - 1)
      else Rank_Upto (A, N, J - 1) + Ways (N - Prefix_Sum (A, J - 1) - 1));
end Climbing_Stairs;
