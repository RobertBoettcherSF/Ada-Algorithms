pragma Ada_2022;
--  Own tests for Elevator_Algorithm (see tests/SOURCES.txt).
--  Move_One_Step: one floor towards Target, stay when there; repeated steps reach Target in |Current - Target| steps.
with Ada.Text_IO; use Ada.Text_IO;
with Elevator_Algorithm; use Elevator_Algorithm;

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
   for C in Floor loop
      for T in Floor loop
         Report (Move_One_Step (C, T) = (if C < T then C + 1 elsif C > T then C - 1 else C), "step" & Integer'Image (C) & Integer'Image (T));
         declare
            F : Floor := C;
         begin
            for I in 1 .. abs (C - T) loop F := Move_One_Step (F, T); end loop;
            Report (F = T, "reach" & Integer'Image (C) & Integer'Image (T));
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
