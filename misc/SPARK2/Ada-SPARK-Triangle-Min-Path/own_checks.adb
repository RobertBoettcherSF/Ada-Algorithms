pragma Ada_2022;
--  Own tests for Triangle_Min_Path (see tests/SOURCES.txt).
--  Minimum top-to-bottom path sum in the triangle (row R uses columns 1 .. R; from
--  column C the path goes to C or C + 1 in the next row). Own brute force over all 8 paths.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Triangle_Min_Path; use Triangle_Min_Path;

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
   function Ref (T : Triangle) return Natural is
      Best : Natural := Natural'Last;
      S : Natural;
      C : Positive;
   begin
      for Code in 0 .. 7 loop
         C := 1; S := T (1, 1);
         for R in 2 .. 4 loop
            if (Code / 2 ** (R - 2)) mod 2 = 1 then C := C + 1; end if;
            S := S + T (R, C);
         end loop;
         Best := Natural'Min (Best, S);
      end loop;
      return Best;
   end Ref;
begin
   for Run in 1 .. 20000 loop
      declare
         T : Triangle := [others => [others => 0]];
      begin
         for R in Row loop
            for C in 1 .. R loop T (R, C) := Next (0, 9); end loop;
            --  cells outside the triangle get junk: they must be ignored
            for C in R + 1 .. 4 loop T (R, C) := (if Run mod 2 = 0 then 0 else Next (0, 9)); end loop;
         end loop;
         Report (Minimum (T) = Ref (T), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
