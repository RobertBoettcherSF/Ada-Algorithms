pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;
with Ugly_Powers; use Ugly_Powers;

--  Ugly number II: the N-th positive number with no prime factor other
--  than 2, 3 and 5, that is the N-th number 2 ** a * 3 ** b * 5 ** c
--  (1 is the first).
--
--  First_Ugly (N): the first N ugly numbers in increasing order, by the
--  three-pointer merge: each ugly number after 1 is 2, 3 or 5 times a
--  smaller one, so the next is the smallest of 2 * L (I2), 3 * L (I3) and
--  5 * L (I5), where each pointer is the first entry whose multiple is not
--  yet listed.  Each entry carries its exponents a, b, c; the record
--  predicate says the value is Val3 (a, b, c) = 2 ** a * 3 ** b * 5 ** c
--  (package Ugly_Powers).
--  Nth_Ugly (N): the value of the last entry of First_Ugly (N).
--
--  Values are Big_Integer, so nothing can overflow (in Positive the
--  1_691st, 2_125_764_000, would be the last: the 1_692nd is 2 ** 31).
--  Limit: N <= 2_000, a run-time limit with assertions enabled (the tests
--  and mutation runs use them): the contracts compare every entry with
--  every other one, so a call costs O (N ** 2) Big_Integer operations,
--  about 0.5 s for N = 1_000, 2.3 s for 2_000 and 4.1 s for 3_000 on the
--  sweep machine (the mutation runs stop a test run after 30 s).
package Ugly_Number_II with SPARK_Mode => On is
   Max_N : constant := 2_000;
   subtype N_Index is Positive range 1 .. Max_N;

   --  The K-th ugly number has a + b + c <= K - 1 (each one is p times an
   --  earlier one), so Max_N bounds every exponent.
   subtype Exponent is Natural range 0 .. Max_N;

   --  At_2, At_3, At_5: the positions of 2, 3 and 5 times this entry in its
   --  list once they are listed (0 before; First_Ugly fills them while the
   --  multiple is at most the last entry, which Closed states).
   type Ugly_Value is record
      Value               : Big_Integer;
      Two, Three, Five    : Exponent;
      At_2, At_3, At_5    : Natural;
   end record
   with Dynamic_Predicate =>
     Ugly_Value.Value = Val3 (Ugly_Value.Two, Ugly_Value.Three, Ugly_Value.Five);

   type Ugly_List is array (Positive range <>) of Ugly_Value;

   --  The index is the rank (L (K) is the K-th ugly number), so a list
   --  that means something starts at 1: the subtype says so for any
   --  length (H180; a Positive index alone lets a 5 .. 10 list through).
   subtype One_Based_List is Ugly_List
   with Predicate => One_Based_List'First = 1;

   function Has (L : Ugly_List; V : Big_Integer) return Boolean is
     (for some K in L'Range => L (K).Value = V)
   with Ghost;

   --  2, 3 and 5 times an entry are listed, at the positions the entry
   --  records, when they are at most the last.
   function Closed (L : Ugly_List) return Boolean is
     (for all J in L'Range =>
        (if 2 * L (J).Value <= L (L'Last).Value
         then L (J).At_2 in L'Range and then L (L (J).At_2).Value = 2 * L (J).Value)
        and then (if 3 * L (J).Value <= L (L'Last).Value
                  then L (J).At_3 in L'Range and then L (L (J).At_3).Value = 3 * L (J).Value)
        and then (if 5 * L (J).Value <= L (L'Last).Value
                  then L (J).At_5 in L'Range and then L (L (J).At_5).Value = 5 * L (J).Value))
   with Ghost, Pre => L'Length >= 1;

   --  L (One_Based_List: it starts at 1) increases and is Closed (its
   --  entries are ugly by their predicate); Lemma_Complete then shows it
   --  lists every ugly number up to its last entry, so L (K) is the K-th
   --  ugly number.
   function Ugly_Prefix (L : One_Based_List) return Boolean is
     (L'Length >= 1 and then L (1).Value = 1
      and then (for all K in 2 .. L'Last => L (K - 1).Value < L (K).Value)
      and then Closed (L))
   with Ghost;

   function First_Ugly (N : N_Index) return One_Based_List
   with
     Global => null,
     Post   => First_Ugly'Result'Last = N and then Ugly_Prefix (First_Ugly'Result);

   function Nth_Ugly (N : N_Index) return Big_Integer is (First_Ugly (N) (N).Value)
   with Global => null;

   --  Every 2 ** A * 3 ** B * 5 ** C up to the last entry of an
   --  Ugly_Prefix is listed.
   procedure Lemma_Complete (L : One_Based_List; A, B, C : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => Ugly_Prefix (L)
                           and then Val3 (A, B, C) <= L (L'Last).Value,
     Post               => Has (L, Val3 (A, B, C)),
     Subprogram_Variant => (Decreases => A, Decreases => B, Decreases => C);

end Ugly_Number_II;
