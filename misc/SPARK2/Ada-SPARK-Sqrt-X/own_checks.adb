pragma Ada_2022;
--  Own tests for Sqrt_X (see tests/SOURCES.txt).
--  Floor_Sqrt (N) is the R with R * R <= N < (R + 1) * (R + 1).
with Ada.Text_IO; use Ada.Text_IO;
with Sqrt_X; use Sqrt_X;

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
   for N in Number loop
      declare
         R : constant Natural := Floor_Sqrt (N);
      begin
         Report (R * R <= N and then N < (R + 1) * (R + 1), "N =" & Integer'Image (N));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
