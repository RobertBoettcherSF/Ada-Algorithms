pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  Val3 (A, B, C) = 2 ** A * 3 ** B * 5 ** C.  Its definition is completed
--  in the body, so the proofs in Ugly_Number_II see only the contract and
--  the three lemmas below (the nonlinear definition stays out of their
--  verification conditions).
package Ugly_Powers with SPARK_Mode => On is
   function Val3 (A, B, C : Natural) return Big_Integer
   with Global => null,
        Post   => Val3'Result >= 1
                  and then (if A = 0 and then B = 0 and then C = 0 then Val3'Result = 1);

   procedure Lemma_Two (A, B, C : Natural)
   with Ghost, Global => null, Pre => A < Natural'Last,
        Post => Val3 (A + 1, B, C) = 2 * Val3 (A, B, C);

   procedure Lemma_Three (A, B, C : Natural)
   with Ghost, Global => null, Pre => B < Natural'Last,
        Post => Val3 (A, B + 1, C) = 3 * Val3 (A, B, C);

   procedure Lemma_Five (A, B, C : Natural)
   with Ghost, Global => null, Pre => C < Natural'Last,
        Post => Val3 (A, B, C + 1) = 5 * Val3 (A, B, C);
end Ugly_Powers;
