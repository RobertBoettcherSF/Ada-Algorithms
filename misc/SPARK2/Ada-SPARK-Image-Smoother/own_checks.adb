pragma Ada_2022;
--  Own tests for Image_Smoother (see tests/SOURCES.txt).
--  Smooth: every output pixel is the floor of the mean of the input pixel and its (up to 8) neighbours.
with Ada.Text_IO; use Ada.Text_IO;
with Image_Smoother; use Image_Smoother;

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
   Img, Out_Img : Image;
begin
   for Trial in 1 .. 20_000 loop
      for R in Index loop
         for C in Index loop
            Img (R, C) := (if Trial mod 3 = 0 then Next (98, 99) else Next (0, 99));
         end loop;
      end loop;
      Smooth (Img, Out_Img);
      for R in Index loop
         for C in Index loop
            declare
               Sum, Cnt : Natural := 0;
            begin
               for DR in -1 .. 1 loop
                  for DC in -1 .. 1 loop
                     if R + DR in Index and then C + DC in Index then
                        Sum := Sum + Img (R + DR, C + DC); Cnt := Cnt + 1;
                     end if;
                  end loop;
               end loop;
               Report (Out_Img (R, C) = Sum / Cnt, "pixel");
            end;
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
