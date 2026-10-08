--  Own tests for Number_Of_Substrings_Containing_All_Three_Characters (see tests/SOURCES.txt).
--  Count = number of substrings containing each of 0, 1 and 2 at least once.
pragma Ada_2022;
with Ada.Text_IO;
with Number_Of_Substrings_Containing_All_Three_Characters; use Number_Of_Substrings_Containing_All_Three_Characters;

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

   A : Symbol_Array;
begin
   for K in 1 .. 6_561 loop                 --  every array over {0, 1, 2}: 3**8 = 6561
      declare
         X : Natural := K - 1;
         E : Natural := 0;
      begin
         for I in Index loop
            A (I) := X mod 3;
            X := X / 3;
         end loop;
         for I in Index loop
            for J in I .. Element_Count loop
               if (for some P in I .. J => A (P) = 0) and then (for some P in I .. J => A (P) = 1)
                 and then (for some P in I .. J => A (P) = 2)
               then
                  E := E + 1;
               end if;
            end loop;
         end loop;
         Report (Natural (Count (A)) = E, "case" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-substrings reference, exhaustive)");
end Own_Checks;
