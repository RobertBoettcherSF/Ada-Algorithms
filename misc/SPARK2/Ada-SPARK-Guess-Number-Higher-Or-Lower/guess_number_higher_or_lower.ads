pragma Ada_2022;

--  Guess number higher or lower: a number Secret in 1 .. N is hidden;
--  each guess is answered only with "lower", "higher" or "equal".
--  Guess_Number finds Secret by binary search and never needs more than
--  floor (log2 N) + 1 guesses, the best possible worst case.
package Guess_Number_Higher_Or_Lower with SPARK_Mode => On is
   Limit : constant := 32;
   subtype Number is Positive range 1 .. Limit;

   --  The answer to a guess: the secret is lower, equal or higher.
   type Order is (Lower, Equal, Higher);

   function Probe (Secret, Guess : Number) return Order is
     (if Secret < Guess then Lower
      elsif Secret > Guess then Higher
      else Equal);

   subtype Probe_Count is Natural range 0 .. 6;

   --  floor (log2 N) + 1: the fewest guesses that always suffice.
   function Max_Probes (N : Number) return Probe_Count is
     (if N < 2 then 1
      elsif N < 4 then 2
      elsif N < 8 then 3
      elsif N < 16 then 4
      elsif N < 32 then 5
      else 6);

   type Result is record
      Answer : Number;
      Probes : Probe_Count;   --  guesses made, the last one correct
   end record;

   --  Finds Secret in 1 .. N; the body reads Secret only through Probe.
   function Guess_Number (N : Number; Secret : Number) return Result
   with
     Global => null,
     Pre    => Secret <= N,
     Post   => Guess_Number'Result.Answer = Secret
               and then Guess_Number'Result.Probes in 1 .. Max_Probes (N);
end Guess_Number_Higher_Or_Lower;
