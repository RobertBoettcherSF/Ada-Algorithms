pragma Ada_2022;
with Ada.Text_IO;
with Newton_Raphson; use Newton_Raphson;
procedure Tests is
   --  Own property check (tests/SOURCES.txt): Sqrt (N) is the integer square root, R * R <= N < (R + 1) ** 2,
   --  checked for every N in the input range.
   Bad : Natural := 0;
begin
   pragma Assert (Newton_Raphson.Sqrt (1) = 1);
   pragma Assert (Newton_Raphson.Sqrt (144) = 12);
   pragma Assert (Newton_Raphson.Sqrt (10_000) = 100);
   for N in Input loop
      declare
         R : constant Integer := Sqrt (N);
      begin
         if not (R >= 0 and then R * R <= N and then N < (R + 1) * (R + 1)) then
            if Bad < 5 then
               Ada.Text_IO.Put_Line ("FAIL Sqrt (" & N'Image & ") =" & R'Image);
            end if;
            Bad := Bad + 1;
         end if;
      end;
   end loop;
   if Bad > 0 then
      Ada.Text_IO.Put_Line ("FAIL" & Bad'Image & " inputs");
      raise Program_Error;
   end if;
   Ada.Text_IO.Put_Line ("PASS Ada-SPARK-Newton-Raphson (all 10000 inputs: R * R <= N < (R + 1) ** 2)");
end Tests;
