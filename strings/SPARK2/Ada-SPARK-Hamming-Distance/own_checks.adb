pragma Ada_2022;
--  Own tests for Hamming_Distance (see tests/SOURCES.txt).
--  Distance on every pair of 3-bit vectors (exhaustive: 64 pairs) against an own count of differing positions.
with Ada.Text_IO; use Ada.Text_IO;
with Hamming_Distance; use Hamming_Distance;

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
   for X in 0 .. 7 loop
      for Y in 0 .. 7 loop
         declare
            A, B : Vector;
            Own : Natural := 0;
         begin
            for I in Index loop
               A (I) := (X / 2 ** (I - 1)) mod 2;
               B (I) := (Y / 2 ** (I - 1)) mod 2;
               if A (I) /= B (I) then Own := Own + 1; end if;
            end loop;
            Report (Distance (A, B) = Own, "Distance" & X'Image & Y'Image);
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
