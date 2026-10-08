--  Own tests for Smallest_Integer_Divisible_By_K.Smallest_Length (written
--  for this repository; see tests/SOURCES.txt). Assumption: the function is
--  wrong or does nothing. Reference, different from the code's running
--  remainder of 1, 11, 111, ...: the repunit R(n) = (10**n - 1) / 9 is a
--  multiple of K exactly when 10**n = 1 modulo 9 K, so for K coprime to 10
--  the answer is the multiplicative order of 10 modulo 9 K (found from the
--  powers of 10); for K sharing a factor with 10 there is no answer (every
--  repunit is odd and ends in 1), which the function reports as 0.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Smallest_Integer_Divisible_By_K; use Smallest_Integer_Divisible_By_K;

procedure Own_Checks is
   Failures : Natural := 0;

   function Reference (K : Divisor) return Natural is
      M     : constant Positive := 9 * K;
      Power : Natural := 10 mod M;
   begin
      if K mod 2 = 0 or else K mod 5 = 0 then
         return 0;
      end if;
      for N in 1 .. M loop
         if Power = 1 mod M then
            return N;
         end if;
         Power := (Power * 10) mod M;
      end loop;
      return Natural'Last;  --  unreachable for K coprime to 10 (Euler)
   end Reference;
begin
   for K in Divisor loop
      if Smallest_Length (K) /= Reference (K) then
         Failures := Failures + 1;
         Put_Line ("FAIL Smallest_Length (" & K'Image & ") =" & Smallest_Length (K)'Image
                   & " want" & Reference (K)'Image);
      end if;
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks: every K in 1 .. 50 (order of 10 modulo 9 K)");
end Own_Checks;
