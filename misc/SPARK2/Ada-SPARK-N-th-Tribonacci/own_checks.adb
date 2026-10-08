--  Own tests for N_Th_Tribonacci.Compute (written for this repository; see
--  tests/SOURCES.txt). Assumption: Compute is wrong, saturates or does
--  nothing. References, both different from the code's three-term loop:
--  (1) T(n) counts the compositions of n - 1 into parts 1, 2 and 3, counted
--  here by explicit recursive enumeration for n <= 22; (2) the four-term
--  identity T(n) = 2 T(n-1) - T(n-4) (n >= 4) in Long_Long_Integer, which
--  has no cap, for every n up to Input'Last.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with N_Th_Tribonacci; use N_Th_Tribonacci;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   function Compositions (M : Natural) return Long_Long_Integer is
     (if M = 0 then 1
      else Compositions (M - 1)
           + (if M >= 2 then Compositions (M - 2) else 0)
           + (if M >= 3 then Compositions (M - 3) else 0));

   T : array (Input) of Long_Long_Integer;

   procedure Check (N : Input; Want : Long_Long_Integer; What : String) is
      Got : constant Long_Long_Integer := Long_Long_Integer (Compute (N));
   begin
      Cases := Cases + 1;
      if Got /= Want then
         Failures := Failures + 1;
         Put_Line ("FAIL N_Th_Tribonacci (" & What & ") N =" & N'Image & " got" & Got'Image & " want" & Want'Image);
      end if;
   end Check;
begin
   T (0) := 0; T (1) := 1; T (2) := 1; T (3) := 2;
   for N in 4 .. Input'Last loop
      T (N) := 2 * T (N - 1) - T (N - 4);
   end loop;
   for N in Input loop
      Check (N, T (N), "four-term identity");
   end loop;
   for N in 1 .. 22 loop
      Check (N, Compositions (N - 1), "compositions into 1, 2, 3");
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " values (four-term identity, composition count)");
end Own_Checks;
