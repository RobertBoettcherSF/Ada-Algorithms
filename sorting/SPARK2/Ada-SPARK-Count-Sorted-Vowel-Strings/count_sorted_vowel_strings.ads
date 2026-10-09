pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  How many strings of length N over the vowels From .. U are sorted
--  (each letter is at least the one before it). The count is computed by
--  the vowel dynamic program: a sorted string over From .. U either does
--  not use From at all (a sorted string over the later vowels) or starts
--  with From (followed by a sorted string of length N - 1 over From .. U).
--
--  Limit: N <= 473. Over all five vowels the count is C (N + 4, 4);
--  C (477, 4) = 2_130_031_575 fits Natural, C (478, 4) = 2_148_006_525
--  does not, and every value the program computes is at most the final one.
package Count_Sorted_Vowel_Strings with SPARK_Mode => On is
   type Vowel is (A, E, I, O, U);

   Max_Length : constant := 473;
   subtype Length is Natural range 0 .. Max_Length;

   --  The definition: sorted strings of length N over From .. U.
   function Sorted_Count (N : Natural; From : Vowel) return Big_Integer
   with
     Ghost,
     Subprogram_Variant => (Decreases => N, Decreases => Vowel'Pos (U) - Vowel'Pos (From));

   --  Its closed form, scaled: Weight (From) * Sorted_Count (N, From) =
   --  Rising (N, From), that is C (N + k, k) with k = 4 - Vowel'Pos (From).
   function Weight (From : Vowel) return Big_Integer is
     (case From is
        when A => To_Big_Integer (24), when E => To_Big_Integer (6), when I => To_Big_Integer (2),
        when O | U => To_Big_Integer (1))
   with Ghost;

   function Rising (N : Natural; From : Vowel) return Big_Integer is
     (case From is
        when U => To_Big_Integer (1),
        when O => To_Big_Integer (N) + 1,
        when I => (To_Big_Integer (N) + 1) * (To_Big_Integer (N) + 2),
        when E => (To_Big_Integer (N) + 1) * (To_Big_Integer (N) + 2) * (To_Big_Integer (N) + 3),
        when A => (To_Big_Integer (N) + 1) * (To_Big_Integer (N) + 2) * (To_Big_Integer (N) + 3)
                  * (To_Big_Integer (N) + 4))
   with Ghost;

   function Number_Of_Strings (N : Length; From : Vowel := A) return Natural
   with
     Global => null,
     Post   => Weight (From) * To_Big_Integer (Number_Of_Strings'Result) = Rising (N, From);

   --  The closed form is the definition (proof only; never called, since
   --  Sorted_Count takes exponential time to run).
   procedure Lemma_Closed_Form (N : Natural; From : Vowel)
   with
     Ghost,
     Global             => null,
     Post               => Weight (From) * Sorted_Count (N, From) = Rising (N, From),
     Subprogram_Variant => (Decreases => N, Decreases => Vowel'Pos (U) - Vowel'Pos (From));

private
   function Sorted_Count (N : Natural; From : Vowel) return Big_Integer is
     (if N = 0 or else From = U then To_Big_Integer (1)
      else Sorted_Count (N, Vowel'Succ (From)) + Sorted_Count (N - 1, From));
end Count_Sorted_Vowel_Strings;
