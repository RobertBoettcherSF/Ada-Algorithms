pragma SPARK_Mode (On);

package Decode_Ways is
   --  A string of N digits has at most Fib (N + 1) decodings (all ones); Fib (30) = 832,040 fits Result
   --  but Fib (31) = 1,346,269 does not, so strings are at most 29 digits long.
   subtype Input is Positive range 1 .. 29;
   subtype Digit is Natural range 0 .. 9;
   subtype Result is Natural range 0 .. 1_000_000;
   type Digit_Sequence is array (Input) of Digit;

   --  Fibonacci numbers up to Fib (30), written out (no recursion)
   subtype Fib_Index is Natural range 0 .. 30;
   function Fib (K : Fib_Index) return Natural is
     (case K is
         when 0 => 0, when 1 => 1, when 2 => 1, when 3 => 2, when 4 => 3, when 5 => 5, when 6 => 8,
         when 7 => 13, when 8 => 21, when 9 => 34, when 10 => 55, when 11 => 89, when 12 => 144,
         when 13 => 233, when 14 => 377, when 15 => 610, when 16 => 987, when 17 => 1_597,
         when 18 => 2_584, when 19 => 4_181, when 20 => 6_765, when 21 => 10_946, when 22 => 17_711,
         when 23 => 28_657, when 24 => 46_368, when 25 => 75_025, when 26 => 121_393,
         when 27 => 196_418, when 28 => 317_811, when 29 => 514_229, when 30 => 832_040)
     with Ghost;

   --  Data (I - 1 .. I) is a two-digit code 10 .. 26
   function Pair_Valid (Left, Right : Digit) return Boolean is
     (Left = 1 or else (Left = 2 and then Right <= 6));

   --  Specification (ghost): decodings of Data (1 .. K): the last code is the single digit Data (K)
   --  (1 .. 9) or the pair Data (K - 1 .. K) (10 .. 26).
   function Ways (Data : Digit_Sequence; K : Natural) return Result
     with Ghost, Pre => K <= Input'Last, Post => Ways'Result <= Fib (K + 1),
          Subprogram_Variant => (Decreases => K);
   function Ways (Data : Digit_Sequence; K : Natural) return Result is
     (if K = 0 then 1
      elsif K = 1 then (if Data (1) /= 0 then 1 else 0)
      else (if Data (K) /= 0 then Ways (Data, K - 1) else 0)
           + (if Pair_Valid (Data (K - 1), Data (K)) then Ways (Data, K - 2) else 0));

   function Count (Data : Digit_Sequence; Length : Input) return Result
     with Post => Count'Result = Ways (Data, Length);
end Decode_Ways;
