pragma Ada_2022;
--  Own tests for Water_Bottles (see tests/SOURCES.txt).
--  Total_Bottles: drink all, trade Exchange empties for one full, repeat; own step-by-step simulation.
with Ada.Text_IO; use Ada.Text_IO;
with Water_Bottles; use Water_Bottles;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
begin
   for Full in Bottle_Count loop
      for E in Exchange_Rate loop
         declare
            Drunk : Natural := Full;
            Empty : Natural := Full;
         begin
            while Empty >= E loop
               Drunk := Drunk + Empty / E;
               Empty := Empty / E + Empty mod E;
            end loop;
            Report (Total_Bottles (Full, E) = Drunk, "F" & Integer'Image (Full) & " E" & Integer'Image (E));
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
