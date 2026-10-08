--  Own tests for Count_The_Number_Of_Consistent_Strings (see tests/SOURCES.txt).
--  Count_Consistent must count the symbols that are <= Allowed.
pragma Ada_2022;
with Ada.Text_IO;
with Count_The_Number_Of_Consistent_Strings; use Count_The_Number_Of_Consistent_Strings;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;
   pragma Warnings (Off, Next);

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

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);

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
