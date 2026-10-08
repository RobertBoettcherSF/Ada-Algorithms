pragma Ada_2022;
--  Own tests for Count_Smaller_After_Self (see tests/SOURCES.txt).
--  Count: Result (I) = number of J > I with Input (J) < Input (I).
with Ada.Text_IO; use Ada.Text_IO;
with Count_Smaller_After_Self; use Count_Smaller_After_Self;

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
   A : Input_Array;
begin
   for Run in 1 .. 20_000 loop
      declare
         R : constant Positive := Next (1, 100);   --  value spread, small means many ties
         C : Count_Array;
         Want : Natural;
      begin
         for I in Index loop A (I) := Next (-R, R); end loop;
         C := Count_Smaller_After_Self.Count (A);
         for I in Index loop
            Want := 0;
            for J in Index loop
               if J > I and then A (J) < A (I) then Want := Want + 1; end if;
            end loop;
            Report (C (I) = Want, "run" & Integer'Image (Run));
         end loop;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
