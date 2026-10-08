--  Own tests for Fibonacci_DP.Compute (written for this repository; see
--  tests/SOURCES.txt). Assumption: Compute is wrong, saturates or does
--  nothing. Reference, different from the code's two-term loop: F(n) for
--  n >= 2 is the number of 0/1 strings of length n - 2 with no two
--  adjacent 1s, counted by trying every bit pattern.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_DP; use Fibonacci_DP;

procedure Own_Checks is
   Failures : Natural := 0;

   --  Number of bit strings of length L with no two adjacent 1s, by brute force.
   function No_Adjacent_Ones (L : Natural) return Natural is
      Count : Natural := 0;
   begin
      for Mask in 0 .. 2 ** L - 1 loop
         declare
            Ok : Boolean := True;
         begin
            for B in 0 .. L - 2 loop
               if (Mask / 2 ** B) mod 2 = 1 and then (Mask / 2 ** (B + 1)) mod 2 = 1 then
                  Ok := False;
               end if;
            end loop;
            if Ok then
               Count := Count + 1;
            end if;
         end;
      end loop;
      return Count;
   end No_Adjacent_Ones;

   procedure Check (N : Input; Want : Natural) is
      Got : constant Natural := Compute (N);
   begin
      if Got /= Want then
         Failures := Failures + 1;
         Put_Line ("FAIL Fibonacci_DP N =" & N'Image & " got" & Got'Image & " want" & Want'Image);
      end if;
   end Check;
begin
   Check (0, 0);
   Check (1, 1);
   for N in 2 .. Input'Last loop
      Check (N, No_Adjacent_Ones (N - 2));
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks: every N in 0 .. 10 (brute-force count of bit strings)");
end Own_Checks;
