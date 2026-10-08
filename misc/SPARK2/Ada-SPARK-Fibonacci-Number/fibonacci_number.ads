pragma SPARK_Mode (On);

--  Iterative Fibonacci numbers F (0) .. F (32) with F (0) = 0, F (1) = 1
--  and F (k) = F (k - 1) + F (k - 2).
package Fibonacci_Number is
   subtype Input is Natural range 0 .. 32;
   subtype Result is Natural range 0 .. 10_000_000;

   --  Specification only (ghost): the Fibonacci numbers F (0) .. F (32).
   --  Is_Fibonacci states the defining recurrence, and the body proves
   --  that Fib satisfies it, so Fib is the Fibonacci sequence (the code
   --  does not consult it).
   function Fib (N : Input) return Result is
      (case N is
          when 0 => 0,
          when 1 => 1,
          when 2 => 1,
          when 3 => 2,
          when 4 => 3,
          when 5 => 5,
          when 6 => 8,
          when 7 => 13,
          when 8 => 21,
          when 9 => 34,
          when 10 => 55,
          when 11 => 89,
          when 12 => 144,
          when 13 => 233,
          when 14 => 377,
          when 15 => 610,
          when 16 => 987,
          when 17 => 1_597,
          when 18 => 2_584,
          when 19 => 4_181,
          when 20 => 6_765,
          when 21 => 10_946,
          when 22 => 17_711,
          when 23 => 28_657,
          when 24 => 46_368,
          when 25 => 75_025,
          when 26 => 121_393,
          when 27 => 196_418,
          when 28 => 317_811,
          when 29 => 514_229,
          when 30 => 832_040,
          when 31 => 1_346_269,
          when 32 => 2_178_309)
   with Ghost;

   function Is_Fibonacci return Boolean is
     (Fib (0) = 0 and then Fib (1) = 1
      and then (for all K in 2 .. Input'Last =>
                  Fib (K) = Fib (K - 1) + Fib (K - 2)))
   with Ghost;

   function Compute (N : Input) return Result
     with Post => Compute'Result = Fib (N);
end Fibonacci_Number;
