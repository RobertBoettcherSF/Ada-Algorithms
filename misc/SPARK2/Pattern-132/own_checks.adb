pragma Ada_2022;
--  Own tests for Pattern_132 (see tests/SOURCES.txt).
--  Exists: some I < J < K with A (I) < A (K) < A (J) in A (1 .. Length); own prefix-minimum reference.
with Ada.Text_IO; use Ada.Text_IO;
with Pattern_132; use Pattern_132;

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
   A : Values;
begin
   for Run in 1 .. 20_000 loop
      declare
         L : constant Natural := Next (0, 12);
         R : constant Natural := Next (0, 32);
         Want : Boolean := False;
         Low : Integer;
      begin
         for I in Index loop A (I) := Next (-R, R); end loop;
         for J in 2 .. L loop   --  best I for this J is the smallest value before J
            Low := Integer'Last;
            for I in 1 .. J - 1 loop Low := Integer'Min (Low, A (I)); end loop;
            for K in J + 1 .. L loop
               if Low < A (K) and then A (K) < A (J) then Want := True; end if;
            end loop;
         end loop;
         Report (Exists (A, L) = Want, "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
