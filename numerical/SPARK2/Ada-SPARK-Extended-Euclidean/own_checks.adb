pragma Ada_2022;
--  Own tests for Extended_Euclidean (see tests/SOURCES.txt).
--  GCD on all pairs 1 .. 200 against an own brute-force largest common divisor, and random pairs up to 1000.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Extended_Euclidean; use Extended_Euclidean;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
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
