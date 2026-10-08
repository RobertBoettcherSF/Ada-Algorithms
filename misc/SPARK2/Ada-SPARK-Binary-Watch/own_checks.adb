--  Own tests for Binary_Watch (see tests/SOURCES.txt).
--  To_Minutes (H, M) = minutes since 0:00 on a 12-hour watch; every typed (H, M) is a valid reading.
with Ada.Text_IO; use Ada.Text_IO;
with Binary_Watch; use Binary_Watch;

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
   for H in Hour loop
      for M in Minute loop
         Report (Binary_Watch.To_Minutes (H, M) = 60 * H + M and then Binary_Watch.Is_Valid (H, M),
                 "reading" & Integer'Image (H) & Integer'Image (M));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
