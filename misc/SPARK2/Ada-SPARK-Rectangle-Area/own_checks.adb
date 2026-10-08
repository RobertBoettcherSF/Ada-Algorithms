pragma Ada_2022;
--  Own tests for Rectangle_Area (see tests/SOURCES.txt).
--  Area: width times height, every rectangle in the domain.
with Ada.Text_IO; use Ada.Text_IO;
with Rectangle_Area; use Rectangle_Area;

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
   for W in Side_Length loop
      for H in Side_Length loop
         Report (Area ((Width => W, Height => H)) = W * H, "W" & Integer'Image (W) & " H" & Integer'Image (H));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
