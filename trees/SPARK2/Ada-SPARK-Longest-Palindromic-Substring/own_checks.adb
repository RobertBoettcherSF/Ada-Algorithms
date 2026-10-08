--  Own tests for Longest_Palindromic_Substring (see tests/SOURCES.txt).
--  Longest_Length = length of the longest palindromic substring.
pragma Ada_2022;
with Ada.Text_IO;
with Longest_Palindromic_Substring; use Longest_Palindromic_Substring;

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

   S : Text_Array;
begin
   for K in 1 .. 5_000 loop
      for I in Index loop
         S (I) := Character'Val (Character'Pos ('a') + Next (0, (if K mod 2 = 0 then 1 else 3)));
      end loop;
      declare
         Best : Natural := 0;
      begin
         for I in Index loop
            for J in I .. Length loop
               declare
                  Pal : Boolean := True;
               begin
                  for P in 0 .. (J - I) / 2 loop
                     Pal := Pal and then S (I + P) = S (J - P);
                  end loop;
                  if Pal then
                     Best := Natural'Max (Best, J - I + 1);
                  end if;
               end;
            end loop;
         end loop;
         Report (Longest_Length (S) = Best, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-substrings reference)");
end Own_Checks;
