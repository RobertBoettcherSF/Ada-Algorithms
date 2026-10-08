--  Own tests for Count_The_Number_Of_Consistent_Strings (see tests/SOURCES.txt).
--  Count_Consistent must count the symbols that are <= Allowed.
pragma Ada_2022;
with Ada.Text_IO;
with Count_The_Number_Of_Consistent_Strings; use Count_The_Number_Of_Consistent_Strings;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;


   A : Input_Array;
begin
   for Allowed in Symbol loop
      for A1 in Symbol loop
         for A2 in Symbol loop
            for A3 in Symbol loop
               for A4 in Symbol loop
                  A := [A1, A2, A3, A4];
                  Report (Count_Consistent (A, Allowed)
                          = Boolean'Pos (A1 <= Allowed) + Boolean'Pos (A2 <= Allowed)
                            + Boolean'Pos (A3 <= Allowed) + Boolean'Pos (A4 <= Allowed),
                          "case");
               end loop;
            end loop;
         end loop;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own count, exhaustive)");
end Own_Checks;
