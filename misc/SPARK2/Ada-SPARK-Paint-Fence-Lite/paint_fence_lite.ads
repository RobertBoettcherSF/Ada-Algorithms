pragma SPARK_Mode (On);

--  Paint fence: N posts in a row, K colours, and no three adjacent posts
--  of the same colour. Count (N, K, M) is the number of colourings mod M.
--
--  Range: every value is reduced mod M <= 2 ** 31 - 1 and every product of
--  two residues is below 2 ** 62 (Long_Long_Integer), so the arithmetic
--  puts no limit on N or K. N <= 1_000 bounds the run time of the ghost
--  contract checks under -gnata: the loop invariant evaluates the ghost
--  recurrence, O (N) work per iteration, O (N ** 2) per call: about
--  0.06 s at N = 1_000, so tests with dozens of calls at the limit still
--  finish within a few seconds.
package Paint_Fence_Lite is
   subtype Number_Of_Posts is Positive range 1 .. 1_000;
   subtype Colours is Positive;
   subtype Modulus is Positive;
   subtype Residue is Long_Long_Integer range 0 .. Long_Long_Integer (Positive'Last) - 1;

   function Md (X : Long_Long_Integer; M : Modulus) return Residue is
     (X mod Long_Long_Integer (M))
   with Pre => X >= 0, Post => Md'Result < Long_Long_Integer (M);

   --  The colourings counted directly, mod M: T (1) = K, T (2) = K * K,
   --  T (N) = (K - 1) * (T (N - 1) + T (N - 2)), since post N either has a
   --  colour other than post N - 1 (K - 1 choices after any colouring of
   --  N - 1 posts), or the colour of post N - 1, which then differs from
   --  post N - 2 (K - 1 choices after any colouring of N - 2 posts).
   type Two_Terms is record
      Prev, Cur : Residue;    --  T (N - 1) mod M, T (N) mod M
   end record;

   --  One step of the recurrence.
   function Step (P : Two_Terms; K : Colours; M : Modulus) return Two_Terms is
     (Prev => P.Cur,
      Cur  => Md (Md (Long_Long_Integer (K) - 1, M) * Md (P.Prev + P.Cur, M), M))
   with Ghost, Pre => P.Prev < Long_Long_Integer (M) and then P.Cur < Long_Long_Integer (M);

   function Terms (N : Number_Of_Posts; K : Colours; M : Modulus) return Two_Terms
   with
     Ghost,
     Pre                => N >= 2,
     Post               => Terms'Result.Prev < Long_Long_Integer (M) and then Terms'Result.Cur < Long_Long_Integer (M),
     Subprogram_Variant => (Decreases => N);

   function T (N : Number_Of_Posts; K : Colours; M : Modulus) return Residue is
     (if N = 1 then Md (Long_Long_Integer (K), M) else Terms (N, K, M).Cur)
   with Ghost;

   function Count (N : Number_Of_Posts; K : Colours; M : Modulus) return Natural
   with
     Global => null,
     Post   => Long_Long_Integer (Count'Result) = T (N, K, M);

private
   function Terms (N : Number_Of_Posts; K : Colours; M : Modulus) return Two_Terms is
     (if N = 2 then
        (Prev => Md (Long_Long_Integer (K), M),
         Cur  => Md (Md (Long_Long_Integer (K), M) * Md (Long_Long_Integer (K), M), M))
      else Step (Terms (N - 1, K, M), K, M));
end Paint_Fence_Lite;
