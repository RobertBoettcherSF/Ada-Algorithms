--  PLACEHOLDER: the README calls this a stub / bounded kernel, not a full Get-Maximum-In-Generated-Array implementation; see tools/readme_stubs.txt
pragma Ada_2022;

--  Get maximum in generated array: nums (0) = 0, nums (1) = 1,
--  nums (2 i) = nums (i) and nums (2 i + 1) = nums (i) + nums (i + 1);
--  find the largest of nums (0 .. N).
--
--  Generate (N): nums (0 .. N), filled in index order (both sources of
--  nums (I) are below I for I >= 2).
--  Maximum (N): the largest entry of Generate (N).
--
--  Limit: N <= 1_000, a run-time limit. The values cannot overflow
--  (nums (I) <= I, proved), but with assertions enabled (the tests and
--  mutation runs use them) the loop invariant of Generate checks the
--  whole prefix against the ghost definition at every step, about
--  N ** 2 / 2 * log2 (N) steps: one Maximum (1_000) takes about 0.13 s,
--  Maximum (2_000) about 0.6 s and Maximum (5_000) about 3.5 s on the
--  sweep machine.
package Get_Maximum_In_Generated_Array with SPARK_Mode => On is
   Max_N : constant := 1_000;
   subtype N_Value is Natural range 0 .. Max_N;
   type Value_Array is array (Natural range <>) of Natural;

   --  Ghost definition of nums (I), carried as the pair
   --  (nums (I), nums (I + 1)) so that one call costs O (log I) when
   --  assertions are enabled: from the pair for I / 2 = K,
   --  (nums (2 K), nums (2 K + 1)) = (nums (K), nums (K) + nums (K + 1))
   --  and (nums (2 K + 1), nums (2 K + 2)) = (nums (K) + nums (K + 1), nums (K + 1)).
   --  Lemma_Rules proves that Nums obeys the rules of the problem.
   type Pair is record
      This, Next : Natural;
   end record;

   function Step (P : Pair; Odd : Boolean) return Pair is
     (if Odd then (P.This + P.Next, P.Next) else (P.This, P.This + P.Next))
   with Ghost, Pre => P.This <= Natural'Last / 2 and then P.Next <= Natural'Last / 2;

   function Nums_Pair (I : N_Value) return Pair
   with
     Ghost,
     Post               => Nums_Pair'Result.This <= I and then Nums_Pair'Result.Next <= I + 1,
     Subprogram_Variant => (Decreases => I);

   function Nums (I : N_Value) return Natural is (Nums_Pair (I).This) with Ghost;

   --  The rules of the problem hold for Nums.
   procedure Lemma_Rules (I : N_Value)
   with
     Ghost,
     Global => null,
     Post   => (if I = 0 then Nums (I) = 0)
               and then (if I = 1 then Nums (I) = 1)
               and then (if I >= 2 and then I mod 2 = 0 then Nums (I) = Nums (I / 2))
               and then (if I >= 2 and then I mod 2 = 1 then Nums (I) = Nums (I / 2) + Nums (I / 2 + 1));

   function Generate (N : N_Value) return Value_Array
   with
     Global => null,
     Post   => Generate'Result'First = 0 and then Generate'Result'Last = N
               and then (for all I in 0 .. N => Generate'Result (I) = Nums (I));

   function Maximum (N : N_Value) return Natural
   with
     Global => null,
     Post   => (for all I in 0 .. N => Nums (I) <= Maximum'Result)
               and then (for some I in 0 .. N => Nums (I) = Maximum'Result);
private
   function Nums_Pair (I : N_Value) return Pair is
     (if I = 0 then (0, 1) else Step (Nums_Pair (I / 2), I mod 2 = 1));
end Get_Maximum_In_Generated_Array;
