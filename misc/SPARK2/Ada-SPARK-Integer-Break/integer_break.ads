pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  Integer break: split N >= 2 into at least two positive parts with the
--  largest product.
--
--  Maximum (N): the dynamic program over the first part. A split of M
--  starts with a part K in 1 .. M - 1; the rest M - K is either kept whole
--  or split again, so Best (M) = max over K of K * max (M - K, Best (M - K)).
--  Best_Split (N): a split with that product (the smallest best first
--  part, then the rest kept whole when that is at least as good).
--
--  Limit: N <= 58. Best (58) = 4 * 3 ** 18 = 1_549_681_956 fits Natural,
--  Best (59) = 2 * 3 ** 19 = 2_324_522_934 does not; every intermediate
--  product is at most the result.
package Integer_Break with SPARK_Mode => On is
   Max_N : constant := 58;
   subtype Number is Positive range 2 .. Max_N;
   subtype Part is Positive range 1 .. Max_N;
   type Part_List is array (Positive range <>) of Part;
   subtype Value is Long_Long_Integer range 0 .. 1_549_681_956;

   --  Best (M): a ghost table of values (an expression function, nothing
   --  runs at elaboration), 0 for M = 1. Row (M) states the defining
   --  property for M, which fixes Best (M) from the smaller entries;
   --  Lemma_Row proves it for each M and the own checks regenerate the
   --  table.
   function Best (M : Part) return Value with Ghost;

   --  The best product for M kept whole or split.
   function Whole_Or_Split (M : Part) return Value is
     (Long_Long_Integer'Max (Long_Long_Integer (M), Best (M)))
   with Ghost;

   --  The smallest first part reaching Best (M) (a ghost table).
   function Arg (M : Number) return Part with Ghost, Post => Arg'Result < M;

   --  The product for M with first part K and the rest kept whole or split.
   function Cand (M : Number; K : Part) return Long_Long_Integer is
     (Long_Long_Integer (K) * Whole_Or_Split (M - K))
   with Ghost, Pre => K < M;

   function Row (M : Number) return Boolean is
     ((for all K in 1 .. M - 1 => Cand (M, K) <= Best (M))
      and then Best (M) = Cand (M, Arg (M)))
   with Ghost;

   --  Row (M) for one M (costs O (M) when assertions are enabled).
   procedure Lemma_Row (M : Number) with Ghost, Global => null, Post => Row (M);

   function Maximum (N : Number) return Positive
   with Global => null, Post => Long_Long_Integer (Maximum'Result) = Best (N);

   --  Sum and product of P (1 .. J).
   function Sum_To (P : Part_List; J : Natural) return Big_Integer
   with
     Ghost,
     Pre                => P'First = 1 and then J <= P'Last,
     Post               => Sum_To'Result >= To_Big_Integer (J),
     Subprogram_Variant => (Decreases => J);

   function Product_To (P : Part_List; J : Natural) return Big_Integer
   with
     Ghost,
     Pre                => P'First = 1 and then J <= P'Last,
     Post               => Product_To'Result >= 1,
     Subprogram_Variant => (Decreases => J);

   function Best_Split (N : Number) return Part_List
   with
     Global => null,
     Post   => Best_Split'Result'First = 1 and then Best_Split'Result'Last in 2 .. N
               and then Sum_To (Best_Split'Result, Best_Split'Result'Last) = To_Big_Integer (N)
               and then Product_To (Best_Split'Result, Best_Split'Result'Last) = To_Big_Integer (Maximum (N));

   --  No split of N into at least two parts has a larger product.
   procedure Lemma_Optimal (N : Number; P : Part_List)
   with
     Ghost,
     Global => null,
     Pre    => P'First = 1 and then P'Last >= 2 and then Sum_To (P, P'Last) = To_Big_Integer (N),
     Post   => Product_To (P, P'Last) <= To_Big_Integer (Maximum (N));

private
   function Best (M : Part) return Value is
     (case M is
        when 1 => 0,
        when 2 => 1,
        when 3 => 2,
        when 4 => 4,
        when 5 => 6,
        when 6 => 9,
        when 7 => 12,
        when 8 => 18,
        when 9 => 27,
        when 10 => 36,
        when 11 => 54,
        when 12 => 81,
        when 13 => 108,
        when 14 => 162,
        when 15 => 243,
        when 16 => 324,
        when 17 => 486,
        when 18 => 729,
        when 19 => 972,
        when 20 => 1_458,
        when 21 => 2_187,
        when 22 => 2_916,
        when 23 => 4_374,
        when 24 => 6_561,
        when 25 => 8_748,
        when 26 => 13_122,
        when 27 => 19_683,
        when 28 => 26_244,
        when 29 => 39_366,
        when 30 => 59_049,
        when 31 => 78_732,
        when 32 => 118_098,
        when 33 => 177_147,
        when 34 => 236_196,
        when 35 => 354_294,
        when 36 => 531_441,
        when 37 => 708_588,
        when 38 => 1_062_882,
        when 39 => 1_594_323,
        when 40 => 2_125_764,
        when 41 => 3_188_646,
        when 42 => 4_782_969,
        when 43 => 6_377_292,
        when 44 => 9_565_938,
        when 45 => 14_348_907,
        when 46 => 19_131_876,
        when 47 => 28_697_814,
        when 48 => 43_046_721,
        when 49 => 57_395_628,
        when 50 => 86_093_442,
        when 51 => 129_140_163,
        when 52 => 172_186_884,
        when 53 => 258_280_326,
        when 54 => 387_420_489,
        when 55 => 516_560_652,
        when 56 => 774_840_978,
        when 57 => 1_162_261_467,
        when 58 => 1_549_681_956);

   function Arg (M : Number) return Part is
     (case M is
        when 2 => 1,
        when 3 => 1,
        when 4 => 2,
        when 5 => 2,
        when 6 => 3,
        when 7 => 2,
        when 8 => 2,
        when 9 => 3,
        when 10 => 2,
        when 11 => 2,
        when 12 => 3,
        when 13 => 2,
        when 14 => 2,
        when 15 => 3,
        when 16 => 2,
        when 17 => 2,
        when 18 => 3,
        when 19 => 2,
        when 20 => 2,
        when 21 => 3,
        when 22 => 2,
        when 23 => 2,
        when 24 => 3,
        when 25 => 2,
        when 26 => 2,
        when 27 => 3,
        when 28 => 2,
        when 29 => 2,
        when 30 => 3,
        when 31 => 2,
        when 32 => 2,
        when 33 => 3,
        when 34 => 2,
        when 35 => 2,
        when 36 => 3,
        when 37 => 2,
        when 38 => 2,
        when 39 => 3,
        when 40 => 2,
        when 41 => 2,
        when 42 => 3,
        when 43 => 2,
        when 44 => 2,
        when 45 => 3,
        when 46 => 2,
        when 47 => 2,
        when 48 => 3,
        when 49 => 2,
        when 50 => 2,
        when 51 => 3,
        when 52 => 2,
        when 53 => 2,
        when 54 => 3,
        when 55 => 2,
        when 56 => 2,
        when 57 => 3,
        when 58 => 2);

   function Sum_To (P : Part_List; J : Natural) return Big_Integer is
     (if J = 0 then To_Big_Integer (0) else Sum_To (P, J - 1) + To_Big_Integer (P (J)));

   function Product_To (P : Part_List; J : Natural) return Big_Integer is
     (if J = 0 then To_Big_Integer (1) else Product_To (P, J - 1) * To_Big_Integer (P (J)));
end Integer_Break;
