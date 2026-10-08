--  Own tests for Longest_Common_Substring (see tests/SOURCES.txt).
--  Length (A, B) must be the length of the longest contiguous common substring.
pragma Ada_2022;
with Ada.Text_IO;
with Longest_Common_Substring; use Longest_Common_Substring;

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
   function Ref (A, B : Char_Array) return Natural is
      Best : Natural := 0;
   begin
      for I in A'Range loop
         for J in B'Range loop
            declare
               K : Natural := 0;
            begin
               while I + K <= A'Last and then J + K <= B'Last and then A (I + K) = B (J + K) loop
                  K := K + 1;
               end loop;
               Best := Natural'Max (Best, K);
            end;
         end loop;
      end loop;
      return Best;
   end Ref;
   function Word (Code, Len, Base : Natural) return Char_Array is
      R : Char_Array (1 .. Len);
      C : Natural := Code;
   begin
      for I in R'Range loop
         R (I) := Character'Val (Character'Pos ('a') + C mod Base);
         C := C / Base;
      end loop;
      return R;
   end Word;
begin
   for Base in 2 .. 3 loop
      for LA in 0 .. Max_Len loop
         for CA in 0 .. Base ** LA - 1 loop
            for LB in 0 .. Max_Len loop
               for CB in 0 .. Base ** LB - 1 loop
                  declare
                     A : constant Char_Array := Word (CA, LA, Base);
                     B : constant Char_Array := Word (CB, LB, Base);
                  begin
                     Report (Length (A, B) = Ref (A, B), "pair");
                  end;
               end loop;
            end loop;
         end loop;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-substrings reference, exhaustive)");
end Own_Checks;
