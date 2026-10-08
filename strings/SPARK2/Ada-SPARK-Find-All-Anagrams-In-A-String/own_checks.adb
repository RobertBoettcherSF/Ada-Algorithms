--  Own tests for Find_All_Anagrams_In_A_String (see tests/SOURCES.txt).
--  Count_Anagrams must count the windows (I, I + 1) holding "ab" or "ba".
pragma Ada_2022;
with Ada.Text_IO;
with Find_All_Anagrams_In_A_String; use Find_All_Anagrams_In_A_String;

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

   T : Text_Array;
   E : Natural;
begin
   for K in 1 .. 5_000 loop
      for I in Index loop
         T (I) := Character'Val (Character'Pos ('a') + Next (0, (if K mod 2 = 0 then 1 else 2)));
      end loop;
      E := 0;
      for I in 1 .. Length - 1 loop
         if (T (I) = 'a' and then T (I + 1) = 'b') or else (T (I) = 'b' and then T (I + 1) = 'a') then
            E := E + 1;
         end if;
      end loop;
      Report (Count_Anagrams (T) = E, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own window count reference)");
end Own_Checks;
