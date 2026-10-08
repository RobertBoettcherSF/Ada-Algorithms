pragma Ada_2022;
--  Own tests for Lagrange_Interpolation (see tests/SOURCES.txt).
--  Interpolate: the quadratic through (-1, Y0), (0, Y1), (1, Y2) takes the sample value at each sample point.
with Ada.Text_IO; use Ada.Text_IO;
with Lagrange_Interpolation; use Lagrange_Interpolation;

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
   for Y0 in Value loop
      for Y1 in Value loop
         for Y2 in Value loop
            Report (Interpolate (Y0, Y1, Y2, -1) = Y0 and then Interpolate (Y0, Y1, Y2, 0) = Y1
                    and then Interpolate (Y0, Y1, Y2, 1) = Y2,
                    "Y" & Integer'Image (Y0) & Integer'Image (Y1) & Integer'Image (Y2));
         end loop;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
