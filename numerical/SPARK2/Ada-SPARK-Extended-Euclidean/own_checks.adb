pragma Ada_2022;
--  Own tests for Extended_Euclidean (see tests/SOURCES.txt).
--  GCD on all pairs 1 .. 200 against an own brute-force largest common divisor, and random pairs up to 1000.
with Ada.Text_IO; use Ada.Text_IO;
with Extended_Euclidean; use Extended_Euclidean;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   procedure Check (A, B : Input) is
      D : Positive := 1;
   begin
      for K in reverse 1 .. Integer'Min (A, B) loop
         if A mod K = 0 and then B mod K = 0 then D := K; exit; end if;
      end loop;
      Report (GCD (A, B) = D, "GCD" & A'Image & B'Image);
   end Check;
begin
   for A in 1 .. 200 loop
      for B in 1 .. 200 loop Check (A, B); end loop;
   end loop;
   for Run in 1 .. 20000 loop Check (Next (1, 1000), Next (1, 1000)); end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
